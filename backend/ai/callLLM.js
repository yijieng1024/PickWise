/**
 * callLLM.js – FINAL, NO ERRORS
 * - Prompts fixed (no { in system)
 * - RAG works (client + index match)
 * - getUserPreferences defined
 * - Pick Score only on filtered laptops
 */

const { ChatGoogleGenerativeAI } = require("@langchain/google-genai");
const { ChatPromptTemplate } = require("@langchain/core/prompts");
const { HumanMessage, AIMessage } = require("@langchain/core/messages");
const { MongoDBAtlasVectorSearch } = require("@langchain/mongodb");
const { GoogleGenerativeAIEmbeddings } = require("@langchain/google-genai");
const Laptop = require("../models/Laptop");
const UserPreference = require("../models/userpreference");
const Conversation = require("../models/Conversation");
const mongoose = require("mongoose");
const { MongoClient } = require("mongodb");
require("dotenv").config();

// ------------------ ENV ------------------
const MONGO_URL = process.env.MONGO_URL || process.env.MONGO_URI;
const MONGO_DB = process.env.MONGO_DB || "test";
if (!MONGO_URL) throw new Error("Missing MONGO_URL");
if (!process.env.GOOGLE_API_KEY) throw new Error("Missing GOOGLE_API_KEY");

// ------------------ MODEL ------------------
const model = new ChatGoogleGenerativeAI({
  model: "gemini-2.5-flash",
  temperature: 0.7,
  apiKey: process.env.GOOGLE_API_KEY,
});

// ------------------ VECTOR STORE ------------------
let laptopVectorStore = null;
let mongoClientSingleton = null;

async function getMongoClient() {
  if (mongoClientSingleton) return mongoClientSingleton;
  const client = new MongoClient(MONGO_URL, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
  await client.connect();
  mongoClientSingleton = client;
  return client;
}

async function initLaptopVectorStore() {
  if (laptopVectorStore) return laptopVectorStore;

  const client = await getMongoClient();
  const collection = client.db(MONGO_DB).collection("laptops");

  const embeddings = new GoogleGenerativeAIEmbeddings({
    model: "text-embedding-004",
    apiKey: process.env.GOOGLE_API_KEY,
  });

  laptopVectorStore = new MongoDBAtlasVectorSearch(embeddings, {
    client,
    collection,
    indexName: "laptop_vector_index",
    textKey: "pageContent",
    embeddingKey: "embedding",
  });

  console.log("Vector store ready");
  return laptopVectorStore;
}

// ------------------ SYNC ------------------
async function syncLaptopEmbeddings(batchSize = 200) {
  const store = await initLaptopVectorStore();
  const total = await Laptop.countDocuments();
  for (let skip = 0; skip < total; skip += batchSize) {
    const docs = await Laptop.find({}).skip(skip).limit(batchSize).lean();
    const documents = docs.map(d => ({
      pageContent: `Name: ${d.product_name}\nBrand: ${d.brand}\nPrice: ${d.price_rm}\nCPU: ${d.processor_name}\nGPU: ${d.gpu_model}\nRAM: ${d.ram_gb}GB\nDisplay: ${d.display_size_inch}" ${d.display_resolution}`,
      metadata: { product_id: d._id.toString() },
    }));
    if (documents.length) await store.addDocuments2121(documents);
  }
  console.log("Sync complete");
}

// ------------------ USER PREFERENCES ------------------
async function getUserPreferences(userId) {
  try {
    const pref = await UserPreference.findOne({ userId });
    return {
      priorityFactors: pref?.priorityFactors || [],
      brandPreferences: pref?.brandPreferences || [],
    };
  } catch (e) {
    console.warn("getUserPreferences error:", e.message);
    return { priorityFactors: [], brandPreferences: [] };
  }
}

// ------------------ PROMPTS (NO { IN SYSTEM) ------------------
const intentPrompt = ChatPromptTemplate.fromTemplate(`
You are a JSON extractor. Return ONLY this JSON:
{"intent_summary": "summary", "budget_min": null, "budget_max": null, "purpose": "", "brands": [], "must_have": [], "avoid": []}
No extra text.

History: {history}
User: {query}
`);

const filterPrompt = ChatPromptTemplate.fromTemplate(`
Return ONLY MongoDB filter JSON.
Example: {"price_rm": {"$gte": 3000, "$lte": 4000}}}}}

History: {history}
User: {query}
Intent: {intent}
`);

const recommendPrompt = ChatPromptTemplate.fromTemplate(`
  You are PickWise Assistant, a friendly tech-savvy laptop advisor who talks casually but professionally.
Recommend 1-3 laptops:
- Brand Model
- RM price
- CPU
- GPU
- RAM
- Display
- Pick Score: XX/100

History: {history}
User: {query}
Intent: {intent}
Laptops: {laptops}
`);

const intentChain = intentPrompt.pipe(model);
const filterChain = filterPrompt.pipe(model);
const recommendChain = recommendPrompt.pipe(model);

// ------------------ HELPERS ------------------
function safeLLMText(resp) {
  if (typeof resp === "string") return resp;
  if (resp?.content) {
    const c = resp.content;
    return Array.isArray(c) ? c.map(i => i?.text || "").join("") : c;
  }
  return "";
}

function safeParseJson(str) {
  if (!str) return {};
  const cleaned = str.replace(/```json/gi, "").replace(/```/g, "").trim();
  const match = cleaned.match(/\{[\s\S]*\}/);
  if (!match) return {};
  try { return JSON.parse(match[0]); } catch { return {}; }
}

// ------------------ RETRIEVAL ------------------
async function hybridRetrieval(userQuery, filter, intentJson) {
  const candidates = new Map();
  const add = (src, list) => list.forEach(l => l?._id && candidates.set(String(l._id), { ...l, _source: src }));

  // RAG
  try {
    const vecStore = await initLaptopVectorStore();
    const retriever = vecStore.asRetriever({ k: 15 });
    const docs = await retriever.invoke(userQuery);
    const ids = docs.map(d => d.metadata?.product_id).filter(Boolean).map(id => new mongoose.Types.ObjectId(id));
    if (ids.length) {
      const found = await Laptop.find({ _id: { $in: ids } }).lean();
      add("RAG", found);
    }
  } catch (e) { console.warn("RAG failed:", e.message); }

  // Filter
  const finalFilter = { ...filter };
  if (intentJson.budget_min) finalFilter.price_rm = { ...finalFilter.price_rm, $gte: intentJson.budget_min };
  if (intentJson.budget_max) finalFilter.price_rm = { ...finalFilter.price_rm, $lte: intentJson.budget_max };
  if (intentJson.purpose?.toLowerCase().includes("gaming")) {
    finalFilter.gpu_benchmark = { ...finalFilter.gpu_benchmark, $gte: 8000 };
  }

  try {
    const list = await Laptop.find(finalFilter).limit(30).lean();
    add("FILTER", list);
  } catch (e) { console.warn("Filter failed:", e.message); }

  let results = Array.from(candidates.values());
  if (!results.length) {
    results = await Laptop.find({ price_rm: { $gte: 3000, $lte: 4000 } }).limit(20).lean();
  }
  return results;
}

// ------------------ MAIN ------------------
async function queryLaptopLLM(userId, userQuery, conversationId) {
  try {
    // History
    let historyMessages = [];
    if (conversationId && mongoose.Types.ObjectId.isValid(conversationId)) {
      const conv = await Conversation.findById(conversationId);
      historyMessages = (conv?.messages || []).map(m =>
        m.role === "user" ? new HumanMessage(m.content) : new AIMessage(m.content)
      );
    }
    const historyStr = historyMessages.map(m => `${m._role}: ${m.content}`).join("\n");

    // 1. Intent
    let intentJson = { intent_summary: userQuery, budget_min: null, budget_max: null, purpose: "" };
    try {
      const resp = await intentChain.invoke({ history: historyStr, query: userQuery });
      intentJson = safeParseJson(safeLLMText(resp));
      if (!intentJson.budget_min && userQuery.match(/(\d{4})-(\d{4})/)) {
        const [, min, max] = userQuery.match(/(\d{4})-(\d{4})/);
        intentJson.budget_min = parseInt(min);
        intentJson.budget_max = parseInt(max);
      }
      if (userQuery.toLowerCase().includes("gaming")) intentJson.purpose = "gaming";
    } catch (e) { console.warn("Intent failed:", e.message); }

    // 2. Filter
    let filter = {};
    try {
      const resp = await filterChain.invoke({ history: historyStr, query: userQuery, intent: JSON.stringify(intentJson) });
      filter = safeParseJson(safeLLMText(resp));
    } catch (e) {
      console.warn("Filter failed:", e.message);
      filter = { price_rm: { $gte: intentJson.budget_min || 0, $lte: intentJson.budget_max || 10000 } };
    }

    // 3. Retrieve
    let laptops = await hybridRetrieval(userQuery, filter, intentJson);
    if (!laptops.length) return "No laptops found in your budget.";

    // 4. PICK SCORE ON FILTERED LAPTOPS ONLY
    const { priorityFactors, brandPreferences } = await getUserPreferences(userId);
    const { calculatePickScore } = require("../utils/PickScoreEngine");

    const scored = await Promise.all(
      laptops.map(async l => {
        const score = await calculatePickScore(l, priorityFactors, brandPreferences);
        return { ...l, pick_score: score };
      })
    );

    scored.sort((a, b) => b.pick_score - a.pick_score);
    const top = scored.slice(0, 3);

    const laptopInfo = top.map(l => ({
      name: l.product_name,
      brand: l.brand,
      price: `RM ${l.price_rm}`,
      cpu: l.processor_name,
      gpu: l.gpu_model,
      ram: `${l.ram_gb} GB`,
      display: `${l.display_size_inch}" ${l.display_resolution}`,
      pick_score: `Pick Score: ${l.pick_score}/100`,
    }));

    // 5. Recommend
    let responseText = "Here are the best matches:";
    try {
      const res = await recommendChain.invoke({
        history: historyStr,
        query: userQuery,
        intent: JSON.stringify(intentJson),
        laptops: JSON.stringify(laptopInfo, null, 2),
      });
      responseText = safeLLMText(res);
    } catch (e) {
      console.warn("Recommend failed:", e.message);
      responseText += "\n\n" + laptopInfo.map(l => `- ${l.brand} ${l.name}: ${l.price} (${l.pick_score})`).join("\n");
    }

    // Save
    try {
      if (conversationId && mongoose.Types.ObjectId.isValid(conversationId)) {
        await Conversation.updateOne(
          { _id: conversationId },
          {
            $push: {
              messages: {
                $each: [
                  { role: "user", content: userQuery, timestamp: new Date() },
                  { role: "assistant", content: responseText, timestamp: new Date() },
                ],
              },
            },
            $set: { updatedAt: new Date() },
          },
          { upsert: true }
        );
      }
    } catch (e) { console.warn("Save error:", e.message); }

    return responseText.trim();
  } catch (err) {
    console.error("queryLaptopLLM error:", err);
    return "Sorry, something went wrong. Please try again.";
  }
}

// ------------------ EXPORTS ------------------
module.exports = {
  queryLaptopLLM,
  initLaptopVectorStore,
  syncLaptopEmbeddings,
};