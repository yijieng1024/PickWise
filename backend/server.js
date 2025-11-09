const dotenv = require("dotenv");
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const connectDB = require("./db");
const authRoutes = require("./routes/auth");
const profileRoutes = require("./routes/profile");
const aiRouter = require("./routes/aiRoute");
const conversationRoutes = require("./routes/conversationRoute");
const cartRoutes = require ("./routes/cartRoutes");
const pickScoreRoute = require("./routes/pickscoreRoute");
const addressRoute = require("./routes/addressRoutes");

// require("./PickAI").initLaptopVectorStore().then(() => console.log("Warm"));

require("dotenv").config();
const app = express();

// ✅ Increase the JSON payload limit to 10MB
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));
app.use(cors());

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
app.use("/api", pickScoreRoute);
app.use("/address", addressRoute);
app.use("/api/order", require("./routes/orderRoute"));
app.use("/api/payment", require("./routes/paymentRoute"));

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});

