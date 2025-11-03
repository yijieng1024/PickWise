require("dotenv").config({ path: "../.env" });
const fs = require("fs");
const csv = require("csv-parser");
const mongoose = require("mongoose");
const connectDB = require("../db"); // 引入你现成的连接模块
const Laptop = require("../models/Laptop");

const CSV_FILE_PATH = "../data/laptops_latest.csv"; // 你的CSV路径

async function importData() {
  await connectDB(); // 等待连接成功

  const laptops = [];

  fs.createReadStream(CSV_FILE_PATH)
    .pipe(csv())
    .on("data", (row) => {
      // remove empty fields and trim spaces
      const firstkey = Object.keys(row)[0];
      if (firstkey.startsWith("\ufeff")) {
        const cleanKey = firstkey.replace("\ufeff", "");
        row[cleanKey] = row[firstkey];
        delete row[firstkey];
      }
      Object.keys(row).forEach((key) => {
        if (row[key] === "") {
          delete row[key];
        } else {
          row[key] = row[key].trim();
        }
      });

      // 自动转换数值
      const num = (v) => (v && !isNaN(v) ? parseFloat(v) : undefined);

      laptops.push({
        model_code: row["model_code"],
        brand: row["brand"],
        product_name: row["product_name"],
        color: row["color"],
        price_rm: num(row["price_rm"]),
        imageURL: row["imageURL"],
        copilot_support: row["copilot_support"],
        processor_name: row["processor_name"],
        processor_brand: row["processor_brand"],
        processor_ghz: num(row["processor_ghz"]),
        cpu_benchmark: num(row["cpu_benchmark"]),
        ram_gb: num(row["ram_gb"]),
        ram_type: row["ram_type"],
        display_type: row["display_type"],
        display_resolution: row["display_resolution"],
        display_size_inch: num(row["display_size_inch"]),
        display_refresh_rate_hz: num(row["display_refresh_rate_hz"]),
        gpu_model: row["gpu_model"],
        gpu_brand: row["gpu_brand"],
        gpu_benchmark: num(row["gpu_benchmark"]),
        ssd_gb: num(row["ssd_gb"]),
        ssd_type: row["ssd_type"],
        io_ports: row["io_ports"],
        network: row["network"],
        bluetooth: row["bluetooth"],
        power_supply: row["power_supply"],
        battery_capacity_wh: num(row["battery_capacity_wh"]),
        dimension_cm: row["dimension_cm"],
        weight_kg: num(row["weight_kg"]),
        bundle: row["bundle"],
        microsoft_office: row["microsoft_office"],
        warranty: row["warranty"],
        release_year: num(row["release_year"]),
        expansion_slots: row["expansion_slots"],
        os: row["os"],
      });
    })
    .on("end", async () => {
      try {
        await Laptop.deleteMany();
        await Laptop.insertMany(laptops);
        console.log(`✅ Successfully imported ${laptops.length} laptops`);
      } catch (err) {
        console.error("❌ Import error:", err);
      } finally {
        mongoose.connection.close();
      }
    });
}

importData();
