import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<User?> login(String username, String password) async {
    final user = await _db.getUserByCredentials(username, password);
    if (user != null) {
      await _saveSession(user);
    }
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUsername);
    await prefs.remove(AppConstants.prefRole);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefLoggedIn) ?? false;
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.prefLoggedIn) ?? false)) return null;

    return User(
      id: prefs.getInt(AppConstants.prefUserId),
      username: prefs.getString(AppConstants.prefUsername) ?? '',
      password: '',
      role: prefs.getString(AppConstants.prefRole) ?? '',
    );
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefLoggedIn, true);
    await prefs.setInt(AppConstants.prefUserId, user.id!);
    await prefs.setString(AppConstants.prefUsername, user.username);
    await prefs.setString(AppConstants.prefRole, user.role);
  }
}
