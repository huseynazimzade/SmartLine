import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity listener and validator service
class NetworkService {
  static final NetworkService instance = NetworkService._internal();

  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Timer? _pollingTimer;
  StreamSubscription? _connectivitySub;

  bool _isConnected = true;
  bool? _mockOffline; // For unit tests and manual offline simulations

  bool get isConnected => _mockOffline != null ? !_mockOffline! : _isConnected;
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Initializes the connectivity listener and periodic checker
  void init() {
    _connectivitySub?.cancel();
    _pollingTimer?.cancel();

    // Check immediately
    checkInternetConnection();

    // Listen to device connectivity state changes
    try {
      _connectivitySub = _connectivity.onConnectivityChanged.listen((results) async {
        await checkInternetConnection();
      });
    } catch (e) {
      debugPrint('[NetworkService] Connectivity stream error (will use polling): $e');
    }

    // Periodic heartbeat every 4 seconds to guarantee detection of reconnects
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkInternetConnection();
    });
  }

  /// Manually override connectivity state for testing or demo purposes
  void setMockOffline(bool? mockOffline) {
    _mockOffline = mockOffline;
    final state = isConnected;
    _connectivityController.add(state);
    debugPrint('[NetworkService] Mock offline set to: $mockOffline (isConnected: $state)');
  }

  /// Actively checks for valid internet access
  Future<bool> checkInternetConnection() async {
    if (_mockOffline != null) {
      final state = !_mockOffline!;
      if (_isConnected != state) {
        _isConnected = state;
        _connectivityController.add(_isConnected);
      }
      return state;
    }

    bool active = false;
    try {
      // 1. Try socket / DNS lookup for real internet access
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        active = true;
      }
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 2));
        if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
          active = true;
        }
      } catch (_) {
        active = false;
      }
    }

    if (_isConnected != active) {
      _isConnected = active;
      _connectivityController.add(_isConnected);
      debugPrint('[NetworkService] İnternet vəziyyəti dəyişdi: ${_isConnected ? "QOŞULDU (ONLINE)" : "KƏSİLDİ (OFFLINE)"}');
    }

    return _isConnected;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _pollingTimer?.cancel();
    _connectivityController.close();
  }
}
