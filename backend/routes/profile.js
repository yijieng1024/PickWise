const express = require("express");
const multer = require("multer");
const User = require("../models/User");
const UserPreference = require("../models/userpreference");
const jwt = require("jsonwebtoken");
const path = require("path");

const router = express.Router();

// Avatar Upload (Multer local storage)
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/avatars/");
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname)); 
  },
});
const upload = multer({ storage: storage });

// Get user profile
router.get("/:id", async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Error retrieving profile" });
  }
});

// Update user profile (username, email, photo)
router.put("/:id", upload.single("avatar"), async (req, res) => {
  try {
    const updates = {
      username: req.body.username,
      email: req.body.email,
    };

    if (req.file) {
      updates.photoUrl = `/uploads/avatars/${req.file.filename}`;
    }

    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true });
    res.json({ message: "Profile updated", user });
  } catch (err) {
    res.status(500).json({ message: "Update failed" });
  }
});

// Get user preference profile
router.get("/preferences/:userId", async (req, res) => {
  try {
    const pref = await UserPreference.findOne({ userId: req.params.userId });
    if (!pref) {
      return res.status(404).json({ message: "No preferences found" });
    }
    res.status(200).json(pref);
  } catch (error) {
    console.error("❌ Error retrieving preferences:", error);
    res.status(500).json({ message: "Error retrieving preferences", error });
  }
});

// CREATE or UPDATE user preferences
router.post("/preferences/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      budget,
      purpose,
      priorityFactors,
      screenSize,
      portabilityPreference,
      preferredBrands,
    } = req.body;

    // Check if preferences already exist
    let pref = await UserPreference.findOne({ userId });

    if (!pref) {
      // Create new preference
      pref = new UserPreference({
        userId,
        budget,
        purpose,
        priorityFactors,
        screenSize,
        portabilityPreference,
        preferredBrands,
      });
      await pref.save();
      return res.status(201).json({ message: "✅ Preferences created", pref });
    } else {
      // Update existing preference
      pref.budget = budget || pref.budget;
      pref.purpose = purpose || pref.purpose;
      pref.priorityFactors = priorityFactors || pref.priorityFactors;
      pref.screenSize = screenSize || pref.screenSize;
      pref.portabilityPreference =
        portabilityPreference || pref.portabilityPreference;
      pref.preferredBrands = preferredBrands || pref.preferredBrands;
      await pref.save();
      return res.status(200).json({ message: "✅ Preferences updated", pref });
    }
  } catch (error) {
    console.error("❌ Error saving preferences:", error);
    res.status(500).json({ message: "Error saving preferences", error });
  }
});

module.exports = router;
