const express = require("express");
const bcrypt = require('bcryptjs');
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const router = express.Router();

// ✅ Signup
router.post("/signup", async (req, res) => {
  try {
    console.log("📥 Incoming signup request:", req.body);

    const { username, email, password } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log("⚠️ Email already registered:", email);
      return res.status(400).json({ message: "Email already registered" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    console.log("🔑 Password hashed successfully");
    console.log("🔒 Hashed Password:", hashedPassword);
    // console.log("bcrypt:" bcrypt);

    const newUser = new User({
      username,
      email,
      password: hashedPassword,
    });

    await newUser.save();
    console.log("✅ User saved to MongoDB:", newUser._id);

    res.status(201).json({ message: "User registered successfully ✅" });
  } catch (err) {
    console.error("❌ Signup error:", err.message);
    res.status(500).json({ message: "Signup failed", error: err.message });
  }
});

// ✅ Normal login (email + password)
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // 找用户
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }

    // 密码为空（表示Google账号）
    if (!user.password) {
      return res.status(400).json({ message: "This account is registered with Google login" });
    }

    // 验证密码
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // 签发 JWT
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: "7d" });

    res.status(200).json({
      message: "Login successful",
      token,
      user: { id: user._id, username: user.username, email: user.email, photoUrl: user.photoUrl },
    });
  } catch (err) {
    console.error("❌ Login error:", err.message);
    res.status(500).json({ message: "Login failed", error: err.message });
  }
});


// ✅ Google login / signup
router.post("/google", async (req, res) => {
  try {
    const { uid, email, username, photoUrl } = req.body;

    let user = await User.findOne({ email });
    if (!user) {
      user = new User({
        username: username || email.split("@")[0],
        email,
        password: null,
        photoUrl,
        googleId: uid,
      });
      await user.save();
      console.log("✅ New Google user saved:", user._id);
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: "7d" });

    res.status(200).json({
      message: "Google login successful",
      token,
      user: { id: user._id, username: user.username, email: user.email, photoUrl: user.photoUrl },
    });
  } catch (err) {
    console.error("❌ Google login error:", err.message);
    res.status(500).json({ message: "Google login failed", error: err.message });
  }
});



module.exports = router;


