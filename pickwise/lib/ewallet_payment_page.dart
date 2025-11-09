import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class EWalletPaymentPage extends StatefulWidget {
  final String paymentId;
  final double amount;

  const EWalletPaymentPage({
    super.key,
    required this.paymentId,
    required this.amount,
  });

  @override
  State<EWalletPaymentPage> createState() => _EWalletPaymentPageState();
}

class _EWalletPaymentPageState extends State<EWalletPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedWallet;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isProcessing = false;
  bool _showPinInput = false;

  final List<Map<String, dynamic>> _wallets = [
    {
      'name': 'Touch n Go',
      'icon': '💳',
      'color': Color(0xFF0066CC),
      'description': 'TNG eWallet'
    },
    {
      'name': 'GrabPay',
      'icon': '🟢',
      'color': Color(0xFF00B14F),
      'description': 'Pay with Grab'
    },
    {
      'name': 'Boost',
      'icon': '🚀',
      'color': Color(0xFFFF4B3E),
      'description': 'Boost eWallet'
    },
    {
      'name': 'ShopeePay',
      'icon': '🛍️',
      'color': Color(0xFFEE4D2D),
      'description': 'Shopee Wallet'
    },
    {
      'name': 'MAE by Maybank',
      'icon': '💛',
      'color': Color(0xFFFFD700),
      'description': 'Maybank eWallet'
    },
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _proceedToAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _showPinInput = true);
  }

  Future<void> _processPayment() async {
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit PIN')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      // Show authentication dialog
      await _showAuthenticationDialog();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/payment/e-wallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentId': widget.paymentId,
          'provider': _selectedWallet,
          'walletPhone': _phoneController.text,
          'walletEmail': _emailController.text,
          'pin': _pinController.text,
        }),
      ).timeout(const Duration(seconds: 30));

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _showSuccessDialog(
          result['transactionId'],
          result['walletTransactionRef'],
        );
      } else {
        _showErrorDialog(result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      _showErrorDialog('Payment processing failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showAuthenticationDialog() async {
    final wallet = _wallets.firstWhere((w) => w['name'] == _selectedWallet);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text(wallet['icon'], style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('Authenticating with ${wallet['name']}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Verifying your payment...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();
  }

  void _showSuccessDialog(String transactionId, String walletRef) {
    final wallet = _wallets.firstWhere((w) => w['name'] == _selectedWallet);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(wallet['icon'], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(wallet['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Transaction ID: $transactionId'),
            const SizedBox(height: 4),
            Text(
              'Ref: $walletRef',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('Amount: RM ${widget.amount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showPinInput = false;
                _pinController.clear();
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('E-Wallet Payment'),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00897B).withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!_showPinInput) ...[
                // Select E-Wallet
                const Text(
                  'Select Your E-Wallet',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...(_wallets.map((wallet) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWallet = wallet['name']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedWallet == wallet['name']
                              ? wallet['color']
                              : Colors.grey.shade300,
                          width: _selectedWallet == wallet['name'] ? 2 : 1,
                        ),
                        boxShadow: _selectedWallet == wallet['name']
                            ? [
                                BoxShadow(
                                  color: wallet['color'].withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            wallet['icon'],
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wallet['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  wallet['description'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedWallet == wallet['name'])
                            Icon(
                              Icons.check_circle,
                              color: wallet['color'],
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList()),

                const SizedBox(height: 24),

                // Phone Number
                const Text(
                  'Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: InputDecoration(
                    hintText: '0123456789',
                    prefixText: '+60 ',
                    prefixIcon: const Icon(Icons.phone_android),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(value)) {
                      return 'Invalid Malaysian phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email (Optional)
                const Text(
                  'Email Address (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'your.email@example.com',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Proceed Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedWallet == null ? null : _proceedToAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue to Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                // PIN Input Screen
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _wallets.firstWhere((w) => w['name'] == _selectedWallet)['icon'],
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedWallet!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+60 ${_phoneController.text}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Enter Your 6-Digit PIN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 16,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showPinInput = false;
                                  _pinController.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00897B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Pay Now',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Make sure you have sufficient balance in your e-wallet.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}