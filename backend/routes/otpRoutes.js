const express = require("express");
const { requestOtp, verifyOtp } = require("../controllers/otpController");

const router = express.Router();

router.post("/request", requestOtp);  // Request OTP
router.post("/verify", verifyOtp);    // Verify OTP

module.exports = router;
