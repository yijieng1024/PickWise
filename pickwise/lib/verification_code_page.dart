import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reset_password_page.dart';

class VerificationCodePage extends StatefulWidget {
  final String email;
  const VerificationCodePage({super.key, required this.email});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto verify when all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  void _onBackspace(int index) {
    if (index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
  final code = _verificationCode;
  if (code.length != 6) {
    _showMessage('Please enter the complete 6-digit code');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:5000/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email, "code": code}),
    );

    if (response.statusCode == 200) {
      _showMessage('Code verified successfully!');
      // TODO: Navigate to your reset password page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(email: widget.email),
        ),
      );
    } else {
      final data = jsonDecode(response.body);
      _showMessage(data['message'] ?? 'Invalid code. Please try again.');
      _clearFields();
    }
  } catch (e) {
    _showMessage('Verification failed: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _clearFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _resendCode() async {
    _showMessage('Resending verification code...');
    
    // TODO: Replace with actual resend logic
    await Future.delayed(const Duration(seconds: 1));
    _showMessage('New code sent to your email');
    _clearFields();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7ED8D1), // Light teal
              Color(0xFF5FB3E8), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A90A4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.monitor_outlined,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Title
                              const Text(
                                'Verification Code',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Subtitle
                              const Text(
                                'Enter the 6-digit code sent to your email',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Code Input Fields
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) => _buildCodeField(index)),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Verify Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _verifyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDB951), // Yellow color
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : const Text(
                                          'Verify Code',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Resend Code
                              TextButton(
                                onPressed: _isLoading ? null : _resendCode,
                                child: const Text(
                                  'Didn\'t receive the code? Resend',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Copyright text
                  const Text(
                    '© 2025 PickWise',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus 
              ? const Color(0xFF4A90A4) 
              : Colors.white.withOpacity(0.3),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onChanged(value, index),
        onTap: () {
          // Clear field on tap for better UX
          _controllers[index].clear();
        },
        onSubmitted: (value) {
          if (value.isEmpty && index > 0) {
            _onBackspace(index);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}