import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'welcome_page.dart';
import 'chatbot_page.dart';
import 'profile_settings_page.dart';
import 'user_preference_profile_page.dart';
import 'shopping_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ✅ Check if token exists (user already logged in)
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return token != null; // if token exists, user is logged in
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PickWise',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,

      // ✅ Use FutureBuilder to decide startup page
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            // ✅ User already logged in → go to ShoppingPage
            return const ShoppingPage(userName: '', userId: ''); // Pass actual user data as needed
          } else {
            // Not logged in → WelcomePage
            return WelcomeScreen();
          }
        },
      ),

      // ✅ Routes setup
      routes: {
        '/shopping': (context) => const ShoppingPage(userName: '', userId: ''),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/welcome': (context) => WelcomeScreen(),
        '/profile': (context) => ProfileSettingsPage(),
        '/user-preference': (context) => UserPreferenceProfilePage(),
        '/chatbot': (context) => const ChatbotPage(userName: '', userId: ''),
      },
    );
  }
}
