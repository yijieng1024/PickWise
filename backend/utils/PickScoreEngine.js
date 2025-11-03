const Laptop = require("../models/Laptop");

// -------------------------------------------------
// 1. Cache statistical ranges
// -------------------------------------------------
let _rangesCache = null;
let _cacheTimestamp = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 min

async function getStatisticalRanges() {
  const now = Date.now();
  if (_rangesCache && now - _cacheTimestamp < CACHE_TTL_MS) {
    return _rangesCache;
  }

  const format = (stats) => (stats[0] ? { min: stats[0].min, max: stats[0].max } : { min: 0, max: 1 });

  const [
    priceStats,
    cpuStats,
    gpuStats,
    weightStats,
    batteryStats,
  ] = await Promise.all([
    Laptop.aggregate([{ $group: { _id: null, min: { $min: "$price_rm" }, max: { $max: "$price_rm" } } }]),
    Laptop.aggregate([{ $group: { _id: null, min: { $min: "$cpu_benchmark" }, max: { $max: "$cpu_benchmark" } } }]),
    Laptop.aggregate([{ $group: { _id: null, min: { $min: "$gpu_benchmark" }, max: { $max: "$gpu_benchmark" } } }]),
    Laptop.aggregate([{ $group: { _id: null, min: { $min: "$weight_kg" }, max: { $max: "$weight_kg" } } }]),
    Laptop.aggregate([{ $group: { _id: null, min: { $min: "$battery_capacity_wh" }, max: { $max: "$battery_capacity_wh" } } }]),
  ]);

  _rangesCache = {
    price: format(priceStats),
    cpu: format(cpuStats),
    gpu: format(gpuStats),
    weight: format(weightStats),
    battery: format(batteryStats),
  };
  _cacheTimestamp = now;

  return _rangesCache;
}

// -------------------------------------------------
// 2. Brand score
// -------------------------------------------------
function calculateBrandScore(laptopBrand, userBrandPreferences) {
  if (!Array.isArray(userBrandPreferences) || userBrandPreferences.length === 0) return 50;
  return userBrandPreferences.includes(laptopBrand) ? 100 : 50;
}

// -------------------------------------------------
// 3. Normalize 0–100
// -------------------------------------------------
function normalize(value, min, max, inverse = false) {
  if (value == null || typeof value !== "number" || isNaN(value)) return 0;
  if (max <= min) return inverse ? 100 : 0;
  let score = ((value - min) / (max - min)) * 100;
  score = Math.max(0, Math.min(100, score));
  return inverse ? 100 - score : score;
}

// -------------------------------------------------
// 4. Default priorities (when user has none)
// -------------------------------------------------
const DEFAULT_PRIORITY = [
  "Price",
  "CPU Performance",
  "GPU Performance",
  "Portability (weight, size)",
  "Battery Life",
  "Brand"
];

// -------------------------------------------------
// 5. Main PickScore
// -------------------------------------------------
async function calculatePickScore(laptop, priorityFactors = [], brandPreferences = []) {
  if (!laptop) return 0;

  const priorities = priorityFactors.length > 0 ? priorityFactors : DEFAULT_PRIORITY;
  const brandScore = calculateBrandScore(laptop.brand, brandPreferences);
  const ranges = await getStatisticalRanges();

  const scores = {
    Price: normalize(laptop.price_rm, ranges.price.min, ranges.price.max, true),
    "CPU Performance": normalize(laptop.cpu_benchmark, ranges.cpu.min, ranges.cpu.max),
    "GPU Performance": normalize(laptop.gpu_benchmark, ranges.gpu.min, ranges.gpu.max),
    "Portability (weight, size)": normalize(laptop.weight_kg, ranges.weight.min, ranges.weight.max, true),
    "Battery Life": normalize(laptop.battery_capacity_wh, ranges.battery.min, ranges.battery.max),
    Brand: brandScore,
  };

  // Weight by position: higher index = lower priority
  const weights = {};
  priorities.forEach((f, i) => {
    weights[f] = priorities.length - i;
  });

  let weightedSum = 0;
  let totalWeight = 0;

  for (const factor of priorities) {
    const score = scores[factor] ?? 0;
    const weight = weights[factor] ?? 1;
    weightedSum += score * weight;
    totalWeight += weight;
  }

  const pickScore = totalWeight > 0 ? Math.round(weightedSum / totalWeight) : 50;
  return Math.max(0, Math.min(100, pickScore));
}

// -------------------------------------------------
module.exports = { calculatePickScore };