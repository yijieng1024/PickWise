const express = require('express');
const router = express.Router();
const { Payment, SavedPaymentMethod } = require('../models/Payment');
const Order = require('../models/Order');
const verifyToken = require('../middleware/verifyToken');
const User = require('../models/User');
const { sendPaymentOTP } = require('../utils/emailService');
const mongoose = require('mongoose');

router.use(verifyToken);

router.post('/initiate', async (req, res) => {
  // await mongoose.connection.db.collection('payments').dropIndex('eWallet.transactionId_1');
  try {
    const userId = req.user.id;
    const { orderId, paymentMethod } = req.body;

    console.log('=== Initiating Payment ===');
    console.log('User ID:', userId);
    console.log('Order ID:', orderId);
    console.log('Payment Method:', paymentMethod);

    // 1. Validate order
const order = await Order.findOne({ _id: orderId, userId });
if (!order) {
  console.log('Order not found for ID:', orderId, 'User:', userId);
  return res.status(404).json({ message: 'Order not found or access denied' });
}

    if (order.paymentStatus === 'Paid')
      return res.status(400).json({ message: 'Order already paid' });

    // 2. Generate transactionId (you already have this logic)
    const date = new Date();
    const year = date.getFullYear().toString();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const timestamp = Date.now().toString().slice(-6);

    let prefix = 'TXN';
    if (paymentMethod === 'Credit/Debit Card') prefix = 'CARD';
    else if (paymentMethod === 'Online Banking') prefix = 'BANK';
    else if (paymentMethod === 'E-Wallet') prefix = 'EWLT';

    const transactionId = `${prefix}${year}${month}${day}${timestamp}`;

    // 3. Create payment record
    const payment = new Payment({
      orderId: order._id,
      userId,
      amount: order.totalAmount,
      paymentMethod,
      transactionId,
      status: 'Pending',
      ipAddress: req.ip,
      userAgent: req.headers['user-agent']
    });

    await payment.save();

    // 4. Generate OTP
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    payment.verificationCode = verificationCode;
    await payment.save();

    // ------------------------------------------------
    // 5. SEND OTP EMAIL
    // ------------------------------------------------
    const user = await User.findById(userId).select('userName email');
    if (user && user.email) {
      const emailResult = await sendPaymentOTP(
        user.email,
        user.userName || 'Customer',
        verificationCode,
        order.orderNumber,
        order.totalAmount
      );

      if (!emailResult.success) {
        console.warn('OTP email failed (continuing anyway):', emailResult.error);
        // You can decide: fail the request or just log
        // return res.status(500).json({ message: 'Failed to send OTP email' });
      }
    } else {
      console.warn('User has no email – OTP not sent');
    }

    // ------------------------------------------------
    // 6. RESPONSE (dev only – remove verificationCode in prod)
    // ------------------------------------------------
    const response = {
      message: 'Payment initiated',
      paymentId: payment._id,
      transactionId: payment.transactionId,
      amount: payment.amount,
      verificationRequired: true
    };

    if (process.env.NODE_ENV !== 'production') {
      response.verificationCode = verificationCode; // for testing
    }

    res.json(response);
  } catch (error) {
    console.error('Payment initiation error:', error);
    res.status(500).json({ message: 'Failed to initiate payment', error: error.message });
  }
});

// PROCESS CARD PAYMENT
router.post('/card', async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      paymentId,
      cardNumber,
      cardHolderName,
      expiryMonth,
      expiryYear,
      cvv,
      billingAddress,
      saveCard
    } = req.body;

    console.log('=== Processing Card Payment ===');
    console.log('Payment ID:', paymentId);

    // Validate payment exists
    const payment = await Payment.findOne({ _id: paymentId, userId });
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Validate card number (basic Luhn algorithm check)
    const isValidCard = validateCardNumber(cardNumber);
    if (!isValidCard) {
      payment.status = 'Failed';
      payment.failureReason = 'Invalid card number';
      payment.failedAt = new Date();
      await payment.save();
      
      return res.status(400).json({ message: 'Invalid card number' });
    }

    // Validate expiry date
    const currentDate = new Date();
    const expiryDate = new Date(parseInt(expiryYear), parseInt(expiryMonth) - 1);
    if (expiryDate < currentDate) {
      payment.status = 'Failed';
      payment.failureReason = 'Card expired';
      payment.failedAt = new Date();
      await payment.save();
      
      return res.status(400).json({ message: 'Card has expired' });
    }

    // Validate CVV
    if (!/^\d{3,4}$/.test(cvv)) {
      return res.status(400).json({ message: 'Invalid CVV' });
    }

    // Determine card type
    const cardType = getCardType(cardNumber);

    // Simulate payment processing (2-3 seconds)
    payment.status = 'Processing';
    await payment.save();

    await new Promise(resolve => setTimeout(resolve, 2000));

    // Simulate success/failure (95% success rate for demo)
    const isSuccess = Math.random() > 0.05;

    if (isSuccess) {
      // Store only last 4 digits
      payment.cardPayment = {
        cardNumber: cardNumber.slice(-4),
        cardHolderName,
        expiryMonth,
        expiryYear,
        cardType,
        billingAddress
      };
      
      payment.status = 'Success';
      payment.isVerified = true;
      payment.completedAt = new Date();
      payment.paymentGatewayResponse = {
        code: '00',
        message: 'Transaction approved',
        timestamp: new Date()
      };

      // Update order
      const order = await Order.findById(payment.orderId);
      order.paymentStatus = 'Paid';
      order.paidAt = new Date();
      order.status = 'Processing';
      await order.save();

      // Save card for future use if requested
      if (saveCard) {
        await SavedPaymentMethod.create({
          userId,
          methodType: 'Credit/Debit Card',
          cardLast4: cardNumber.slice(-4),
          cardType,
          cardHolderName,
          cardExpiryMonth: expiryMonth,
          cardExpiryYear: expiryYear,
          cardToken: `tok_${Date.now()}`, // Simulated token
          lastUsedAt: new Date()
        });
      }

      await payment.save();

      console.log('✅ Card payment successful:', payment.transactionId);

      res.json({
        success: true,
        message: 'Payment successful',
        transactionId: payment.transactionId,
        paymentDetails: payment.getSafePaymentInfo()
      });

    } else {
      payment.status = 'Failed';
      payment.failureReason = 'Insufficient funds or card declined';
      payment.failedAt = new Date();
      payment.paymentGatewayResponse = {
        code: '05',
        message: 'Transaction declined',
        timestamp: new Date()
      };
      await payment.save();

      console.log('❌ Card payment failed:', payment.transactionId);

      res.status(400).json({
        success: false,
        message: 'Payment failed',
        reason: payment.failureReason
      });
    }

  } catch (error) {
    console.error('Card payment error:', error);
    res.status(500).json({ message: 'Payment processing failed', error: error.message });
  }
});

// PROCESS ONLINE BANKING PAYMENT
router.post('/online-banking', async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      paymentId,
      bankName,
      accountNumber,
      accountHolderName
    } = req.body;

    console.log('=== Processing Online Banking ===');
    console.log('Payment ID:', paymentId);
    console.log('Bank:', bankName);

    const payment = await Payment.findOne({ _id: paymentId, userId });
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Validate bank account (basic check)
    if (!accountNumber || accountNumber.length < 10) {
      return res.status(400).json({ message: 'Invalid account number' });
    }

    // Generate FPX transaction ID
    const fpxTransactionId = `FPX${Date.now()}${Math.floor(Math.random() * 1000)}`;

    console.log ('Generated FPX Transaction ID:', fpxTransactionId);

    payment.status = 'Processing';
    await payment.save();

    console.log('Payment status set to Processing for payment ID:', paymentId);

    // Simulate bank authentication (3-4 seconds)
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Simulate authentication success (90% success rate)
    const isSuccess = Math.random() > 0.1;

    if (isSuccess) {
      payment.onlineBanking = {
        bankName,
        accountHolderName,
        accountNumberLast4: accountNumber.slice(-4),
        transactionId: `BANK${Date.now()}`,
        fpxTransactionId,
        authenticationTime: new Date()
      };
      
      payment.status = 'Success';
      payment.isVerified = true;
      payment.completedAt = new Date();
      payment.paymentGatewayResponse = {
        code: '00',
        message: 'Transaction successful',
        timestamp: new Date()
      };

      // Update order
      const order = await Order.findById(payment.orderId);
      order.paymentStatus = 'Paid';
      order.paidAt = new Date();
      order.status = 'Processing';
      await order.save();

      await payment.save();

      console.log('✅ Banking payment successful:', payment.transactionId);

      res.json({
        success: true,
        message: 'Payment successful via Online Banking',
        transactionId: payment.transactionId,
        fpxTransactionId,
        paymentDetails: payment.getSafePaymentInfo()
      });

    } else {
      payment.status = 'Failed';
      payment.failureReason = 'Authentication failed or insufficient balance';
      payment.failedAt = new Date();
      payment.paymentGatewayResponse = {
        code: '51',
        message: 'Authentication failed',
        timestamp: new Date()
      };
      await payment.save();

      console.log('❌ Banking payment failed:', payment.transactionId);

      res.status(400).json({
        success: false,
        message: 'Payment failed',
        reason: payment.failureReason
      });
    }

  } catch (error) {
    console.error('Online banking payment error:', error);
    res.status(500).json({ message: 'Payment processing failed', error: error.message });
  }
});

// PROCESS E-WALLET PAYMENT
router.post('/e-wallet', async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      paymentId,
      provider,
      walletPhone,
      walletEmail,
      pin
    } = req.body;

    console.log('=== Processing E-Wallet Payment ===');
    console.log('Payment ID:', paymentId);
    console.log('Provider:', provider);

    const payment = await Payment.findOne({ _id: paymentId, userId });
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Validate phone number
    if (!/^(\+?6?01)[0-9]{8,9}$/.test(walletPhone)) {
      return res.status(400).json({ message: 'Invalid Malaysian phone number' });
    }

    // Validate PIN (6 digits for demo)
    if (!/^\d{6}$/.test(pin)) {
      return res.status(400).json({ message: 'Invalid PIN format' });
    }

    // Generate wallet transaction reference
    const walletTransactionRef = `${provider.toUpperCase().replace(/\s/g, '')}_${Date.now()}`;

    payment.status = 'Processing';
    await payment.save();

    // Simulate e-wallet processing (2 seconds)
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Simulate success (92% success rate)
    const isSuccess = Math.random() > 0.08;

    if (isSuccess) {
      payment.eWallet = {
        provider,
        walletPhone,
        walletEmail,
        transactionId: `EWLT${Date.now()}`,
        walletTransactionRef,
        authenticationTime: new Date()
      };
      
      payment.status = 'Success';
      payment.isVerified = true;
      payment.completedAt = new Date();
      payment.paymentGatewayResponse = {
        code: '00',
        message: 'Payment successful',
        timestamp: new Date()
      };

      // Update order
      const order = await Order.findById(payment.orderId);
      order.paymentStatus = 'Paid';
      order.paidAt = new Date();
      order.status = 'Processing';
      await order.save();

      // Save e-wallet for future use
      const existingWallet = await SavedPaymentMethod.findOne({
        userId,
        walletProvider: provider,
        walletPhone
      });

      if (!existingWallet) {
        await SavedPaymentMethod.create({
          userId,
          methodType: 'E-Wallet',
          walletProvider: provider,
          walletPhone,
          walletEmail,
          lastUsedAt: new Date()
        });
      } else {
        existingWallet.lastUsedAt = new Date();
        await existingWallet.save();
      }

      await payment.save();

      console.log('✅ E-Wallet payment successful:', payment.transactionId);

      res.json({
        success: true,
        message: `Payment successful via ${provider}`,
        transactionId: payment.transactionId,
        walletTransactionRef,
        paymentDetails: payment.getSafePaymentInfo()
      });

    } else {
      payment.status = 'Failed';
      payment.failureReason = 'Insufficient balance or authentication failed';
      payment.failedAt = new Date();
      payment.paymentGatewayResponse = {
        code: '51',
        message: 'Payment declined',
        timestamp: new Date()
      };
      await payment.save();

      console.log('❌ E-Wallet payment failed:', payment.transactionId);

      res.status(400).json({
        success: false,
        message: 'Payment failed',
        reason: payment.failureReason
      });
    }

  } catch (error) {
    console.error('E-wallet payment error:', error);
    res.status(500).json({ message: 'Payment processing failed', error: error.message });
  }
});

// GET PAYMENT DETAILS
router.get('/:paymentId', async (req, res) => {
  try {
    const userId = req.user.id;
    const { paymentId } = req.params;

    const payment = await Payment.findOne({ _id: paymentId, userId })
      .populate('orderId', 'orderNumber totalAmount');

    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    res.json(payment.getSafePaymentInfo());

  } catch (error) {
    console.error('Get payment error:', error);
    res.status(500).json({ message: 'Failed to fetch payment', error: error.message });
  }
});

// GET PAYMENT HISTORY
router.get('/history/all', async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 10, status } = req.query;

    const query = { userId };
    if (status) query.status = status;

    const payments = await Payment.find(query)
      .populate('orderId', 'orderNumber')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Payment.countDocuments(query);

    const safePayments = payments.map(p => p.getSafePaymentInfo());

    res.json({
      payments: safePayments,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalPayments: count
    });

  } catch (error) {
    console.error('Payment history error:', error);
    res.status(500).json({ message: 'Failed to fetch payment history', error: error.message });
  }
});

// GET SAVED PAYMENT METHODS
router.get('/methods/saved', async (req, res) => {
  try {
    const userId = req.user.id;

    const methods = await SavedPaymentMethod.find({ userId, isActive: true })
      .sort({ isDefault: -1, lastUsedAt: -1 });

    res.json(methods);

  } catch (error) {
    console.error('Get saved methods error:', error);
    res.status(500).json({ message: 'Failed to fetch saved methods', error: error.message });
  }
});

// DELETE SAVED PAYMENT METHOD
router.delete('/methods/:methodId', async (req, res) => {
  try {
    const userId = req.user.id;
    const { methodId } = req.params;

    const method = await SavedPaymentMethod.findOneAndDelete({
      _id: methodId,
      userId
    });

    if (!method) {
      return res.status(404).json({ message: 'Payment method not found' });
    }

    res.json({ message: 'Payment method removed successfully' });

  } catch (error) {
    console.error('Delete method error:', error);
    res.status(500).json({ message: 'Failed to delete payment method', error: error.message });
  }
});

// REFUND PAYMENT
router.post('/:paymentId/refund', async (req, res) => {
  try {
    const userId = req.user.id;
    const { paymentId } = req.params;
    const { reason, amount } = req.body;

    const payment = await Payment.findOne({ _id: paymentId, userId });
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    if (payment.status !== 'Success') {
      return res.status(400).json({ message: 'Can only refund successful payments' });
    }

    const refundAmount = amount || payment.amount;

    payment.status = 'Refunded';
    payment.refundReason = reason;
    payment.refundAmount = refundAmount;
    payment.refundedAt = new Date();
    await payment.save();

    // Update order
    const order = await Order.findById(payment.orderId);
    order.paymentStatus = 'Refunded';
    order.status = 'Refunded';
    await order.save();

    res.json({
      message: 'Refund processed successfully',
      refundAmount,
      transactionId: payment.transactionId
    });

  } catch (error) {
    console.error('Refund error:', error);
    res.status(500).json({ message: 'Refund failed', error: error.message });
  }
});

// HELPER FUNCTIONS

// Luhn algorithm for card validation
function validateCardNumber(cardNumber) {
  const digits = cardNumber.replace(/\D/g, '');
  if (digits.length < 13 || digits.length > 19) return false;
  
  let sum = 0;
  let isEven = false;
  
  for (let i = digits.length - 1; i >= 0; i--) {
    let digit = parseInt(digits[i]);
    
    if (isEven) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    
    sum += digit;
    isEven = !isEven;
  }
  
  return sum % 10 === 0;
}

// Determine card type from number
function getCardType(cardNumber) {
  const digits = cardNumber.replace(/\D/g, '');
  
  if (/^4/.test(digits)) return 'Visa';
  if (/^5[1-5]/.test(digits)) return 'Mastercard';
  if (/^3[47]/.test(digits)) return 'American Express';
  
  return 'Unknown';
}

module.exports = router;