import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_settings_page.dart';
import 'api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'shopping_page.dart';

class ChatbotPage extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final String userId;
  final VoidCallback? onUserUpdate;

  const ChatbotPage({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.userId,
    this.onUserUpdate,
  });

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late String _userName;
  String? _userAvatar;
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _chatBoundaryKey = GlobalKey(); // Added for screenshot
  final List<dynamic> _messages = []; // Changed to List<dynamic> to hold message objects
  bool _conversationStarted = false;
  late ScrollController _scrollController;
  String? _conversationId; // Track current conversation ID
  String? _conversationTitle;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userAvatar = widget.userAvatar;
    _scrollController = ScrollController();
  }

void _scrollToBottom({bool force = false}) {
  if (!_scrollController.hasClients) return;

  final position = _scrollController.position;
  final maxScroll = position.maxScrollExtent;
  final currentScroll = position.pixels;

  // Define a threshold (e.g., 100 pixels from bottom)
  const double threshold = 100.0;

  final bool isNearBottom = (maxScroll - currentScroll) <= threshold;
  final bool shouldScroll = force || isNearBottom;

  if (shouldScroll) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE8E4E1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile Settings'),
              onTap: () async {
                Navigator.pop(context);
                final updatedUser = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsPage(),
                  ),
                );

                if (updatedUser != null && mounted) {
                  setState(() {
                    _userName = updatedUser['username'] ?? _userName;
                    final photoUrl = updatedUser['photoUrl'];
                    if (photoUrl != null && photoUrl.toString().isNotEmpty) {
                      _userAvatar = "${ApiConstants.baseUrl}$photoUrl";
                    } else {
                      _userAvatar = null;
                    }
                  });
                  widget.onUserUpdate?.call();
                }
              },
            ),
            /*
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('App Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),*/
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("jwt_token");
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      print("🔍 Decoded JWT: $decoded"); // debug check
      return decoded['id']; // ✅ match the backend payload key
    }

    return null;
  }

  Future<void> _saveConversationToDatabase(List <dynamic> messages) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final userId = await getUserIdFromToken();

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/conversation/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'conversationId': _conversationId, // Include conversation ID
        'messages': messages,
      }),
    );

    if (response.statusCode != 201) {
      debugPrint('Failed to save conversation: ${response.body}');
    } else {
      debugPrint('Conversation saved successfully ✅');
      final data = jsonDecode(response.body);
      setState(() {
        _conversationId = data['_id'] ?? _conversationId; // Update conversationId if new
      });
    }
  } catch (e) {
    debugPrint('Error saving conversation: $e');
  }
}

  Future<void> _sendMessage(String message) async {
  if (message.trim().isEmpty) return;

  setState(() {
    _messages.add({"sender": "user", "text": message});
    _isLoading = true;
    _conversationStarted = true;
  });

  _messageController.clear();
  _scrollToBottom();

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/conversation/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': widget.userId,
        'message': message,
        'conversationId': _conversationId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiResponse = data['reply'] ?? 'No response received.';

      setState(() {
        _messages.add({
          "sender": "assistant",
          "text": aiResponse,
          "fullText": aiResponse,
          "displayText": "",
          "isTyping": true
        });
        _isLoading = false;
      });

      await _typeMessage(_messages.last);
      await _saveConversationToDatabase(_messages);
    } else {
      setState(() => _isLoading = false);
      throw Exception('Failed to get AI response: ${response.body}');
    }
  } catch (e) {
    setState(() => _isLoading = false);
    debugPrint('Error in _sendMessage: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to send message. Please try again.')),
    );
  }

  _scrollToBottom();
}

  Future<void> _typeMessage(Map<String, dynamic> botMessage) async {
    String fullText = botMessage['fullText'];
    String displayText = '';
    int index = 0;

    while (index < fullText.length && mounted) {
      setState(() {
        displayText += fullText[index];
        botMessage['displayText'] = displayText;
        botMessage['isTyping'] = index < fullText.length - 1;
      });
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 20)); // Typing speed
      index++;
    }

    if (mounted) {
      setState(() {
        botMessage['isTyping'] = false;
      });
    }
  }

 void _startNewConversation() async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/conversation/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': widget.userId,
        'message': {
          'sender': 'system',
          'text': 'Conversation started',
        },
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() {
        _conversationId = data['_id'];
        _conversationTitle = data['title']; // Store title
        _messages.clear();
        _conversationStarted = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New conversation started')),
      );
    } else {
      print('Failed to create conversation: ${response.statusCode}');
    }
  } catch (e) {
    print('Error creating conversation: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE0F2F1), // Color.fromARGB(0, 0, 0, 0), 
      drawer: SidebarDrawer(
        userName: _userName,
        userAvatar: _userAvatar ?? '',
        userId: widget.userId,
        onShowSettings: _showSettingsMenu,
        onNewConversation: _startNewConversation, // Passed the function
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (Fixed/Floating-like in mobile sense)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2DFDB),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      icon: const Icon(
                        Icons.menu,
                        color: Color(0xFF37474F),
                        size: 24,
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/pickwise_logo_middle_rmbg.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove("jwt_token");
                            Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/login', (route) => false);
                          },
                          icon: (_userAvatar != null && _userAvatar!.isNotEmpty)
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(_userAvatar!),
                                  radius: 20,
                                )
                              : CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF707274),
                                  child: Text(
                                    _userName.isNotEmpty
                                        ? _userName[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Chat Area
            Expanded(
              child: RepaintBoundary( // Added RepaintBoundary for screenshot
                key: _chatBoundaryKey,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: _conversationStarted
                      ? ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg['sender'] == 'user';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Stack( // Added Stack for copy button positioning
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isUser
                                                ? const Color(0xFF4DD0E1)
                                                : const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(16),
                                              topRight: const Radius.circular(16),
                                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                                              bottomRight: Radius.circular(isUser ? 4 : 16),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: isUser
                                              ? Text(
                                                  msg['text'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                )
                                              : BotMessageWidget(
                                                  fullText:
                                                      msg['fullText'] ?? msg['text'] ?? '',
                                                  displayText:
                                                      msg['displayText'] ??
                                                      msg['fullText'] ??
                                                      msg['text'] ??
                                                      '',
                                                  isTyping: msg['isTyping'] ?? false,
                                                ),
                                        ),
                                        // Copy button for messages (like ChatGPT)
                                        if (!(msg['isTyping'] ?? false))
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _copyMessage(isUser ? (msg['text'] ?? '') : (msg['fullText'] ?? msg['text'] ?? '')),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.copy,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: WelcomeMessage(userName: _userName),
                        ),
                ),
              ),
            ),

            // Input Bar (Fixed at bottom, floating-like)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
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
                          onSubmitted: (_) => _sendMessage(_messageController.text)
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        onPressed: () => _sendMessage(_messageController.text),
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class WelcomeMessage extends StatelessWidget {
  final String userName;

  const WelcomeMessage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi, $userName!',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: Color(0xFF37474F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What can I help you?',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF37474F),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BotMessageWidget extends StatelessWidget {
  final String fullText;
  final String displayText;
  final bool isTyping;

  const BotMessageWidget({
    super.key,
    required this.fullText,
    required this.displayText,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: displayText,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: Color(0xFF37474F),
              fontSize: 16,
              height: 1.4,
            ),
            strong: const TextStyle(fontWeight: FontWeight.bold),
            code: const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Color(0xFFE0E0E0),
              fontSize: 14,
            ),
            blockquotePadding: const EdgeInsets.only(left: 12),
            blockquoteDecoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF4DD0E1), width: 3),
              ),
            ),
          ),
        ),
        if (isTyping)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4DD0E1),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Typing...',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SidebarDrawer extends StatelessWidget {
  final String userName;
  final String userAvatar;
  final String userId;
  final void Function(BuildContext)? onShowSettings;
  final VoidCallback? onNewConversation; // ✅ added

  const SidebarDrawer({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.userId,
    this.onShowSettings,
    this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFE8E4E1),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onNewConversation, // ✅ call passed function
                      icon: const Icon(
                        Icons.add_comment_outlined,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                builder: (context) => ShoppingPage(
                userId: userId,
                userName: userName,
                userAvatar: userAvatar,
                ),
                ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(280, 48),
                // backgroundColor: const Color(0xFFE8E4E1),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Back To Home'),
            ),
            const SizedBox(height: 10),
            // Chat Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.black87,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFD0CCC7), thickness: 1),
            // Placeholder Chat List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // TODO: Replace with dynamic chat list from DB
                  // _buildChatItem(context, 'ASUS Vivobook Pro 15 OLED'),
                  // _buildChatItem(context, 'Compare Between Apple and Acer'),
                ],
              ),
            ),
            // User Profile Bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFD0CCC7))),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4A5568),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onShowSettings?.call(context),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.black87,
                      size: 24,
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

  static Widget _buildChatItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          print('Selected chat: $title');
          Navigator.pop(context);
        },
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.black54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}