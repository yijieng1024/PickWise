const express = require("express");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { queryLaptopLLM } = require("../ai/callLLM");
const Conversation = require("../models/Conversation");

dotenv.config();
const router = express.Router();

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);

// 🔹 Create a new conversation with auto-generated title
router.post("/create", async (req, res) => {
  try {
    const { userId, message } = req.body;
    const userText = message?.text || "";

    let generatedTitle = "Untitled Conversation";
    if (userText.trim()) {
      try {
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
        const prompt = `Generate a short, natural conversation title (max 6 words) that summarizes this message:\n\n"${userText}"`;
        const result = await model.generateContent(prompt);
        generatedTitle = result.response.text().trim() || "Untitled Conversation";
      } catch (titleError) {
        console.error("Gemini title generation failed:", titleError);
      }
    }

    const newConversation = new Conversation({
      userId,
      title: generatedTitle,
      messages: [
        {
          role: message.role || message.sender || "user",
          content: message.text || "",
          timestamp: new Date(),
        },
      ],
    });

    await newConversation.save();
    res.status(201).json(newConversation);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to create conversation" });
  }
});

router.post("/save", async (req, res) => {
  try {
    // 🔍 Log all incoming data
    console.log("🟢 [POST /api/conversation/save] Incoming request body:");
    console.log(JSON.stringify(req.body, null, 2));

    const { userId, messages, conversationId } = req.body;

    // 🧩 Log extracted values
    console.log("➡️ Extracted userId:", userId);
    console.log("➡️ Extracted conversationId:", conversationId);
    console.log("➡️ Messages count:", messages ? messages.length : "No messages");

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      console.log("❌ Invalid userId detected:", userId);
      return res.status(400).json({ error: "Invalid userId" });
    }

    let conversation;
    if (conversationId && mongoose.Types.ObjectId.isValid(conversationId)) {
      console.log("🟡 Updating existing conversation:", conversationId);
      conversation = await Conversation.findById(conversationId);
      if (!conversation) {
        console.log("❌ Conversation not found:", conversationId);
        return res.status(404).json({ error: "Conversation not found" });
      }

      conversation.messages = messages.map((msg) => ({
        role: msg.role || msg.sender || "user",
        content: msg.content || msg.text || "",
        timestamp: msg.timestamp || new Date(),
      }));

      const latestUserMessage = messages.find((msg) => msg.role === "user")?.content;
      if (latestUserMessage) {
        conversation.title = await generateTitle(latestUserMessage);
      }
    } else {
      console.log("🆕 Creating new conversation for user:", userId);
      const generatedTitle =
        messages.length > 0 ? await generateTitle(messages[0].content) : "Untitled Conversation";

      conversation = new Conversation({
        userId,
        title: generatedTitle,
        messages: messages.map((msg) => ({
          role: msg.role || msg.sender || "user",
          content: msg.content || msg.text || "",
          timestamp: msg.timestamp || new Date(),
        })),
      });
    }

    await conversation.save();
    console.log("✅ Conversation saved successfully:", conversation._id);

    res.status(201).json(conversation);
  } catch (error) {
    console.error("🔥 Error saving conversation:", error);
    res.status(500).json({ error: "Failed to save conversation" });
  }
});


async function generateTitle(messageContent) {
  try {
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
    const prompt = `Generate a short, natural conversation title (max 6 words) that summarizes this message:\n\n"${messageContent}"`;
    const result = await model.generateContent(prompt);
    return result.response.text().trim() || "Untitled Conversation";
  } catch (error) {
    console.error("Gemini title generation failed:", error);
    return "Untitled Conversation";
  }
}

router.post("/send", async (req, res) => {
  try {
    const { message, conversationId, userId } = req.body;
    const response = await queryLaptopLLM(userId, message, conversationId);
    res.status(200).json({ reply: response });
  } catch (error) {
    console.error("Error in /send:", error);
    res.status(500).json({ error: "Failed to process message" });
  }
});

router.post("/:id/add-message", async (req, res) => {
  try {
    const { message } = req.body;
    const conversation = await Conversation.findById(req.params.id);

    if (!conversation) return res.status(404).json({ error: "Conversation not found" });

    conversation.messages.push(message);
    conversation.updatedAt = new Date();
    await conversation.save();

    res.status(200).json(conversation);
  } catch (error) {
    res.status(500).json({ error: "Failed to add message" });
  }
});

module.exports = router;
