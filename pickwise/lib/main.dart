import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'welcome_page.dart';
import 'home_page.dart';
import 'profile_settings_page.dart';
import 'user_preference_profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            // Login status is true → HomePage
            return HomePage(userName: '', userAvatar: '', userId: '');
          } else {
            // Login status is false → WelcomePage
            return WelcomeScreen();
          }
        },
      ),

      routes: {
        '/home': (context) => HomePage(userName: '', userAvatar: '', userId: ''),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/welcome': (context) => WelcomeScreen(),
        '/profile': (context) => ProfileSettingsPage(),
        '/user-preference': (context) => UserPreferenceProfilePage(),
      },
    );
  }
}
