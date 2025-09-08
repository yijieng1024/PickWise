import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Light mint/teal background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Top spacing
              const SizedBox(height: 50),
              
              // Logo section
              SizedBox(
                child: Image.asset(
                  'assets/images/pickwise_logo_middle_rmbg.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain, // Maintains aspect ratio
                )
              ),
              
              // const SizedBox(height: 5),
              
              // App name
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'P',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    TextSpan(
                      text: 'ick',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: 'W',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    TextSpan(
                      text: 'ise',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Spacer to push content to center
              const Spacer(),
              
              // Welcome text
              const Text(
                'Welcome to PickWise',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
                textAlign: TextAlign.center,
              ),
              
              // const SizedBox(height: 1),
              
              // Subtitle
              const Text(
                'Your smart assistant to choosing Laptop.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5F6368),
                ),
                textAlign: TextAlign.center,
              ),
              
              // Spacer
              const Spacer(),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                onPressed: () {
                  // Navigate to Sign Up screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F), // Yellow color
                    foregroundColor: const Color(0xFF37474F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login link
              TextButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: const Text(
                  'Already have an account? Log In',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF37474F),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Copyright
              const Text(
                '© 2025 PickWise',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}