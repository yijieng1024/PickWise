const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const dotenv = require("dotenv");
const connectDB = require("./db");
const authRoutes = require("./routes/auth");
const profileRoutes = require("./routes/profile");
const aiRouter = require("./routes/aiRoute");
const conversationRoutes = require("./routes/conversationRoute");
const cartRoutes = require ("./routes/cartRoutes");

// require("./PickAI").initLaptopVectorStore().then(() => console.log("Warm"));

require("dotenv").config();
const app = express();

// Log every incoming request
app.use((req, res, next) => {
  console.log(`➡️ ${req.method} ${req.url}`);
  next();
});

// Middleware
app.use(cors());
app.use(bodyParser.json());

// DB Connection
connectDB().catch(err => {
  console.error("Failed to connect to MongoDB", err);
  process.exit(1);
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/ai", aiRouter);
app.use("/api/conversation", conversationRoutes);
app.use("/api/laptops", require("./routes/laptopRoute"));
app.use("/api/cart", cartRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});

