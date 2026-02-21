import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroupService {
  static String _baseUrl = dotenv.get('BASE_URL', fallback: '');
  static String _apiKey = dotenv.get('API_KEY', fallback: '');

  // 🔐 Common headers
  static Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken(true);

    return {
      "Content-Type": "application/json",
      "Authorization": token ?? '',
      "X-API-KEY": _apiKey,
    };
  }

  // ==========================
  // 🚀 CREATE GROUP
  // ==========================
  static Future<String> createGroup({
    required String name,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/create-group"),
      headers: await _headers(),
      body: jsonEncode({
        "name": name.trim().toLowerCase(),
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["groupId"];
    } else {
      throw Exception(data["error"] ?? "Failed to create group");
    }
  }

  // ==========================
  // 🔑 JOIN GROUP
  // ==========================
  static Future<String> joinGroup({
    required String name,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/join-group"),
      headers: await _headers(),
      body: jsonEncode({
        "name": name.trim().toLowerCase(),
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["groupId"];
    } else {
      throw Exception(data["error"] ?? "Failed to join group");
    }
  }
}
