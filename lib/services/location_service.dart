import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final bool isLiveGps;

  LatLng get coordinate => LatLng(latitude, longitude);

  UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isLiveGps,
  });
}

class LocationService {
  // Default Baku Center (Near Nizami / Fountain Square)
  static const double defaultLat = 40.3725;
  static const double defaultLon = 40.3725;

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

  /// Determines the current position of the user
  static Future<UserLocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackBakuLocation();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackBakuLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackBakuLocation();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      // Check if location is inside or near Baku (lat ~39-41, lon ~48-51)
      String detectedAddress = 'Cari GPS Lokasiyası (Enlik: ${position.latitude.toStringAsFixed(4)}, Uzunluq: ${position.longitude.toStringAsFixed(4)})';
      if ((position.latitude - 40.38).abs() < 0.5 && (position.longitude - 49.85).abs() < 0.5) {
        detectedAddress = 'Nizami küçəsi yaxınlığı, Səbail rayonu, Bakı';
      }

      return UserLocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: detectedAddress,
        isLiveGps: true,
      );
    } catch (e) {
      debugPrint('Geolocator error or simulation: $e');
      return _fallbackBakuLocation();
    }
  }

  static UserLocationResult _fallbackBakuLocation() {
    // Pick an authentic Baku landmark with slight jitter
    final rand = Random();
    final item = _bakuLandmarks[rand.nextInt(_bakuLandmarks.length)];
    final lat = (item['lat'] as double) + (rand.nextDouble() - 0.5) * 0.002;
    final lon = (item['lon'] as double) + (rand.nextDouble() - 0.5) * 0.002;

    return UserLocationResult(
      latitude: lat,
      longitude: lon,
      address: item['name'] as String,
      isLiveGps: false,
    );
  }
}
