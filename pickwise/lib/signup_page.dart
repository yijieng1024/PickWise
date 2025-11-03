import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'login_page.dart';
import 'chatbot_page.dart';
import 'api_constants.dart';

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

  // ✅ Validation getters
  bool get _isUsernameValid => _usernameController.text.trim().isNotEmpty;
  bool get _isEmailValid => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text.trim());
  bool get _isPasswordValid => _passwordController.text.length >= 6;
  bool get _isPasswordMatch => _passwordController.text == _confirmPasswordController.text;
  bool get _allValid => _isUsernameValid && _isEmailValid && _isPasswordValid && _isPasswordMatch && _agreeToTerms;

  Future<void> _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // 注册成功 → 自动登录
        final loginResponse = await http.post(
          Uri.parse("${ApiConstants.baseUrl}/api/auth/login"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": email, "password": password}),
        );

        if (loginResponse.statusCode == 200) {
          final loginData = jsonDecode(loginResponse.body);
          final token = loginData['token'];
          final userName = loginData['user']['username'];

          // 保存 token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          // 跳转 HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChatbotPage(userName: userName, userAvatar: loginData['user']['avatar'] ?? '', userId: loginData['user']['id'])),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login after signup failed: ${loginResponse.body}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Signup failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      final credential = {
        "uid": googleUser.id,
        "email": googleUser.email,
        "username": googleUser.displayName ?? googleUser.email.split('@')[0],
        "photoUrl": googleUser.photoUrl,
      };

      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(credential),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userName = data['user']['username'];

        // 保存 token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        // 跳转 HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatbotPage(userName: userName, userAvatar: data['user']['avatar'] ?? '', userId: data['user']['id'])),
        );
      } else {
        print("Google login failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google login failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }

  Widget _buildChecklistItem(String text, bool isChecked) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_circle : Icons.cancel,
          color: isChecked ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isChecked ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (_) => setState(() {}),
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
            colors: [Color(0xFF68C799), Color(0xFF4DD0E1)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glassmorphism container
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset('assets/images/pickwise_logo_middle_rmbg.png', fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 24),
                          const Text('Create Your Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
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
                              ),
                              const Expanded(
                                child: Text('I agree to the Terms & Conditions', style: TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildChecklistItem("Username entered", _isUsernameValid),
                              _buildChecklistItem("Valid email", _isEmailValid),
                              _buildChecklistItem("Password ≥ 6 characters", _isPasswordValid),
                              _buildChecklistItem("Passwords match", _isPasswordMatch),
                              _buildChecklistItem("Agreed to Terms", _agreeToTerms),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (!_isLoading && _allValid) ? _signUp : null,
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Sign Up'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _signInWithGoogle,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: Image.asset('assets/images/google_icon.png')),
                                  const SizedBox(width: 12),
                                  const Text('Continue with Google'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
