const mongoose = require('mongoose');

// Card Payment Schema
const cardPaymentSchema = new mongoose.Schema({
  cardNumber: {
    type: String,
    required: true,
    // Store only last 4 digits for security
    validate: {
      validator: function(v) {
        return /^\d{4}$/.test(v);
      },
      message: 'Invalid card format (last 4 digits only)'
    }
  },
  cardHolderName: {
    type: String,
    required: true
  },
  expiryMonth: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return /^(0[1-9]|1[0-2])$/.test(v);
      },
      message: 'Invalid month format (01-12)'
    }
  },
  expiryYear: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return /^\d{4}$/.test(v);
      },
      message: 'Invalid year format (YYYY)'
    }
  },
  cardType: {
    type: String,
    enum: ['Visa', 'Mastercard', 'American Express'],
    required: true
  },
  billingAddress: {
    addressLine1: String,
    city: String,
    postalCode: String,
    country: String
  }
});

// Online Banking Schema
const onlineBankingSchema = new mongoose.Schema({
  bankName: {
    type: String,
    required: true,
    enum: [
      'Maybank',
      'CIMB Bank',
      'Public Bank',
      'RHB Bank',
      'Hong Leong Bank',
      'AmBank',
      'Bank Islam',
      'OCBC Bank',
      'UOB Bank'
    ]
  },
  accountHolderName: {
    type: String,
    required: true
  },
  // For demo purposes - in production, this would be handled by bank's gateway
  accountNumberLast4: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return /^\d{4}$/.test(v);
      }
    }
  },
  transactionId: {
    type: String,
    required: true,
    unique: true
  },
  fpxTransactionId: String, // FPX reference ID
  authenticationTime: Date
});

// E-Wallet Schema
const eWalletSchema = new mongoose.Schema({
  provider: {
    type: String,
    required: true,
    enum: ['Touch n Go', 'GrabPay', 'Boost', 'ShopeePay', 'MAE by Maybank']
  },
  walletPhone: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return /^(\+?6?01)[0-9]{8,9}$/.test(v);
      },
      message: 'Invalid Malaysian phone number'
    }
  },
  walletEmail: String,
  transactionId: {
    type: String,
    required: true,
    unique: true
  },
  walletTransactionRef: String,
  authenticationTime: Date
});

// Main Payment Transaction Schema
const paymentSchema = new mongoose.Schema({
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order',
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  // Payment Details
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'MYR'
  },
  
  // Payment Method
  paymentMethod: {
    type: String,
    required: true,
    enum: ['Credit/Debit Card', 'Online Banking', 'E-Wallet']
  },
  
  // Method-specific data
  cardPayment: cardPaymentSchema,
  onlineBanking: onlineBankingSchema,
  eWallet: eWalletSchema,
  
  // Transaction Status
  status: {
    type: String,
    enum: ['Pending', 'Processing', 'Success', 'Failed', 'Refunded', 'Cancelled'],
    default: 'Pending',
    index: true
  },
  
  // Transaction Tracking
  transactionId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  paymentGatewayResponse: {
    code: String,
    message: String,
    timestamp: Date
  },
  
  // Timestamps
  initiatedAt: {
    type: Date,
    default: Date.now
  },
  completedAt: Date,
  failedAt: Date,
  refundedAt: Date,
  
  // Additional Info
  ipAddress: String,
  userAgent: String,
  failureReason: String,
  refundReason: String,
  refundAmount: Number,
  
  // Security
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationCode: String, // OTP or 3D Secure
  verificationAttempts: {
    type: Number,
    default: 0
  }
  
}, {
  timestamps: true
});

// Generate unique transaction ID
paymentSchema.pre('save', async function(next) {
  if (this.isNew && !this.transactionId) {
    const date = new Date();
    const year = date.getFullYear().toString();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const timestamp = Date.now().toString().slice(-6);
    
    let prefix = 'TXN';
    if (this.paymentMethod === 'Credit/Debit Card') prefix = 'CARD';
    else if (this.paymentMethod === 'Online Banking') prefix = 'BANK';
    else if (this.paymentMethod === 'E-Wallet') prefix = 'EWLT';
    
    this.transactionId = `${prefix}${year}${month}${day}${timestamp}`;
  }
  next();
});

// Indexes for better query performance
paymentSchema.index({ orderId: 1, status: 1 });
paymentSchema.index({ userId: 1, createdAt: -1 });
// paymentSchema.index({ transactionId: 1 });

// Method to mask sensitive data for display
paymentSchema.methods.getSafePaymentInfo = function() {
  const safeData = {
    transactionId: this.transactionId,
    amount: this.amount,
    currency: this.currency,
    paymentMethod: this.paymentMethod,
    status: this.status,
    createdAt: this.createdAt
  };
  
  if (this.cardPayment) {
    safeData.cardInfo = {
      last4: this.cardPayment.cardNumber,
      cardType: this.cardPayment.cardType,
      cardHolderName: this.cardPayment.cardHolderName
    };
  }
  
  if (this.onlineBanking) {
    safeData.bankingInfo = {
      bankName: this.onlineBanking.bankName,
      accountHolderName: this.onlineBanking.accountHolderName,
      last4: this.onlineBanking.accountNumberLast4
    };
  }
  
  if (this.eWallet) {
    safeData.walletInfo = {
      provider: this.eWallet.provider,
      phone: this.eWallet.walletPhone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
    };
  }
  
  return safeData;
};

// Saved Payment Methods Schema (for returning customers)
const savedPaymentMethodSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  methodType: {
    type: String,
    required: true,
    enum: ['Credit/Debit Card', 'Online Banking', 'E-Wallet']
  },
  
  // Card Info (tokenized)
  cardLast4: String,
  cardType: String,
  cardHolderName: String,
  cardExpiryMonth: String,
  cardExpiryYear: String,
  cardToken: String, // Payment gateway token
  
  // Banking Info
  bankName: String,
  accountHolderName: String,
  accountLast4: String,
  
  // E-Wallet Info
  walletProvider: String,
  walletPhone: String,
  walletEmail: String,
  
  isDefault: {
    type: Boolean,
    default: false
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  nickname: String, // User-given name like "Work Card", "Personal Account"
  
  lastUsedAt: Date
  
}, {
  timestamps: true
});

// Ensure only one default payment method per user
savedPaymentMethodSchema.pre('save', async function(next) {
  if (this.isDefault) {
    await this.constructor.updateMany(
      { userId: this.userId, _id: { $ne: this._id } },
      { isDefault: false }
    );
  }
  next();
});

const Payment = mongoose.model('Payment', paymentSchema);
const SavedPaymentMethod = mongoose.model('SavedPaymentMethod', savedPaymentMethodSchema);

module.exports = { Payment, SavedPaymentMethod };