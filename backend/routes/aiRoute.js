const express = require("express");
const { queryLaptopLLM } = require("../ai/PickAI");

const router = express.Router();

router.post("/recommend", async (req, res) => {
  const { query } = req.body;

  if (!query) return res.status(400).json({ error: "Missing query text" });

  const answer = await queryLaptopLLM(query);
  res.json({ answer });
});

module.exports = router;
