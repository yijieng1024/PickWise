const Otp = require("../models/Otp");
const nodemailer = require("nodemailer");

// Generate 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Send email
async function sendEmail(to, otpCode) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: `"PickWise OTP" <${process.env.EMAIL_USER}>`,
    to,
    subject: "Your OTP Code",
    text: `Your verification code is: ${otpCode}. It will expire in 5 minutes.`,
  });
}

exports.requestOtp = async (req, res) => {
  try {
    const { email } = req.body;

    // Generate OTP
    const otpCode = generateOTP();

    // Save OTP in DB
    const otp = new Otp({ email, code: otpCode });
    await otp.save();

    // Send via email
    await sendEmail(email, otpCode);

    res.json({ message: "OTP sent to email" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { email, code } = req.body;

    // Find OTP
    const otpRecord = await Otp.findOne({ email, code });

    if (!otpRecord) {
      return res.status(400).json({ message: "Invalid or expired OTP" });
    }

    // OTP is valid → delete after use
    await Otp.deleteMany({ email });

    res.json({ message: "OTP verified successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
