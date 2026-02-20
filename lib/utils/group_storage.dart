import 'package:shared_preferences/shared_preferences.dart';

class GroupStorage {
  static const _key = "current_group_id";

  static Future<void> save(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, groupId);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
