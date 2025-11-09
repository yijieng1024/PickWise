import 'package:flutter/material.dart';
import 'api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_preference_profile_page.dart';

class Question {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  dynamic answer;

  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    this.answer,
  });
}

enum QuestionType { singleChoice, ranking }

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int currentQuestionIndex = 0;
  
  final List<Question> questions = [
    Question(
      id: 'Q1',
      question: 'What is your budget range for the laptop/desktop?',
      type: QuestionType.singleChoice,
      options: [
        '< RM 2000',
        'RM 2000 – RM 3000',
        'RM 3000 – RM 5000',
        '> RM 5000',
      ],
    ),
    Question(
      id: 'Q2',
      question: 'What will you mainly use the laptop/desktop for?',
      type: QuestionType.singleChoice,
      options: [
        'Office / Study (basic tasks)',
        'Programming / Development',
        'Gaming',
        'Creative Work (Design, Video Editing, 3D, etc.)',
        'General Use (Mixed / Casual)',
      ],
    ),
    Question(
      id: 'Q3',
      question: 'What is the most important factor(s) when choosing a laptop/desktop? Please drag the below card for priority ranking.',
      type: QuestionType.ranking,
      options: [
        'Price',
        'CPU Performance',
        'GPU Performance',
        'Portability (weight, size)',
        'Battery Life',
        'Brand / Reliability',
      ],
    ),
    Question(
      id: 'Q4',
      question: 'What screen size do you prefer?',
      type: QuestionType.singleChoice,
      options: [
        '13" – 14" (Compact)',
        '15" – 16" (Balanced)',
        '17" and above (Large Display)',
      ],
    ),
    Question(
      id: 'Q5',
      question: 'Do you value portability (thin & light design)?',
      type: QuestionType.singleChoice,
      options: [
        'Yes, I need a light device',
        'Neutral, doesn\'t matter',
        'No, performance is more important',
      ],
    ),
    Question(
      id: 'Q6',
      question: 'Do you have a preferred brand?',
      type: QuestionType.singleChoice,
      options: [
        'No preference',
        'Lenovo',
        'Dell',
        'HP',
        'Asus',
        'Acer',
        'MSI',
        'Apple',
      ],
    ),
  ];

  double get progress {
    return (currentQuestionIndex + 1) / questions.length;
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Questionnaire completed - handle submission
      _handleCompletion();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  Future<void> _handleCompletion() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("jwt_token") ?? "";
  final userId = prefs.getString("user_id") ?? "";

  if (userId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User not logged in")),
    );
    return;
  }

  // 🧩 Map answers from the questionnaire
  final answers = {
    "budget": questions[0].answer,
    "purpose": questions[1].answer,
    "priorityFactors": questions[2].answer,
    "screenSize": questions[3].answer,
    "portabilityPreference": questions[4].answer,
    "preferredBrands": questions[5].answer == "No preference"
        ? []
        : [questions[5].answer],
  };

  try {
    final res = await http.post(
      // url changed to match backend route
      Uri.parse("${ApiConstants.baseUrl}/api/profile/preferences/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode(answers),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      print("✅ Preferences saved successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences saved successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UserPreferenceProfilePage(),
        ),
      );
    } else {
      print("❌ Failed to save preferences: ${res.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save: ${res.body}")),
      );
    }
  } catch (e) {
    print("❌ Error saving preferences: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error saving preferences: $e")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9DD9E8), Color(0xFF7BC9B8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon and Progress
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Q&A Icon
                        SizedBox(
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                left: 60,
                                child: _buildChatBubble(
                                  'Q',
                                  const Color(0xFFFFC947),
                                  Colors.black,
                                ),
                              ),
                              Positioned(
                                right: 60,
                                child: _buildChatBubble(
                                  'A',
                                  const Color(0xFFE85D5D),
                                  Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Progress Bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6BCF7F),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Question Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQuestion.question,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Answer:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          if (currentQuestion.type == QuestionType.singleChoice)
                            _buildSingleChoiceQuestion(currentQuestion)
                          else
                            _buildRankingQuestion(currentQuestion),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: currentQuestionIndex > 0
                                ? previousQuestion
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD9D9D9),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: currentQuestion.answer != null
                                ? nextQuestion
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC947),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              currentQuestionIndex < questions.length - 1
                                  ? 'Next'
                                  : 'Finish',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Copyright
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      '© 2025 PickWise',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, Color bgColor, Color textColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          // Decorative lines
          if (text == 'Q')
            Positioned(
              right: -15,
              top: 5,
              child: CustomPaint(
                size: const Size(15, 20),
                painter: _LinePainter(),
              ),
            ),
          if (text == 'A')
            Positioned(
              left: -15,
              bottom: 5,
              child: CustomPaint(
                size: const Size(15, 20),
                painter: _LinePainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleChoiceQuestion(Question question) {
    return Column(
      children: question.options.map((option) {
        final isSelected = question.answer == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                question.answer = option;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6BCF7F) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6BCF7F) : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRankingQuestion(Question question) {
    List<String> rankedList = question.answer ?? List<String>.from(question.options);
    
    question.answer ??= rankedList;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankedList.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = rankedList.removeAt(oldIndex);
          rankedList.insert(newIndex, item);
          question.answer = rankedList;
        });
      },
      itemBuilder: (context, index) {
        return Container(
          key: ValueKey(rankedList[index]),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF6BCF7F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rankedList[index],
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.drag_handle, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width * 0.7, 0),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}