const nodemailer = require('nodemailer');
require('dotenv').config();

// Create reusable transporter
const createTransporter = () => {
  return nodemailer.createTransport({
    service: process.env.EMAIL_SERVICE || 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD
    }
  });
};

// Alternative: Use SMTP configuration
const createSMTPTransporter = () => {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT || 587,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD
    }
  });
};

// Send OTP Email for Payment Verification
const sendPaymentOTP = async (email, userName, otp, orderNumber, amount) => {
  try {
    const transporter = createTransporter();

    const mailOptions = {
      from: {
        name: 'PickWise',
        address: process.env.EMAIL_USER
      },
      to: email,
      subject: `Payment Verification - OTP Code`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body {
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
              background-color: #f5f5f5;
              margin: 0;
              padding: 0;
            }
            .container {
              max-width: 600px;
              margin: 40px auto;
              background-color: #ffffff;
              border-radius: 12px;
              overflow: hidden;
              box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            }
            .header {
              background: linear-gradient(135deg, #00897B 0%, #00695C 100%);
              padding: 30px;
              text-align: center;
              color: white;
            }
            .header h1 {
              margin: 0;
              font-size: 28px;
              font-weight: 600;
            }
            .content {
              padding: 40px 30px;
            }
            .greeting {
              font-size: 18px;
              color: #333;
              margin-bottom: 20px;
            }
            .message {
              font-size: 15px;
              color: #666;
              line-height: 1.6;
              margin-bottom: 30px;
            }
            .otp-box {
              background: linear-gradient(135deg, #B2DFDB 0%, #80CBC4 100%);
              border-radius: 10px;
              padding: 30px;
              text-align: center;
              margin: 30px 0;
              box-shadow: 0 2px 8px rgba(0, 137, 123, 0.2);
            }
            .otp-label {
              font-size: 14px;
              color: #00695C;
              font-weight: 600;
              margin-bottom: 10px;
              text-transform: uppercase;
              letter-spacing: 1px;
            }
            .otp-code {
              font-size: 42px;
              font-weight: bold;
              color: #00695C;
              letter-spacing: 8px;
              font-family: 'Courier New', monospace;
              margin: 10px 0;
            }
            .order-details {
              background-color: #f8f9fa;
              border-left: 4px solid #00897B;
              padding: 20px;
              margin: 25px 0;
              border-radius: 5px;
            }
            .order-details-title {
              font-size: 14px;
              font-weight: 600;
              color: #00695C;
              margin-bottom: 12px;
              text-transform: uppercase;
            }
            .order-detail-row {
              display: flex;
              justify-content: space-between;
              margin: 8px 0;
              font-size: 14px;
            }
            .order-detail-label {
              color: #666;
            }
            .order-detail-value {
              color: #333;
              font-weight: 600;
            }
            .warning {
              background-color: #fff3cd;
              border: 1px solid #ffc107;
              border-radius: 8px;
              padding: 15px;
              margin: 25px 0;
              font-size: 13px;
              color: #856404;
            }
            .warning-icon {
              font-size: 18px;
              margin-right: 8px;
            }
            .footer {
              background-color: #f8f9fa;
              padding: 25px 30px;
              text-align: center;
              font-size: 13px;
              color: #666;
              border-top: 1px solid #e0e0e0;
            }
            .footer-links {
              margin-top: 15px;
            }
            .footer-link {
              color: #00897B;
              text-decoration: none;
              margin: 0 10px;
            }
            .footer-link:hover {
              text-decoration: underline;
            }
            .expiry-notice {
              text-align: center;
              color: #e53935;
              font-size: 14px;
              font-weight: 600;
              margin-top: 15px;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔐 Payment Verification</h1>
            </div>
            
            <div class="content">
              <div class="greeting">
                Hello ${userName},
              </div>
              
              <div class="message">
                You're almost done! Please use the following One-Time Password (OTP) to complete your payment verification for your recent order.
              </div>
              
              <div class="otp-box">
                <div class="otp-label">Your OTP Code</div>
                <div class="otp-code">${otp}</div>
                <div class="expiry-notice">⏱️ Valid for 10 minutes</div>
              </div>
              
              <div class="order-details">
                <div class="order-details-title">📦 Order Information</div>
                <div class="order-detail-row">
                  <span class="order-detail-label">Order Number:</span>
                  <span class="order-detail-value">${orderNumber}</span>
                </div>
                <div class="order-detail-row">
                  <span class="order-detail-label">Amount:</span>
                  <span class="order-detail-value">RM ${amount.toFixed(2)}</span>
                </div>
              </div>
              
              <div class="warning">
                <span class="warning-icon">⚠️</span>
                <strong>Security Notice:</strong> Never share this OTP with anyone. PickWise staff will never ask for your OTP code. If you didn't request this payment, please contact our support team immediately.
              </div>
              
              <div class="message">
                If you have any questions or concerns, please don't hesitate to reach out to our customer support team.
              </div>
            </div>
            
            <div class="footer">
              <div>
                <strong>PickWise</strong> - Your Trusted Laptop Store
              </div>
              <div style="margin-top: 10px;">
                📧 support@pickwise.com | 📞 +60 12-345-6789
              </div>
              <div class="footer-links">
                <a href="#" class="footer-link">Help Center</a>
                <a href="#" class="footer-link">Contact Us</a>
                <a href="#" class="footer-link">Privacy Policy</a>
              </div>
              <div style="margin-top: 15px; font-size: 12px; color: #999;">
                © 2025 PickWise. All rights reserved.
              </div>
            </div>
          </div>
        </body>
        </html>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✅ OTP Email sent successfully:', info.messageId);
    return { success: true, messageId: info.messageId };

  } catch (error) {
    console.error('❌ Error sending OTP email:', error);
    return { success: false, error: error.message };
  }
};

// Send Order Confirmation Email
const sendOrderConfirmation = async (email, userName, orderDetails) => {
  try {
    const transporter = createTransporter();

    const itemsList = orderDetails.items.map(item => `
      <tr>
        <td style="padding: 12px; border-bottom: 1px solid #e0e0e0;">
          ${item.productName}
        </td>
        <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: center;">
          ${item.quantity}
        </td>
        <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: right;">
          RM ${item.price.toFixed(2)}
        </td>
        <td style="padding: 12px; border-bottom: 1px solid #e0e0e0; text-align: right; font-weight: 600;">
          RM ${item.subtotal.toFixed(2)}
        </td>
      </tr>
    `).join('');

    const mailOptions = {
      from: {
        name: 'PickWise',
        address: process.env.EMAIL_USER
      },
      to: email,
      subject: `Order Confirmation - ${orderDetails.orderNumber}`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }
            .container { max-width: 650px; margin: 40px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1); }
            .header { background: linear-gradient(135deg, #00897B 0%, #00695C 100%); padding: 40px 30px; text-align: center; color: white; }
            .header h1 { margin: 0 0 10px 0; font-size: 32px; }
            .success-icon { font-size: 48px; margin-bottom: 15px; }
            .content { padding: 40px 30px; }
            .order-number { background-color: #f8f9fa; border-left: 4px solid #00897B; padding: 15px 20px; margin: 20px 0; font-size: 16px; }
            .order-number strong { color: #00897B; }
            .table-container { margin: 30px 0; overflow-x: auto; }
            table { width: 100%; border-collapse: collapse; }
            th { background-color: #00897B; color: white; padding: 15px; text-align: left; font-weight: 600; }
            .summary { background-color: #f8f9fa; padding: 20px; margin: 30px 0; border-radius: 8px; }
            .summary-row { display: flex; justify-content: space-between; margin: 10px 0; font-size: 15px; }
            .total-row { font-size: 18px; font-weight: bold; color: #00897B; border-top: 2px solid #00897B; padding-top: 15px; margin-top: 15px; }
            .button { display: inline-block; background-color: #00897B; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; margin: 25px 0; font-weight: 600; }
            .footer { background-color: #f8f9fa; padding: 25px 30px; text-align: center; font-size: 13px; color: #666; border-top: 1px solid #e0e0e0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="success-icon">✅</div>
              <h1>Order Confirmed!</h1>
              <p style="margin: 0; font-size: 16px;">Thank you for your purchase</p>
            </div>
            
            <div class="content">
              <p style="font-size: 16px; color: #333;">Hello ${userName},</p>
              <p style="font-size: 15px; color: #666; line-height: 1.6;">
                Great news! Your order has been confirmed and is being processed. We'll send you another email once your items have been shipped.
              </p>
              
              <div class="order-number">
                <strong>Order Number:</strong> ${orderDetails.orderNumber}
              </div>
              
              <h2 style="color: #00695C; margin-top: 40px;">Order Details</h2>
              
              <div class="table-container">
                <table>
                  <thead>
                    <tr>
                      <th>Item</th>
                      <th style="text-align: center;">Quantity</th>
                      <th style="text-align: right;">Price</th>
                      <th style="text-align: right;">Subtotal</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${itemsList}
                  </tbody>
                </table>
              </div>
              
              <div class="summary">
                <div class="summary-row">
                  <span>Merchandise Subtotal:</span>
                  <span>RM ${orderDetails.merchandiseSubtotal.toFixed(2)}</span>
                </div>
                <div class="summary-row">
                  <span>Shipping Fee:</span>
                  <span>RM ${orderDetails.shippingFee.toFixed(2)}</span>
                </div>
                <div class="summary-row">
                  <span>SST (6%):</span>
                  <span>RM ${orderDetails.sstAmount.toFixed(2)}</span>
                </div>
                ${orderDetails.discount > 0 ? `
                  <div class="summary-row" style="color: #4caf50;">
                    <span>Discount:</span>
                    <span>- RM ${orderDetails.discount.toFixed(2)}</span>
                  </div>
                ` : ''}
                <div class="summary-row total-row">
                  <span>Total Amount:</span>
                  <span>RM ${orderDetails.totalAmount.toFixed(2)}</span>
                </div>
              </div>
              
              <div style="text-align: center;">
                <a href="#" class="button">Track Your Order</a>
              </div>
              
              <p style="font-size: 14px; color: #666; margin-top: 30px;">
                If you have any questions about your order, please contact our customer support team.
              </p>
            </div>
            
            <div class="footer">
              <div><strong>PickWise</strong> - Your Trusted Laptop Store</div>
              <div style="margin-top: 10px;">📧 support@pickwise.com | 📞 +60 12-345-6789</div>
              <div style="margin-top: 15px; font-size: 12px; color: #999;">© 2025 PickWise. All rights reserved.</div>
            </div>
          </div>
        </body>
        </html>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Order confirmation email sent:', info.messageId);
    return { success: true, messageId: info.messageId };

  } catch (error) {
    console.error('❌ Error sending confirmation email:', error);
    return { success: false, error: error.message };
  }
};

// Send Password Reset OTP
const sendPasswordResetOTP = async (email, userName, otp) => {
  try {
    const transporter = createTransporter();

    const mailOptions = {
      from: {
        name: 'PickWise',
        address: process.env.EMAIL_USER
      },
      to: email,
      subject: 'Password Reset Request - OTP Code',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1); }
            .header { background: linear-gradient(135deg, #00897B 0%, #00695C 100%); padding: 30px; text-align: center; color: white; }
            .header h1 { margin: 0; font-size: 28px; }
            .content { padding: 40px 30px; }
            .otp-box { background: linear-gradient(135deg, #B2DFDB 0%, #80CBC4 100%); border-radius: 10px; padding: 30px; text-align: center; margin: 30px 0; }
            .otp-code { font-size: 42px; font-weight: bold; color: #00695C; letter-spacing: 8px; font-family: 'Courier New', monospace; }
            .warning { background-color: #fff3cd; border: 1px solid #ffc107; border-radius: 8px; padding: 15px; margin: 25px 0; font-size: 13px; color: #856404; }
            .footer { background-color: #f8f9fa; padding: 25px 30px; text-align: center; font-size: 13px; color: #666; border-top: 1px solid #e0e0e0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>🔑 Password Reset</h1>
            </div>
            <div class="content">
              <p style="font-size: 16px;">Hello ${userName},</p>
              <p style="color: #666;">We received a request to reset your password. Use the OTP code below:</p>
              <div class="otp-box">
                <div style="color: #00695C; font-weight: 600; margin-bottom: 10px;">YOUR OTP CODE</div>
                <div class="otp-code">${otp}</div>
                <div style="color: #e53935; margin-top: 15px; font-weight: 600;">⏱️ Valid for 10 minutes</div>
              </div>
              <div class="warning">
                ⚠️ <strong>Security Notice:</strong> If you didn't request this, please ignore this email and ensure your account is secure.
              </div>
            </div>
            <div class="footer">
              <div><strong>PickWise</strong></div>
              <div style="margin-top: 10px;">© 2025 PickWise. All rights reserved.</div>
            </div>
          </div>
        </body>
        </html>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Password reset OTP sent:', info.messageId);
    return { success: true, messageId: info.messageId };

  } catch (error) {
    console.error('❌ Error sending password reset email:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendPaymentOTP,
  sendOrderConfirmation,
  sendPasswordResetOTP
};