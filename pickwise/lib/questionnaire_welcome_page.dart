import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:PickWise/questionnaire_page.dart';
import 'package:PickWise/login_page.dart';

class QuestionnaireWelcomePage extends StatefulWidget {
  const QuestionnaireWelcomePage({Key? key}) : super(key: key);

  @override
  State<QuestionnaireWelcomePage> createState() => _QuestionnaireWelcomePageState();
}

class _QuestionnaireWelcomePageState extends State<QuestionnaireWelcomePage> {
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// ✅ 检查是否已登录（JWT 存在）
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final name = prefs.getString('username');

    if (token == null) {
      // ❌ 未登录，跳回登录页
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      // ✅ 已登录，显示用户名
      setState(() {
        userName = name ?? "User";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEBF4F6),
              Color(0xFFD1E8EB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // 🎨 主图
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Image.asset(
                  'assets/images/pickwise_logo_middle_rmbg.png',
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),

              // ✨ 欢迎语
              Text(
                'Welcome, ${userName ?? 'User'} !',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Let's personalize your PickWise experience.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF34495E),
                ),
              ),
              const Spacer(),

              // 🚀 开始按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionnairePage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A9E9A),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
