import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';
import 'address_book_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  Map<String, dynamic>? _user;
  File? _avatarFile;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = prefs.getString("user_id") ?? "";

    setState(() {
      _token = token;
    });

    if (userId.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/profile/$userId"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        setState(() => _user = json.decode(res.body));
      } else {
        print("❌ Failed to fetch profile: ${res.body}");
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _avatarFile = File(pickedFile.path));
      await _updateProfile(avatarFile: _avatarFile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Profile picture updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateProfile({
    String? username,
    String? email,
    File? avatarFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = prefs.getString("user_id") ?? "";

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("${ApiConstants.baseUrl}/api/profile/$userId"),
    );
    request.headers["Authorization"] = "Bearer $token";

    if (username != null) request.fields["username"] = username;
    if (email != null) request.fields["email"] = email;
    if (avatarFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath("avatar", avatarFile.path),
      );
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      _loadUserProfile();
      if (username != null || email != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      print("Failed to update profile");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog(String field) {
    final controller = TextEditingController(text: _user?[field] ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              field == "username" ? Icons.person : Icons.email,
              color: const Color(0xFF2596BE),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text("Edit ${field[0].toUpperCase()}${field.substring(1)}"),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new $field",
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (field == "username") {
                _updateProfile(username: controller.text.trim());
              }
              if (field == "email") {
                _updateProfile(email: controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2596BE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    String subtitle = "",
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2596BE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: const Color(0xFF2596BE)),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF263238),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF546E7A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2596BE).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFB2DFDB),
                  backgroundImage: _avatarFile != null
                      ? FileImage(_avatarFile!)
                      : (_user!["photoUrl"] != null &&
                                    _user!["photoUrl"].toString().isNotEmpty
                                ? NetworkImage(
                                    "${ApiConstants.baseUrl}${_user!["photoUrl"]}",
                                  )
                                : null)
                            as ImageProvider<Object>?,
                  child: (_user!["photoUrl"] == null ||
                          _user!["photoUrl"].toString().isEmpty)
                      ? Text(
                          (_user!["username"]?.isNotEmpty ?? false)
                              ? _user!["username"][0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2596BE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // Username
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _user!["username"] ?? "",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showEditDialog("username"),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2596BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Color(0xFF2596BE),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 16,
                color: Color(0xFF546E7A),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _user!["email"] ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF546E7A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showEditDialog("email"),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2596BE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF2596BE),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: Colors.black,
        centerTitle: true,
        elevation: 0,
      ),
      body: _user == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2596BE),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2596BE),
              onRefresh: _loadUserProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header Card
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),

                  // Quick Action Cards in 2 columns
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildOptionCard(
                        icon: Icons.shopping_bag_outlined,
                        label: "My Orders",
                        subtitle: "Track your purchases",
                        onTap: () => Navigator.pushNamed(context, "/orders"),
                      ),
                      _buildOptionCard(
                        icon: Icons.shopping_cart_outlined,
                        label: "Cart",
                        subtitle: "View shopping cart",
                        onTap: () => Navigator.pushNamed(context, "/cart"),
                      ),
                      _buildOptionCard(
                        icon: Icons.location_on_outlined,
                        label: "Address Book",
                        subtitle: "Manage addresses",
                        onTap: () {
                          if (_token == null || _token!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please log in again."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddressBookPage(token: _token!),
                            ),
                          );
                        },
                      ),
                      _buildOptionCard(
                        icon: Icons.tune,
                        label: "Preferences",
                        subtitle: "Customize experience",
                        onTap: () =>
                            Navigator.pushNamed(context, "/user-preference"),
                      ),
                      _buildOptionCard(
                        icon: Icons.lock_outline,
                        label: "Security",
                        subtitle: "Change password",
                        onTap: () =>
                            Navigator.pushNamed(context, "/change-password"),
                      ),
                      // Logout button
                      _buildOptionCard(
                        icon: Icons.logout,
                        label: "Logout",
                        subtitle: "Sign out of account",
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove("jwt_token");
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}