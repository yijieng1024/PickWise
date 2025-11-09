const express = require("express");
const router = express.Router();
const Cart = require("../models/Cart");
const Laptop = require("../models/Laptop");
const verifyToken = require("../middleware/verifyToken");

// ✅ Add item to cart
router.post("/add", async (req, res) => {
  try {
    const { userId, laptopId, quantity } = req.body;

    if (!userId || !laptopId) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    let cart = await Cart.findOne({ userId });

    if (!cart) {
      cart = new Cart({ userId, items: [] });
    }

    // Check if laptop already in cart
    const existingItem = cart.items.find(
      (item) => item.laptopId.toString() === laptopId
    );

    if (existingItem) {
      existingItem.quantity += quantity || 1;
    } else {
      cart.items.push({ laptopId, quantity: quantity || 1 });
    }

    await cart.save();
    res.json({ message: "Item added to cart", cart });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Server error" });
  }
});

// ✅ Get cart by user ID
router.get("/:userId", verifyToken, async (req, res) => {
  try {
    const cart = await Cart.findOne({ userId: req.params.userId }).populate("items.laptopId");
    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }
    res.json(cart);
  } catch (error) {
    console.error("Error fetching cart:", error);
    res.status(500).json({ message: "Server error fetching cart" });
  }
});

// ❌ Remove item
router.delete("/remove/:userId/:laptopId", async (req, res) => {
  try {
    const { userId, laptopId } = req.params;
    const cart = await Cart.findOne({ userId });
    if (!cart) return res.status(404).json({ message: "Cart not found" });

    cart.items = cart.items.filter(
      (item) => item.laptopId.toString() !== laptopId
    );
    await cart.save();
    res.json({ message: "Item removed", cart });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
});

// ✅ Clear cart after checkout
router.delete("/clear/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const cart = await Cart.findOne({ userId });
    if (!cart) return res.status(404).json({ message: "Cart not found" });

    cart.items = [];
    await cart.save();
    res.json({ message: "Cart cleared successfully" });
  } catch (error) {
    console.error("Error clearing cart:", error);
    res.status(500).json({ message: "Server error" });
  }
});


module.exports = router;
