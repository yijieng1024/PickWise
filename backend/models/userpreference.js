// models/userpreference.js
const mongoose = require("mongoose");

const userPreferenceSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: "User", 
    required: true 
  },
  budget: { type: String },
  purpose: { type: String },
  priorityFactors: [String],
  screenSize: { type: String },
  portabilityPreference: { type: String },
  preferredBrands: [String],
  createdAt: { type: Date, default: Date.now },

  longTermMemory: [{
    date: { type: Date, default: Date.now },
    summary: { type: String, required: true },
    rawQuery: { type: String, required: true }
  }]
}, { 
  timestamps: true
});

const UserPreference = mongoose.model("UserPreference", userPreferenceSchema);
module.exports = UserPreference;