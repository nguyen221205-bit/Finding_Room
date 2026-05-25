import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class LocalSessionService {
  Future<void> saveCurrentUserId(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.currentUserId, userId);
  }

  Future<String?> loadCurrentUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.currentUserId);
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.currentUserId);
  }
}
