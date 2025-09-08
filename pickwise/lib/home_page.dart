import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String userName;

  HomePage({Key? key, this.userName = "Jack"}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Light mint background
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFB2DFDB), // Slightly darker mint for header
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hamburger Menu
                  IconButton(
                    onPressed: () {
                      print('Menu pressed');
                    },
                    icon: const Icon(
                      Icons.menu,
                      color: Color(0xFF37474F),
                      size: 24,
                    ),
                  ),
                  
                  // Logo and Title
                  Row(
                    children: [
                      // Logo
                      Container(
                        child: Image.asset(
                          'assets/images/pickwise_logo_middle_rmbg.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain, // Maintains aspect ratio
                        )
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // App name
                      const Text(
                        'Pickwise',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                  
                  // Profile/Settings Icon
                  IconButton(
                    onPressed: () {
                      // Logout logic
                      print('Profile pressed');
                      // Example: Navigate to login page and remove all previous routes
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      // You can also clear user session or token here if needed
                    },
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: Color(0xFF37474F),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Greeting
                    Text(
                      'Hi, ${widget.userName}!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    const Text(
                      'What can I help you?',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Text Input Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask for Recommendation',
                          hintStyle: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (value) {
                          _sendMessage();
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Send Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DD0E1),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4DD0E1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      print('Sending message: ${_messageController.text}');
      
      // Handle sending message here
      // You can add chat functionality, API calls, etc.
      
      // Clear the input field
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}