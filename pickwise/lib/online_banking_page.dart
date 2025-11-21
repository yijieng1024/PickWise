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
  bool _isLoadingToken = true; // To show loading until token is fetched
  String? _token;

  final List<Map<String, dynamic>> _banks = [
    {'name': 'Maybank', 'color': const Color(0xFFFFD700)},
    {'name': 'CIMB Bank', 'color': const Color(0xFFDC143C)},
    {'name': 'Public Bank', 'color': const Color(0xFFDC143C)},
    {'name': 'RHB Bank', 'color': const Color(0xFF003DA5)},
    {'name': 'Hong Leong Bank', 'color': const Color(0xFF0066CC)},
    {'name': 'AmBank', 'color': const Color(0xFFE31837)},
    {'name': 'Bank Islam', 'color': const Color(0xFF00A651)},
    {'name': 'OCBC Bank', 'color': const Color(0xFFED1C24)},
    {'name': 'UOB Bank', 'color': const Color(0xFF0F2C6F)},
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token'); // Change key if you used 'auth_token'

    if (token == null || token.isEmpty) {
      _showErrorAndRedirect('Session expired. Please login again.');
      return;
    }

    setState(() {
      _token = token;
      _isLoadingToken = false;
    });
  }

  void _showErrorAndRedirect(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );

    // Redirect to login after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

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

    if (_token == null) {
      _showErrorAndRedirect('Authentication failed. Please login again.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate bank authentication
      await _showBankAuthenticationDialog();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/payment/online-banking'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentId': widget.paymentId,
          'bankName': _selectedBank,
          'accountNumber': _accountNumberController.text.trim(),
          'accountHolderName': _accountHolderController.text.trim(),
          'pin': _pinController.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _showSuccessDialog(
          result['transactionId'] ?? 'N/A',
          result['fpxTransactionId'] ?? 'N/A',
        );
      } else {
        _showErrorDialog(result['message'] ?? 'Payment failed. Please try again.');
      }
    } on TimeoutException {
      _showErrorDialog('Connection timeout. Please check your internet and try again.');
    } catch (e) {
      if (e.toString().contains('401')) {
        _handleUnauthorized();
      } else {
        _showErrorDialog('Payment failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    _showErrorAndRedirect('Session expired. Logging you out...');
  }

  Future<void> _showBankAuthenticationDialog() async {
    final completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          if (!completer.isCompleted) completer.complete();
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            children: [
              const Icon(Icons.account_balance, size: 48, color: Color(0xFF00897B)),
              const SizedBox(height: 8),
              Text('Connecting to $_selectedBank'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00897B)),
              SizedBox(height: 16),
              Text('Securely authenticating...'),
            ],
          ),
        );
      },
    ).then((_) => completer.complete());

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
            const Text('Payment Successful!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank: $_selectedBank'),
            const SizedBox(height: 8),
            Text('Transaction ID: $transactionId'),
            Text('FPx Ref: $fpxId', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Amount: RM ${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return success to previous screen
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
              Navigator.pop(context);
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
    if (_isLoadingToken) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00897B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Online Banking'),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00695C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Total Payable', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      'RM ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!_showPinInput) ...[
                const Text('Select Bank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: _banks.map((bank) => RadioListTile<String>(
                      value: bank['name'],
                      groupValue: _selectedBank,
                      activeColor: const Color(0xFF00897B),
                      onChanged: (val) => setState(() => _selectedBank = val),
                      title: Row(children: [const SizedBox(width: 12), Text(bank['name'])]),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Account Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(16)],
                  decoration: InputDecoration(
                    hintText: 'e.g. 123456789012',
                    prefixIcon: const Icon(Icons.credit_card),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v!.isEmpty || v.length < 10 ? 'Enter valid account number' : null,
                ),

                const SizedBox(height: 20),
                const Text('Account Holder Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accountHolderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'As shown in bank statement',
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedBank == null ? null : _proceedToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Proceed to Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                // PIN Screen
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance, size: 64, color: _banks.firstWhere((b) => b['name'] == _selectedBank)['color']),
                      const SizedBox(height: 16),
                      Text(_selectedBank!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('•••• ${_accountNumberController.text.substring(_accountNumberController.text.length - 4)}', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 32),
                      const Text('Enter 6-Digit PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF0F0F0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(onPressed: () => setState(() => _showPinInput = false), child: const Text('Back', style: TextStyle(color: Colors.black)))),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _processPayment,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), padding: const EdgeInsets.symmetric(vertical: 18)),
                              child: _isProcessing
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(child: Text('Your transaction is secured and encrypted.', style: TextStyle(color: Colors.blue, fontSize: 13))),
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