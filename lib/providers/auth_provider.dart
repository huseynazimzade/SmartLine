import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isOtpViewPresented = false;
  bool _hasCompletedOnboarding = true;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  UserRole get selectedRole => UserRole.citizen;
  bool get isOtpViewPresented => _isOtpViewPresented;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser_v2');
    if (userJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(userJson);
        _currentUser = User.fromJson(data);
      } catch (e) {
        debugPrint('Error decoding user: $e');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
  }

  /// Instant login with citizen account
  Future<void> loginAsCitizen({String phone = '50 123 45 67', String name = 'Hörmətli Sakin'}) async {
    final user = User(
      phoneNumber: phone,
      role: UserRole.citizen,
      isAuthenticated: true,
      username: name,
    );
    _currentUser = user;
    _isOtpViewPresented = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser_v2', jsonEncode(user.toJson()));
  }

  /// Backward compatible alias for tests/components
  Future<void> loginAsRole(UserRole role) async {
    await loginAsCitizen();
  }

  void setSelectedRole(UserRole role) {
    notifyListeners();
  }

  void sendOtp(String phone) {
    _isOtpViewPresented = true;
    notifyListeners();
  }

  void cancelOtp() {
    _isOtpViewPresented = false;
    notifyListeners();
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    if (otp == '1111' || otp.length == 4) {
      final user = User(
        phoneNumber: phone.isEmpty ? '50 123 45 67' : phone,
        role: UserRole.citizen,
        isAuthenticated: true,
        username: 'Hörmətli Sakin',
      );
      _currentUser = user;
      _isOtpViewPresented = false;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser_v2', jsonEncode(user.toJson()));
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _isOtpViewPresented = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser_v2');
  }
}
