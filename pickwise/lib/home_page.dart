import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_settings_page.dart';
import 'api_constants.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final String userId;
  final VoidCallback? onUserUpdate;

  const HomePage({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.userId,
    this.onUserUpdate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _userName;
  String? _userAvatar;
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
    _userAvatar = widget.userAvatar;
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
                  MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
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
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('App Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("jwt_token");
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE0F2F1),
      drawer: SidebarDrawer(
        userName: _userName,
        userAvatar: _userAvatar ?? '',
        userId: widget.userId,
        onShowSettings: _showSettingsMenu,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      icon: const Icon(Icons.menu, color: Color(0xFF37474F), size: 24),
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
                    // Profile pic (logout)
                    IconButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove("jwt_token");
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      icon: (_userAvatar != null && _userAvatar!.isNotEmpty)
                          ? CircleAvatar(backgroundImage: NetworkImage(_userAvatar!), radius: 20)
                          : CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color.fromARGB(255, 112, 114, 116),
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : "?",
                                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Main Content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hi, $_userName!',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                    ),
                    const SizedBox(height: 16),
                    const Text('What can I help you?', style: TextStyle(fontSize: 18, color: Color(0xFF5F6368))),
                  ],
                ),
              ),
            ),
            // Bottom Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
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
                          border: Border.all(color: Color(0xFFE0E0E0)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Ask for Recommendation',
                            hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
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
                          BoxShadow(color: const Color(0xFF4DD0E1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
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

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      print('Sending message: ${_messageController.text}');
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class SidebarDrawer extends StatelessWidget {
  final String userName;
  final String userAvatar;
  final String userId;
  final void Function(BuildContext)? onShowSettings;  // FIXED: Changed type to void Function(BuildContext)?

  const SidebarDrawer({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.userId,
    this.onShowSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFE8E4E1),
      child: SafeArea(
        child: Column(
          children: [
            // Search and New Chat
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () => print('New chat pressed'),
                      icon: const Icon(Icons.add_comment_outlined, color: Colors.black87, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // Chat Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.black87, size: 20),
                  SizedBox(width: 8),
                  Text('Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ),
            const Divider(color: Color(0xFFD0CCC7), thickness: 1),
            // Chat List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildChatItem(context, 'ASUS Vivobook Pro 15 OLED R'),
                  _buildChatItem(context, 'Compare Between Apple and A'),
                ],
              ),
            ),
            // User Profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFD0CCC7), width: 1))),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4A5568),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onShowSettings?.call(context),  // FIXED: Pass context to callback
                    icon: const Icon(Icons.settings_outlined, color: Colors.black87, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, String title) {
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
              child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Rename')]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
            ),
          ],
        ),
      ),
    );
  }
}