require("dotenv").config();
const {
  ChatGoogleGenerativeAI,
} = require("@langchain/google-genai");
const {
  ChatPromptTemplate,
} = require("@langchain/core/prompts");
const { MongoDBAtlasVectorSearch } = require("@langchain/mongodb");
const { GoogleGenerativeAIEmbeddings } = require("@langchain/google-genai");
const mongoose = require("mongoose");
const { MongoClient } = require("mongodb");

const Laptop = require("../models/Laptop");
const UserPreference = require("../models/userpreference");
const Conversation = require("../models/Conversation");
const { calculatePickScore } = require("../utils/PickScoreEngine");

// ------------------ ENV ------------------
const MONGO_URL = process.env.MONGO_URL || process.env.MONGO_URI;
const MONGO_DB = process.env.MONGO_DB || "test";
if (!MONGO_URL) throw new Error("Missing MONGO_URL");
if (!process.env.GOOGLE_API_KEY) throw new Error("Missing GOOGLE_API_KEY");

// ------------------ SINGLETONS ------------------
let _model, _embeddings, _vecStore, _mongoClient;
const getModel = () => _model ??= new ChatGoogleGenerativeAI({
  model: "gemini-2.5-flash",
  temperature: 0.75,
  apiKey: process.env.GOOGLE_API_KEY,
  maxRetries: 2,
});

const getEmbeddings = () => _embeddings ??= new GoogleGenerativeAIEmbeddings({
  model: "text-embedding-004",
  apiKey: process.env.GOOGLE_API_KEY,
});

const getMongoClient = async () => {
  if (_mongoClient) return _mongoClient;
  _mongoClient = new MongoClient(MONGO_URL, {
    maxPoolSize: 10,
    serverSelectionTimeoutMS: 5000,
  });
  await _mongoClient.connect();
  return _mongoClient;
};

const getVectorStore = async () => {
  if (_vecStore) return _vecStore;
  const client = await getMongoClient();
  const coll = client.db(MONGO_DB).collection("laptops");
  _vecStore = new MongoDBAtlasVectorSearch(getEmbeddings(), {
    collection: coll,
    indexName: "laptop_vector_index",
    embeddingKey: "embedding",
    textKey: "pageContent",
  });
  return _vecStore;
};

// ------------------ PROMPTS (Picko Style) ------------------
const intentTpl = ChatPromptTemplate.fromTemplate(`
You are JSON ninja. Return ONLY this:
{
  "intent_summary": "string",
  "budget_min": number | null,
  "budget_max": number | null,
  "purpose": "gaming|editing|office|general",
  "brands": search in database,
  "must_have": ["RTX", "16GB"],
  "avoid": ["Intel UHD"],
  "clarification_required": true|false,
  "clarification": "Ask budget / software / weight"
}
NO extra words.

History: {history}
Memory: {memory}
User: {query}`);

const filterTpl = ChatPromptTemplate.fromTemplate(`
Return ONLY MongoDB filter JSON.
Example: 
{{"price_rm":{{"$gte":3000,"$lte":5000}}}},
{"gpu_benchmark":{{"$gte":8000}}}}}

History: {history}
User: {query}
Intent: {intent}`);

const recommendTpl = ChatPromptTemplate.fromTemplate(`
You are Picko, a Malaysian laptop kaki from PickWise.
You call everyone "boss", end half your sentences with "lah", roast bad picks with 😂, 
and always drop ONE emoji. Close every reply with "Deal or not?"

Rules:
- Talk like texting your best friend
- Never say "based on your request"
- If user wants Intel UHD → reply "UHD? Boss you editing video or PowerPoint ah? 😂"
- If clarification_required → ONLY ask the question, NO laptop list

History:
{history}

Long-term memory (last 5 visits):
{memory}

User: {query}
Intent: {intent}
Laptops: {laptops}
`);

let _intentChain, _filterChain, _recommendChain;
const getIntentChain = () => _intentChain ??= intentTpl.pipe(getModel());
const getFilterChain = () => _filterChain ??= filterTpl.pipe(getModel());
const getRecommendChain = () => _recommendChain ??= recommendTpl.pipe(getModel());

// ------------------ UTILS ------------------
const BUDGET_REGEX = /(\d{4})\s*[-~]\s*(\d{4})/;
const cleanJson = str => {
  if (!str) return {};
  const m = str.match(/\{[\s\S]*\}/);
  return m ? JSON.parse(m[0]) : {};
};
const text = resp => resp?.content
  ? (Array.isArray(resp.content)
      ? resp.content.map(c => c?.text ?? "").join("")
      : resp.content)
  : "";

// ------------------ MAIN AGENT ------------------
async function queryLaptopLLM(userId, userQuery, conversationId) {
  const start = Date.now();
  try {
    // 0. Load short + long memory
    const [conv, pref] = await Promise.all([
      conversationId && mongoose.Types.ObjectId.isValid(conversationId)
        ? Conversation.findById(conversationId, "messages").lean()
        : null,
      UserPreference.findOne({ userId }).lean(),
    ]);

    const historyStr = conv?.messages
      ? conv.messages.map(m => `${m.role === "user" ? "User" : "Assistant"}: ${m.content}`).join("\n")
      : "";

    const memoryStr = (pref?.longTermMemory || [])
      .slice(-5)
      .map(m => `${new Date(m.date).toLocaleDateString()}: ${m.summary}`)
      .join("\n") || "No past visits";

    // 1. Intent + Filter parallel
    const [intentResp, filterResp] = await Promise.all([
      getIntentChain().invoke({ history: historyStr, memory: memoryStr, query: userQuery }),
      getFilterChain().invoke({ history: historyStr, query: userQuery, intent: "{}" }),
    ]);

    let intent = cleanJson(text(intentResp));
    if (!intent.budget_min) {
      const m = userQuery.match(BUDGET_REGEX);
      if (m) [intent.budget_min, intent.budget_max] = m.slice(1).map(Number);
    }

    // 2. Clarification → short-circuit
    if (intent.clarification_required) {
      const q = await getRecommendChain().invoke({
        history: historyStr,
        memory: memoryStr,
        query: userQuery,
        intent: JSON.stringify(intent),
        laptops: "[]",
      });
      return text(q).trim();
    }

    // 3. Build filter
    let filter = cleanJson(text(filterResp));
    filter.price_rm = {
      ...(filter.price_rm || {}),
      ...(intent.budget_min ? { $gte: intent.budget_min } : {}),
      ...(intent.budget_max ? { $lte: intent.budget_max } : {}),
    };
    if (intent.purpose === "gaming")
      filter.gpu_benchmark = { ...(filter.gpu_benchmark || {}), $gte: 8000 };

    // 4. Hybrid RAG + Filter parallel
    const vecStore = await getVectorStore();
    const ragPromise = vecStore.asRetriever({ k: 12 }).invoke(userQuery)
      .then(docs => docs.map(d => d.metadata?.product_id).filter(Boolean))
      .then(ids => ids.length ? Laptop.find({ _id: { $in: ids.map(id => new mongoose.Types.ObjectId(id)) } }).lean() : []);

    const filterPromise = Laptop.find(filter).limit(30).lean();
    const [ragLaptops, filterLaptops] = await Promise.all([ragPromise, filterPromise]);

    // Dedupe
    const seen = new Set();
    const laptops = [];
    for (const l of [...ragLaptops, ...filterLaptops]) {
      const key = l._id.toString();
      if (!seen.has(key)) { seen.add(key); laptops.push(l); }
    }

    if (!laptops.length) {
      const fallback = await Laptop.find({
        price_rm: { $gte: intent.budget_min ?? 2500, $lte: intent.budget_max ?? 6000 },
      }).limit(10).lean();
      laptops.push(...fallback);
    }
    if (!laptops.length) return "Boss, really no stock lah. Widen budget can? 😅";

    // 5. Score parallel
    const { priorityFactors = [], brandPreferences = [] } = pref || {};
    const scored = await Promise.all(
      laptops.map(l => calculatePickScore(l, priorityFactors, brandPreferences)
        .then(score => ({ ...l, pick_score: score }))
      )
    );
    scored.sort((a, b) => b.pick_score - a.pick_score);
    const top = scored.slice(0, 3);

    const pretty = top.map(l => ({
      name: l.product_name,
      brand: l.brand,
      price: `RM ${l.price_rm}`,
      cpu: l.processor_name,
      gpu: l.gpu_model,
      ram: `${l.ram_gb} GB`,
      display: `${l.display_size_inch}" ${l.display_resolution}`,
      pick_score: `Pick Score: ${l.pick_score}/100`,
    }));

    // 6. Final reply
    const rec = await getRecommendChain().invoke({
      history: historyStr,
      memory: memoryStr,
      query: userQuery,
      intent: JSON.stringify(intent),
      laptops: JSON.stringify(pretty, null, 2),
    });

    let answer = text(rec).trim();
    if (!answer.includes("Pick Score")) {
      answer += "\n\n" + pretty.map(p =>
        `• **${p.brand} ${p.name}** – ${p.price}\n  ${p.cpu} • ${p.gpu} • ${p.ram} • ${p.display}\n  ${p.pick_score} 🔥`
      ).join("\n\n");
    }

    // 7. Save BOTH memories (fire-and-forget)
    const summary = `${intent.purpose || 'general'} laptop, budget ${intent.budget_min || '?'}–${intent.budget_max || '?'} RM`;
    UserPreference.updateOne(
      { userId }, 
      { $push: { longTermMemory: { date: new Date(), summary, rawQuery: userQuery }}}
    ).catch(() => {});

    if (conversationId && mongoose.Types.ObjectId.isValid(conversationId)) {
      Conversation.updateOne(
        { _id: conversationId },
        {
          $push: { messages: { $each: [
            { role: "user", content: userQuery, timestamp: new Date() },
            { role: "assistant", content: answer, timestamp: new Date() },
          ]}},
          $set: { updatedAt: new Date() },
        },
        { upsert: true }
      ).catch(() => {});
    }

    console.log(`Picko replied in ${Date.now() - start} ms ⚡`);
    return answer;

  } catch (err) {
    console.error("Picko fainted:", err);
    return "Aiya boss, system jam lah. Try again 10 seconds can? 😅";
  }
}

// ------------------ EXPORTS ------------------
module.exports = {
  queryLaptopLLM,
  initLaptopVectorStore: getVectorStore,
  // syncLaptopEmbeddings: require("./sync").syncLaptopEmbeddings,
};