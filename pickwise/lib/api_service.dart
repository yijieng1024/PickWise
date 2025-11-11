import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';

class ApiService {
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<List<dynamic>> fetchConversationList(String userId) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/conversation/list')
        .replace(queryParameters: {'userId': userId});
    final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('Failed to load conversations');
  }

  static Future<Map<String, dynamic>> fetchConversation(String convId) async {
    final token = await _token();
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/conversation/$convId');
    final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to load conversation');
  }
}