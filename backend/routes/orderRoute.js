const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Address = require('../models/Address');
const Laptop = require('../models/Laptop');
const Cart = require('../models/Cart');
const verifyToken = require('../middleware/verifyToken');

// Apply authentication to all order routes
router.use(verifyToken);

// CREATE NEW ORDER
router.post('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      addressId,
      items,
      merchandiseSubtotal,
      shippingFee,
      sstRate,
      sstAmount,
      discount,
      totalAmount,
      deliveryOption,
      paymentMethod,
      appliedVoucher,
      remark
    } = req.body;

    // Validate required fields
    if (!addressId || !items || items.length === 0) {
      return res.status(400).json({ 
        message: 'Address and items are required' 
      });
    }

    // Fetch and validate address
    const address = await Address.findOne({ 
      _id: addressId, 
      userId 
    });

    if (!address) {
      return res.status(404).json({ 
        message: 'Address not found' 
      });
    }

    // Validate and format order items
    const orderItems = [];
    let calculatedSubtotal = 0;

    for (const item of items) {
      const laptop = await Laptop.findById(item.laptopId);
      
      if (!laptop) {
        return res.status(404).json({ 
          message: `Laptop not found: ${item.laptopId}` 
        });
      }

      // Check stock availability
      if (laptop.stock < item.quantity) {
        return res.status(400).json({ 
          message: `Insufficient stock for ${laptop.product_name}` 
        });
      }

      const price = parseFloat(laptop.price_rm) || parseFloat(laptop.price) || 0;
      const subtotal = price * item.quantity;
      calculatedSubtotal += subtotal;

      orderItems.push({
        laptopId: laptop._id,
        productName: laptop.product_name,
        price: price,
        quantity: item.quantity,
        subtotal: subtotal
      });

      // Reduce laptop stock
      laptop.stock -= item.quantity;
      await laptop.save();
    }

    // Validate voucher if applied
    let finalDiscount = 0;
    let voucherInfo = null;

    if (appliedVoucher && appliedVoucher.trim().toUpperCase() === 'PICK10') {
      finalDiscount = calculatedSubtotal * 0.1;
      voucherInfo = {
        code: appliedVoucher.toUpperCase(),
        discountAmount: finalDiscount
      };
    }

    // Calculate final amounts
    const finalSstAmount = calculatedSubtotal * (sstRate || 0.06);
    const finalTotal = calculatedSubtotal + (shippingFee || 5.00) + finalSstAmount - finalDiscount;

    // Format delivery address
    const deliveryAddress = {
      addressId: address._id,
      fullName: address.fullName,
      phoneNumber: address.phoneNumber,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
      formattedAddress: `${address.addressLine1}, ${address.addressLine2 ? address.addressLine2 + ', ' : ''}${address.city}, ${address.state} ${address.postalCode}, ${address.country}`
    };

    // ——— GENERATE ORDER NUMBER BEFORE SAVING ———
    const orderNumber = await Order.generateOrderNumber();

    // Create order
    const order = new Order({
      userId,
      orderNumber,  // ← This is the fix
      deliveryAddress,
      items: orderItems,
      merchandiseSubtotal: calculatedSubtotal,
      shippingFee: shippingFee || 5.00,
      sstRate: sstRate || 0.06,
      sstAmount: finalSstAmount,
      discount: finalDiscount,
      totalAmount: finalTotal,
      deliveryOption: deliveryOption || 'Standard Delivery',
      paymentMethod: paymentMethod || 'Online Banking',
      appliedVoucher: voucherInfo,
      remark: remark || '',
      status: 'Pending',
      paymentStatus: 'Pending'
    });

    await order.save();

    // Clear cart items for ordered products
    const laptopIds = items.map(item => item.laptopId);
    await Cart.updateOne(
      { userId },
      { $pull: { items: { laptopId: { $in: laptopIds } } } }
    );

    res.status(201).json({
      message: 'Order placed successfully',
      order: order
    });

  } catch (error) {
    console.error('Order creation error:', error);
    res.status(500).json({ 
      message: 'Failed to create order', 
      error: error.message 
    });
  }
});

// GET ALL ORDERS FOR USER
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, page = 1, limit = 10 } = req.query;

    const query = { userId };
    if (status) {
      query.status = status;
    }

    const orders = await Order.find(query)
      .populate('items.laptopId', 'product_name imageURL brand')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();

    const count = await Order.countDocuments(query);

    res.json({
      orders,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalOrders: count
    });

  } catch (error) {
    console.error('Fetch orders error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch orders', 
      error: error.message 
    });
  }
});

// GET SINGLE ORDER BY ID
router.get('/:orderId', async (req, res) => {
  try {
    const userId = req.user.id;
    const { orderId } = req.params;

    const order = await Order.findOne({ 
      _id: orderId, 
      userId 
    }).populate('items.laptopId', 'product_name imageURL brand price_rm');

    if (!order) {
      return res.status(404).json({ 
        message: 'Order not found' 
      });
    }

    res.json(order);

  } catch (error) {
    console.error('Fetch order error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch order', 
      error: error.message 
    });
  }
});

// GET ORDER BY ORDER NUMBER
router.get('/number/:orderNumber', async (req, res) => {
  try {
    const userId = req.user.id;
    const { orderNumber } = req.params;

    const order = await Order.findOne({ 
      orderNumber, 
      userId 
    }).populate('items.laptopId', 'product_name imageURL brand price_rm');

    if (!order) {
      return res.status(404).json({ 
        message: 'Order not found' 
      });
    }

    res.json(order);

  } catch (error) {
    console.error('Fetch order error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch order', 
      error: error.message 
    });
  }
});

// UPDATE ORDER STATUS (User can only cancel)
router.patch('/:orderId/cancel', async (req, res) => {
  try {
    const userId = req.user.id;
    const { orderId } = req.params;

    const order = await Order.findOne({ 
      _id: orderId, 
      userId 
    }).populate('items.laptopId');

    if (!order) {
      return res.status(404).json({ 
        message: 'Order not found' 
      });
    }

    // Only allow cancellation if order is Pending or Processing
    if (!['Pending', 'Processing'].includes(order.status)) {
      return res.status(400).json({ 
        message: `Cannot cancel order with status: ${order.status}` 
      });
    }

    // Restore laptop stock
    for (const item of order.items) {
      if (item.laptopId) {
        item.laptopId.stock += item.quantity;
        await item.laptopId.save();
      }
    }

    order.status = 'Cancelled';
    order.cancelledAt = new Date();
    await order.save();

    res.json({
      message: 'Order cancelled successfully',
      order
    });

  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({ 
      message: 'Failed to cancel order', 
      error: error.message 
    });
  }
});

// VALIDATE VOUCHER CODE
router.post('/validate-voucher', async (req, res) => {
  try {
    const { code, subtotal } = req.body;

    if (!code || subtotal === undefined) {
      return res.status(400).json({ 
        message: 'Voucher code and subtotal are required' 
      });
    }

    // Add your voucher validation logic here
    const validVouchers = {
      'PICK10': { discount: 0.1, type: 'percentage', minPurchase: 0 }
    };

    const voucher = validVouchers[code.toUpperCase()];

    if (!voucher) {
      return res.status(400).json({ 
        valid: false, 
        message: 'Invalid voucher code' 
      });
    }

    if (subtotal < voucher.minPurchase) {
      return res.status(400).json({ 
        valid: false, 
        message: `Minimum purchase of RM ${voucher.minPurchase} required` 
      });
    }

    const discountAmount = voucher.type === 'percentage' 
      ? subtotal * voucher.discount 
      : voucher.discount;

    res.json({
      valid: true,
      code: code.toUpperCase(),
      discountAmount,
      message: 'Voucher applied successfully'
    });

  } catch (error) {
    console.error('Validate voucher error:', error);
    res.status(500).json({ 
      message: 'Failed to validate voucher', 
      error: error.message 
    });
  }
});

// GET ORDER STATISTICS (for user dashboard)
router.get('/stats/summary', async (req, res) => {
  try {
    const userId = req.user.id;

    const stats = await Order.aggregate([
      { $match: { userId: mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ]);

    const summary = {
      totalOrders: 0,
      totalSpent: 0,
      pending: 0,
      processing: 0,
      shipped: 0,
      delivered: 0,
      cancelled: 0
    };

    stats.forEach(stat => {
      summary.totalOrders += stat.count;
      summary.totalSpent += stat.totalAmount;
      summary[stat._id.toLowerCase()] = stat.count;
    });

    res.json(summary);

  } catch (error) {
    console.error('Order stats error:', error);
    res.status(500).json({ 
      message: 'Failed to fetch order statistics', 
      error: error.message 
    });
  }
});

module.exports = router;