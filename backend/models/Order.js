const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  laptopId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Laptop',
    required: true
  },
  productName: {
    type: String,
    required: true
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
    default: 1
  },
  subtotal: {
    type: Number,
    required: true,
    min: 0
  }
});

const orderSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  orderNumber: {
    type: String,
    required: true
  },
  
  // Delivery Information
  deliveryAddress: {
    addressId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Address'
    },
    fullName: String,
    phoneNumber: String,
    addressLine1: String,
    addressLine2: String,
    city: String,
    state: String,
    postalCode: String,
    country: String,
    formattedAddress: String
  },
  
  // Order Items
  items: [orderItemSchema],
  
  // Pricing Details
  merchandiseSubtotal: {
    type: Number,
    required: true,
    min: 0
  },
  shippingFee: {
    type: Number,
    required: true,
    default: 5.00,
    min: 0
  },
  sstRate: {
    type: Number,
    default: 0.06
  },
  sstAmount: {
    type: Number,
    required: true,
    min: 0
  },
  discount: {
    type: Number,
    default: 0,
    min: 0
  },
  totalAmount: {
    type: Number,
    required: true,
    min: 0
  },
  
  // Delivery & Payment Options
  deliveryOption: {
    type: String,
    enum: ['Standard Delivery', 'Express Delivery'],
    default: 'Standard Delivery'
  },
  paymentMethod: {
    type: String,
    enum: ['Online Banking', 'Credit/Debit Card', 'E-Wallet'],
    required: true
  },
  
  // Voucher Information
  appliedVoucher: {
    code: String,
    discountAmount: Number
  },
  
  // Order Status
  status: {
    type: String,
    enum: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded'],
    default: 'Pending',
    index: true
  },
  
  // Payment Status
  paymentStatus: {
    type: String,
    enum: ['Pending', 'Paid', 'Failed', 'Refunded'],
    default: 'Pending'
  },
  
  // Additional Information
  remark: {
    type: String,
    maxlength: 500
  },
  
  // Tracking
  trackingNumber: String,
  
  // Timestamps for status changes
  paidAt: Date,
  shippedAt: Date,
  deliveredAt: Date,
  cancelledAt: Date,
  
}, {
  timestamps: true // Adds createdAt and updatedAt
});

// ——— STATIC METHOD: Generate unique order number ———
orderSchema.statics.generateOrderNumber = async function () {
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  const lastOrder = await this.findOne({
    orderNumber: new RegExp(`^ORD${year}${month}${day}`)
  }).sort({ orderNumber: -1 });

  let sequence = 1;
  if (lastOrder) {
    const lastSeq = parseInt(lastOrder.orderNumber.slice(-4), 10);
    sequence = lastSeq + 1;
  }

  return `ORD${year}${month}${day}${String(sequence).padStart(4, '0')}`;
};

// ——— PRE-SAVE HOOK: Fallback if orderNumber is missing ———
orderSchema.pre('save', async function (next) {
  if (this.isNew && !this.orderNumber) {
    this.orderNumber = await this.constructor.generateOrderNumber();
  }
  next();
});

// Indexes for better query performance
orderSchema.index({ userId: 1, createdAt: -1 });
orderSchema.index({ orderNumber: 1 });
orderSchema.index({ status: 1, createdAt: -1 });

// Virtual for total items count
orderSchema.virtual('totalItems').get(function () {
  return this.items.reduce((sum, item) => sum + item.quantity, 0);
});

// Ensure virtuals are included in JSON
orderSchema.set('toJSON', { virtuals: true });
orderSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Order', orderSchema);