import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  Map<String, dynamic>? _user; // user profile data
  File? _avatarFile;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user profile from backend
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = prefs.getString("user_id") ?? "";

    if (userId.isEmpty) return;

    try {
      final res = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/profile/$userId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        setState(() {
          _user = json.decode(res.body);
        });
      } else {
        print("❌ Failed to fetch profile: ${res.body}");
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }
  }

  /// Pick image & upload avatar
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });

      await _updateProfile(avatarFile: _avatarFile);
    }
  }

  /// Update username, email or avatar
  Future<void> _updateProfile({String? username, String? email, File? avatarFile}) async {
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
      request.files.add(await http.MultipartFile.fromPath("avatar", avatarFile.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      print("Profile updated");
      _loadUserProfile(); // refresh profile data
    } else {
      print("Failed to update profile");
    }
  }

  /// Show dialog for editing username or email
  void _showEditDialog(String field) {
    final controller = TextEditingController(text: _user?[field] ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${field[0].toUpperCase()}${field.substring(1)}"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $field"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (field == "username") {
                _updateProfile(username: controller.text.trim());
              } else if (field == "email") {
                _updateProfile(email: controller.text.trim());
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didpop, Object? result) {
        if (didpop) return;
        Navigator.pop(context, _user);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: _user == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),

            // Avatar with edit button
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : (_user!["photoUrl"] != null && _user!["photoUrl"].toString().isNotEmpty
                                  ? NetworkImage("${ApiConstants.baseUrl}${_user!["photoUrl"]}")
                                  : null)
                              as ImageProvider<Object>?,
                    child:
                        (_user!["photoUrl"] == null ||
                            _user!["photoUrl"].toString().isEmpty)
                        ? Text(
                            (_user!["username"]?.isNotEmpty ?? false)
                                ? _user!["username"][0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Username
            ListTile(
              leading: const Icon(Icons.person),
              title: Text("Username"),
              subtitle: Text(_user!["username"] ?? ""),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditDialog("username"),
              ),
            ),

            // Email
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Email"),
              subtitle: Text(_user!["email"] ?? ""),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditDialog("email"),
              ),
            ),

            const Divider(),

            // Change Password
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Change Password"),
              onTap: () => Navigator.pushNamed(context, "/change-password"),
            ),

            // Dark Mode
            /*
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text("Dark Mode"),
              value: isDarkMode,
              onChanged: (value) {
                setState(() => isDarkMode = value);
                // TODO: save to prefs/db
              },
            ),
            */
            const Divider(),

            // User Preference Profile
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text("User Preference Profile"),
              subtitle: const Text("Make recommendations more accurate"),
              onTap: () => Navigator.pushNamed(context, "/user-preference"),
            ),
          ],
        ),
      ),
    );
  }
}
