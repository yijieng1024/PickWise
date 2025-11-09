import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class OnlineBankingPage extends StatefulWidget {
  final String paymentId;
  final double amount;

  const OnlineBankingPage({
    super.key,
    required this.paymentId,
    required this.amount,
  });

  @override
  State<OnlineBankingPage> createState() => _OnlineBankingPageState();
}

class _OnlineBankingPageState extends State<OnlineBankingPage> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedBank;
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isProcessing = false;
  bool _showPinInput = false;

  final List<Map<String, dynamic>> _banks = [
    {'name': 'Maybank', 'icon': '🏦', 'color': Color(0xFFFFD700)},
    {'name': 'CIMB Bank', 'icon': '🏦', 'color': Color(0xFFDC143C)},
    {'name': 'Public Bank', 'icon': '🏦', 'color': Color(0xFFDC143C)},
    {'name': 'RHB Bank', 'icon': '🏦', 'color': Color(0xFF003DA5)},
    {'name': 'Hong Leong Bank', 'icon': '🏦', 'color': Color(0xFF0066CC)},
    {'name': 'AmBank', 'icon': '🏦', 'color': Color(0xFFE31837)},
    {'name': 'Bank Islam', 'icon': '🏦', 'color': Color(0xFF00A651)},
    {'name': 'OCBC Bank', 'icon': '🏦', 'color': Color(0xFFED1C24)},
    {'name': 'UOB Bank', 'icon': '🏦', 'color': Color(0xFF0F2C6F)},
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _proceedToLogin() async {
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

      // Show simulated bank authentication
      await _showBankAuthenticationDialog();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/payment/online-banking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentId': widget.paymentId,
          'bankName': _selectedBank,
          'accountNumber': _accountNumberController.text,
          'accountHolderName': _accountHolderController.text,
          'pin': _pinController.text,
        }),
      ).timeout(const Duration(seconds: 5));

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _showSuccessDialog(result['transactionId'], result['fpxTransactionId']);
      } else {
        _showErrorDialog(result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      _showErrorDialog('Payment processing failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

Future<void> _showBankAuthenticationDialog() async {
  // Use a Completer to control when the future ends
  final completer = Completer<void>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Auto-dismiss after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          // Only pop if dialog is still open
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          completer.complete();
        }
      });

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.account_balance, size: 48, color: Color(0xFF00897B)),
            const SizedBox(height: 8),
            Text('Authenticating with $_selectedBank'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait while we connect to your bank...'),
          ],
        ),
      );
    },
  ).then((_) {
    // Ensure completer finishes even if dialog is popped manually
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  // Wait for either auto-dismiss or manual close
  return completer.future;
}

  void _showSuccessDialog(String transactionId, String fpxId) {
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
            Text('Bank: $_selectedBank'),
            const SizedBox(height: 8),
            Text('Transaction ID: $transactionId'),
            const SizedBox(height: 4),
            Text('FPX Ref: $fpxId', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
        title: const Text('Online Banking'),
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
                // Select Bank
                const Text(
                  'Select Your Bank',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _banks.map((bank) {
                      return RadioListTile<String>(
                        value: bank['name'],
                        groupValue: _selectedBank,
                        onChanged: (value) => setState(() => _selectedBank = value),
                        title: Row(
                          children: [
                            Text(bank['icon'], style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Text(bank['name']),
                          ],
                        ),
                        activeColor: const Color(0xFF00897B),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Account Number
                const Text(
                  'Account Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter your account number',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account number';
                    }
                    if (value.length < 10) {
                      return 'Invalid account number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Account Holder Name
                const Text(
                  'Account Holder Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountHolderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'As per bank records',
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account holder name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Proceed Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedBank == null ? null : _proceedToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Proceed to Login',
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
                      Icon(
                        Icons.account_balance,
                        size: 64,
                        color: _banks.firstWhere((b) => b['name'] == _selectedBank)['color'],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedBank!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Account: ${_accountNumberController.text}',
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
                                      'Confirm Payment',
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

              // Security Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will be redirected to your bank\'s secure page for authentication.',
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
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