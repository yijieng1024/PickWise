import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'questionnaire_welcome_page.dart';

class UserPreferenceProfilePage extends StatefulWidget {
  const UserPreferenceProfilePage({super.key});

  @override
  State<UserPreferenceProfilePage> createState() =>
      _UserPreferenceProfilePageState();
}

class _UserPreferenceProfilePageState extends State<UserPreferenceProfilePage> {
  Map<String, dynamic>? _preferences;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreference();
  }

  // Load user preference
  Future<void> _loadUserPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = prefs.getString("user_id") ?? "";

    if (userId.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/profile/preferences/$userId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        setState(() {
          _preferences = json.decode(res.body);
          isLoading = false;
        });
      } else {
        print("❌ Failed to load preferences: ${res.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error loading preferences: $e");
      setState(() => isLoading = false);
    }
  }

  /// 🔁 Redo questionnaire
  void _redoQuestionnaire() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuestionnaireWelcomePage()),
    );
  }

  /// 🆕 Take questionnaire (first time)
  void _takeQuestionnaire() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuestionnaireWelcomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Preference Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
          ? _buildNoPreferenceView() // 👈 Show button to take questionnaire
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Q1
                  _buildPreferenceCard(
                    "Budget Range: ",
                    _preferences!["budget"],
                  ),

                  // Q2
                  _buildPreferenceCard(
                    "Main Purpose: ",
                    _preferences!["purpose"],
                  ),

                  // Q3
                  _buildPreferenceCard(
                    "Factor Priorities: ",
                    _formatListOrString(_preferences!["priorityFactors"]),
                  ),

                  // Q4
                  _buildPreferenceCard(
                    "Screen Size: ",
                    _preferences!["screenSize"],
                  ),

                  // Q5
                  _buildPreferenceCard(
                    "Portability Preference: ",
                    _preferences!["portabilityPreference"],
                  ),

                  // Q6
                  _buildPreferenceCard(
                    "Preferred Brand: ",
                    _formatListOrString(_preferences!["preferredBrands"]),
                  ),

                  const Spacer(),

                  // 🔁 Redo questionnaire button
                  ElevatedButton.icon(
                    onPressed: _redoQuestionnaire,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Redo Questionnaire"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 🆕 When user has no preference yet
  Widget _buildNoPreferenceView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "You haven’t filled in your preferences yet.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _takeQuestionnaire,
              icon: const Icon(Icons.assignment_outlined),
              label: const Text("Take Questionnaire"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 210, 147, 0),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Format string or list
  String _formatListOrString(dynamic value) {
    if (value == null) return "Not specified";
    if (value is List) return value.join(", ");
    return value.toString();
  }

  /// ✅ Unified card style
  Widget _buildPreferenceCard(String title, dynamic value) {
    // Convert to list if applicable
    List<String>? valueList;
    if (value is List) {
      valueList = value.cast<String>();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: double.infinity,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 6),
                // ✅ If it's a list, show bullet points
                if (valueList != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: valueList.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "• ",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    (value != null && value.toString().isNotEmpty)
                        ? value.toString()
                        : "Not specified",
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
