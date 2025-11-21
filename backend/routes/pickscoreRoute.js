const express = require("express");
const router = express.Router();
const { generatePickScore } = require("../utils/PickScoreEngine");

// calculate Pick_Score for a list of laptops for a user
router.post("/pickscore", async (req, res) => {
  try {
    const { userId, laptops } = req.body;

    if (!userId || !laptops || !Array.isArray(laptops)) {
      return res.status(400).json({ message: "Missing userId or laptop list." });
    }

    const result = await generatePickScore(userId, laptops);

    res.status(200).json(result);
  } catch (error) {
    console.error("❌ Pick_Score API error:", error);
    res.status(500).json({ message: "Error generating Pick_Score", error });
  }
});

module.exports = router;
