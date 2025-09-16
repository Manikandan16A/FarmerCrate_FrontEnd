import 'package:shared_preferences/shared_preferences.dart';

class UserUtils {
  static Future<int?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('customer_id') ?? prefs.getInt('user_id');
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
  
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
  
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }
  
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }
  
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('customer_id');
    await prefs.remove('role');
    await prefs.remove('username');
    await prefs.remove('email');
  }
}
