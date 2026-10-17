import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  UserRole _selectedRole = UserRole.citizen;
  bool _isOtpViewPresented = false;
  bool _hasCompletedOnboarding = true; // Open directly to the 2-choice login screen as requested!
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  UserRole get selectedRole => _selectedRole;
  bool get isOtpViewPresented => _isOtpViewPresented;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Allow user to see role choices or restore session
    final savedRole = prefs.getString('selectedRole_v2');
    if (savedRole != null) {
      _selectedRole = UserRole.fromString(savedRole);
    }

    final userJson = prefs.getString('currentUser_v2');
    if (userJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(userJson);
        _currentUser = User.fromJson(data);
        _selectedRole = _currentUser!.role;
      } catch (e) {
        debugPrint('Error decoding user: $e');
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  void setSelectedRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
  }

  /// Instant 1-tap entry as either Citizen or Driver
  Future<void> loginAsRole(UserRole role) async {
    _selectedRole = role;
    final user = User(
      phoneNumber: role == UserRole.driver ? '50 999 88 77' : '50 123 45 67',
      role: role,
      isAuthenticated: true,
      username: role == UserRole.driver ? 'Eko Sürücü' : 'Hörmətli Sakin',
    );
    _currentUser = user;
    _isOtpViewPresented = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser_v2', jsonEncode(user.toJson()));
    await prefs.setString('selectedRole_v2', role.name);
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
    if (otp == '1111') {
      final user = User(
        phoneNumber: phone,
        role: _selectedRole,
        isAuthenticated: true,
        username: _selectedRole == UserRole.driver ? 'Eko Sürücü' : 'Hörmətli Sakin',
      );
      _currentUser = user;
      _isOtpViewPresented = false;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser_v2', jsonEncode(user.toJson()));
      await prefs.setString('selectedRole_v2', _selectedRole.name);
      return true;
    }
    return false;
  }

  Future<void> switchRole(UserRole newRole) async {
    _selectedRole = newRole;
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        phoneNumber: _currentUser!.phoneNumber,
        isAuthenticated: true,
        role: newRole,
        username: newRole == UserRole.driver ? 'Eko Sürücü' : 'Hörmətli Sakin',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser_v2', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('selectedRole_v2', newRole.name);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _isOtpViewPresented = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser_v2');
  }
}
