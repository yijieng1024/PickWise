const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const Laptop = require("../models/Laptop");
require("dotenv").config();

// Middleware: Verify JWT Token
const verifyToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) return res.status(401).json({ message: "Access denied. No token provided." });

  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET);
    req.user = verified; // Attach decoded user info to request
    next();
  } catch (err) {
    res.status(403).json({ message: "Invalid token." });
  }
};

// ✅ GET all laptops
router.get("/", verifyToken, async (req, res) => {
  try {
    const laptops = await Laptop.find();
    res.json(laptops);
  } catch (error) {
    console.error("Error fetching laptops:", error);
    res.status(500).json({ message: "Server error fetching laptops" });
  }
});

// ✅ GET laptop by ID
router.get("/:id", verifyToken, async (req, res) => {
  try {
    const laptop = await Laptop.findById(req.params.id);
    if (!laptop) {
      return res.status(404).json({ message: "Laptop not found" });
    }
    res.json(laptop);
  } catch (error) {
    console.error("Error fetching laptop:", error);
    res.status(500).json({ message: "Server error fetching laptop" });
  }
});

module.exports = router;
