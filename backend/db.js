const mongoose = require("mongoose");
require("dotenv").config();

async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGO_URL); // 改成 await，确保异步等待
    console.log("✅ MongoDB connected:", mongoose.connection.host);
    
    // 可选：监听连接事件，更robust
    mongoose.connection.on("connected", () => {
      console.log("🔗 Mongoose connected to MongoDB");
    });
    
    mongoose.connection.on("error", (err) => {
      console.error("❌ Mongoose connection error:", err);
    });
    
    mongoose.connection.on("disconnected", () => {
      console.log("🔌 Mongoose disconnected");
    });
    
  } catch (error) {
    console.error("❌ MongoDB connection failed:", error.message);
    process.exit(1);
  }
}

module.exports = connectDB;