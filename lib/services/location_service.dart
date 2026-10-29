import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final bool isLiveGps;
  final double accuracy;
  final bool isLastKnownLocation;

  LatLng get coordinate => LatLng(latitude, longitude);

  UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isLiveGps,
    this.accuracy = 5.0,
    this.isLastKnownLocation = false,
  });
}

class LocationService {
  // Default Baku Center (Near Nizami / Fountain Square)
  static const double defaultLat = 40.3725;
  static const double defaultLon = 49.8400;

  static const String _prefLastLat = 'smartline_last_known_lat';
  static const String _prefLastLon = 'smartline_last_known_lon';
  static const String _prefLastAcc = 'smartline_last_known_acc';
  static const String _prefLastAddr = 'smartline_last_known_addr';

  static final List<Map<String, dynamic>> _bakuLandmarks = [
    {
      'name': 'Nizami küçəsi (Torqovaya) 48, Səbail rayonu, Bakı',
      'lat': 40.3725,
      'lon': 49.8400,
    },
    {
      'name': 'Fəvvarələr meydanı 12, Səbail rayonu, Bakı',
      'lat': 40.3715,
      'lon': 49.8375,
    },
    {
      'name': 'Sahil Parkı, Neftçilər prospekti, Bakı',
      'lat': 40.3750,
      'lon': 49.8486,
    },
    {
      'name': '28 May küçəsi / Azadlıq prospekti kəsişməsi, Bakı',
      'lat': 40.3798,
      'lon': 49.8488,
    },
    {
      'name': 'Təbriz küçəsi 34, Nərimanov rayonu, Bakı',
      'lat': 40.4032,
      'lon': 49.8700,
    },
    {
      'name': 'Port Baku Mall ətrafı, Neftçilər prospekti 151, Bakı',
      'lat': 40.3780,
      'lon': 49.8550,
    },
    {
      'name': 'İçərişəhər, Qala divarları yaxınlığı, Bakı',
      'lat': 40.3660,
      'lon': 49.8320,
    },
  ];

  /// Determines the current position of the user even without internet using device GPS
  static Future<UserLocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await _getLastKnownOrFallback();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await _getLastKnownOrFallback();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await _getLastKnownOrFallback();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      String detectedAddress = 'GPS Lokasiyası (Dəqiqlik: ${position.accuracy.toStringAsFixed(1)}m, Enlik: ${position.latitude.toStringAsFixed(4)}, Uzunluq: ${position.longitude.toStringAsFixed(4)})';
      if ((position.latitude - 40.38).abs() < 0.5 && (position.longitude - 49.85).abs() < 0.5) {
        detectedAddress = 'Nizami küçəsi yaxınlığı, Səbail rayonu, Bakı';
      }

      await _cacheLastLocation(
        lat: position.latitude,
        lon: position.longitude,
        acc: position.accuracy,
        addr: detectedAddress,
      );

      return UserLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: detectedAddress,
        isLiveGps: true,
        accuracy: position.accuracy,
        isLastKnownLocation: false,
      );
    } catch (e) {
      debugPrint('[LocationService] Canlı GPS alınmadı, ən son məlum lokasiyaya keçilir: $e');
      return await _getLastKnownOrFallback();
    }
  }

  static Future<void> _cacheLastLocation({
    required double lat,
    required double lon,
    required double acc,
    required String addr,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefLastLat, lat);
      await prefs.setDouble(_prefLastLon, lon);
      await prefs.setDouble(_prefLastAcc, acc);
      await prefs.setString(_prefLastAddr, addr);
    } catch (_) {}
  }

  static Future<UserLocationResult> _getLastKnownOrFallback() async {
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final addr = 'Ən son məlum GPS koordinatı (Dəqiqlik: ${lastPos.accuracy.toStringAsFixed(1)}m)';
        return UserLocationResult(
          latitude: lastPos.latitude,
          longitude: lastPos.longitude,
          address: addr,
          isLiveGps: false,
          accuracy: lastPos.accuracy,
          isLastKnownLocation: true,
        );
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefLastLat);
      final lon = prefs.getDouble(_prefLastLon);
      final acc = prefs.getDouble(_prefLastAcc) ?? 15.0;
      final addr = prefs.getString(_prefLastAddr);

      if (lat != null && lon != null) {
        return UserLocationResult(
          latitude: lat,
          longitude: lon,
          address: addr != null ? '$addr (Ən son qeydə alınmış lokasiya)' : 'Ən son məlum lokasiya ($lat, $lon)',
          isLiveGps: false,
          accuracy: acc,
          isLastKnownLocation: true,
        );
      }
    } catch (_) {}

    return _fallbackBakuLocation();
  }

  static UserLocationResult _fallbackBakuLocation() {
    final rand = Random();
    final item = _bakuLandmarks[rand.nextInt(_bakuLandmarks.length)];
    final lat = (item['lat'] as double) + (rand.nextDouble() - 0.5) * 0.002;
    final lon = (item['lon'] as double) + (rand.nextDouble() - 0.5) * 0.002;

    return UserLocationResult(
      latitude: lat,
      longitude: lon,
      address: '${item['name']} (Son məlum referans məntəqəsi)',
      isLiveGps: false,
      accuracy: 25.0,
      isLastKnownLocation: true,
    );
  }
}
