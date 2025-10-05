const mongoose = require("mongoose");
const db = require('../db');

const userPreferenceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  budget: { type: String }, 
  purpose: { type: String },
  priorityFactors: [String], 
  screenSize: { type: String }, 
  portabilityPreference: { type: String },
  preferredBrands: [String], 
  createdAt: { type: Date, default: Date.now }
});

const UserPreference = mongoose.model("UserPreference", userPreferenceSchema);
module.exports = UserPreference;
