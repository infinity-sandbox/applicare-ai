import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<SharedPreferences> get _instance async =>
      await SharedPreferences.getInstance();

  static Future<String?> get accessToken async {
    final prefs = await _instance;
    return prefs.getString('accessToken');
  }

  static Future<String?> get email async {
    final prefs = await _instance;
    return prefs.getString('email');
  }

  static Future<bool> get isLoggedIn async {
    final prefs = await _instance;
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> setLoginData(String token, String email) async {
    final prefs = await _instance;
    await prefs.setString('accessToken', token);
    await prefs.setString('email', email);
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<void> clearLoginData() async {
    final prefs = await _instance;
    await prefs.remove('accessToken');
    await prefs.remove('email');
    await prefs.setBool('isLoggedIn', false);
  }
}
