import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'password_reset_success_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _resetPassword() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  final newPassword = _newPasswordController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  if (newPassword != confirmPassword) {
    _showMessage('Passwords do not match');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': widget.email,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      _showMessage('Password reset successfully!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PasswordResetSuccessPage()),
      );
    } else {
      final data = jsonDecode(response.body);
      _showMessage(data['message'] ?? 'Failed to reset password');
    }
  } catch (e) {
    _showMessage('Error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
                          child: Form(
                            key: _formKey,
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
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // New Password Field
                                _buildPasswordField(
                                  controller: _newPasswordController,
                                  hint: 'New Password',
                                  obscure: _obscureNewPassword,
                                  onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                  validator: _validatePassword,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Confirm Password Field
                                _buildPasswordField(
                                  controller: _confirmPasswordController,
                                  hint: 'Confirm Password',
                                  obscure: _obscureConfirmPassword,
                                  onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  validator: _validateConfirmPassword,
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Reset Password Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _resetPassword,
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
                                            'Reset Password',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Colors.grey[600],
              ),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}