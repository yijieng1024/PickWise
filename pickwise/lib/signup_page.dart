import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must agree to the Terms & Conditions")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully ✅")),
      );

      // TODO: 这里可以跳转到首页或登录页
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Sign up failed")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
              Color(0xFF81C784),
              Color(0xFF4DD0E1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Image.asset('assets/images/pickwise_logo_middle_rmbg.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Your Account',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(controller: _usernameController, hintText: 'Username', icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _emailController, hintText: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildPasswordField(controller: _passwordController, hintText: 'Password', obscureText: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                      const SizedBox(height: 16),
                      _buildPasswordField(controller: _confirmPasswordController, hintText: 'Confirm Password', obscureText: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                            activeColor: const Color(0xFF4CAF50),
                          ),
                          const Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'I agree to the ', style: TextStyle(color: Color(0xFF757575), fontSize: 14)),
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(color: Color(0xFF37474F), fontSize: 14, decoration: TextDecoration.underline, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD54F),
                            foregroundColor: const Color(0xFF37474F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Color(0xFFBDBDBD))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          Expanded(child: Container(height: 1, color: Color(0xFFBDBDBD))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Google sign-in
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF37474F),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: Image.asset('assets/images/google_icon.png', fit: BoxFit.contain)),
                              const SizedBox(width: 12),
                              const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('© 2025 PickWise', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E0E0))),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF757575)),
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String hintText, required bool obscureText, required VoidCallback onToggle}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E0E0))),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF757575)),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF757575)),
          ),
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
