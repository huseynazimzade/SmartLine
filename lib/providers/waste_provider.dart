import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';

class WasteProvider extends ChangeNotifier {
  List<BinCluster> _clusters = [];
  List<CollectionTruck> _trucks = [];
  List<LatLng> _depots = [];
  CollectionTruck? _assignedTruck;
  String? _lastNotification;
  bool _showNotification = false;

  Timer? _simulationTimer;
  final Random _random = Random();
  final double _movementSpeed = 0.00035;

  List<BinCluster> get clusters => _clusters;
  List<CollectionTruck> get trucks => _trucks;
  List<LatLng> get depots => _depots;
  CollectionTruck? get assignedTruck => _assignedTruck;
  String? get lastNotification => _lastNotification;
  bool get showNotification => _showNotification;

  WasteProvider() {
    _setupInitialData();
    _startSimulation();
  }

  void _setupInitialData() {
    final locations = [
      {'name': 'Sahil Park', 'address': 'Neftchilar Ave, Baku', 'lat': 40.3750, 'lon': 49.8486},
      {'name': 'Old City', 'address': 'Icherisheher, Baku', 'lat': 40.3660, 'lon': 49.8320},
      {'name': 'Nizami Street', 'address': 'Torgovaya, Baku', 'lat': 40.3725, 'lon': 49.8400},
      {'name': 'Port Baku Mall', 'address': 'Neftchilar Ave 151', 'lat': 40.3780, 'lon': 49.8550},
      {'name': '28 May Station', 'address': 'Azadliq Ave', 'lat': 40.3798, 'lon': 49.8488},
      {'name': 'Ganjlik Mall', 'address': 'Fatali Khan Khoyski', 'lat': 40.4001, 'lon': 49.8515},
      {'name': 'Narimanov Park', 'address': 'Tabriz St, Baku', 'lat': 40.4032, 'lon': 49.8700},
      {'name': 'White City North', 'address': 'Baku White City', 'lat': 40.3880, 'lon': 49.8850},
      {'name': 'Flame Towers', 'address': 'Mehdi Huseyn St', 'lat': 40.3620, 'lon': 49.8265},
      {'name': 'Boulevard North', 'address': 'Seafront Park Inland', 'lat': 40.3650, 'lon': 49.8380},
      {'name': 'Heydar Aliyev Center', 'address': 'Heydar Aliyev Ave', 'lat': 40.3953, 'lon': 49.8678},
      {'name': 'Fountain Square', 'address': 'City Center', 'lat': 40.3715, 'lon': 49.8375},
      {'name': 'Azerbaijan Ave', 'address': 'Near Central Mall', 'lat': 40.3755, 'lon': 49.8350},
      {'name': 'Heydar Palace', 'address': 'Bulbul Ave', 'lat': 40.3785, 'lon': 49.8440},
      {'name': 'Puppet Theatre', 'address': 'Inland Blvd', 'lat': 40.3685, 'lon': 49.8410},
      {'name': 'Mini-Venice West', 'address': 'Baku Boulevard Inland', 'lat': 40.3630, 'lon': 49.8320},
      {'name': 'Baku Eye North', 'address': 'New Boulevard Inland', 'lat': 40.3585, 'lon': 49.8280},
      {'name': 'Bayil Hill', 'address': 'Bayil District', 'lat': 40.3450, 'lon': 49.8220},
      {'name': 'Highland Park', 'address': 'Panoramic View', 'lat': 40.3585, 'lon': 49.8260},
      {'name': 'Martyrs\' Lane', 'address': 'Mehdi Huseyn St', 'lat': 40.3570, 'lon': 49.8240},
      {'name': 'Philharmonic Hall', 'address': 'Istiglaliyyat St', 'lat': 40.3645, 'lon': 49.8300},
      {'name': 'White City South', 'address': 'Inland District', 'lat': 40.3820, 'lon': 49.8800},
      {'name': 'Winter Park', 'address': 'Fuzuli St', 'lat': 40.3760, 'lon': 49.8400},
      {'name': 'Torgovaya East', 'address': 'Nizami St 100', 'lat': 40.3740, 'lon': 49.8465},
    ];

    _clusters = locations.map((loc) {
      final List<WasteBin> bins = [];
      final mixedCount = 6 + _random.nextInt(5);
      final plasticCount = 2 + _random.nextInt(3);
      final clothesCount = 1 + _random.nextInt(2);

      for (int i = 0; i < mixedCount; i++) {
        bins.add(_createBin(BinType.mixed));
      }
      for (int i = 0; i < plasticCount; i++) {
        bins.add(_createBin(BinType.plastic));
      }
      for (int i = 0; i < clothesCount; i++) {
        bins.add(_createBin(BinType.clothes));
      }

      return BinCluster(
        name: loc['name'] as String,
        address: loc['address'] as String,
        latitude: (loc['lat'] as num).toDouble(),
        longitude: (loc['lon'] as num).toDouble(),
        bins: bins,
      );
    }).toList();

    _depots = [
      const LatLng(40.400, 49.880),
      const LatLng(40.365, 49.820),
      const LatLng(40.385, 49.845),
      const LatLng(40.350, 49.815),
    ];

    _trucks = List.generate(8, (i) {
      final depot = _depots[_random.nextInt(_depots.length)];
      return CollectionTruck(
        latitude: depot.latitude,
        longitude: depot.longitude,
        status: 'At Station',
        capacity: _random.nextDouble() * 0.3,
      );
    });

    _assignedTruck = _trucks.first;
  }

  WasteBin _createBin(BinType type) {
    return WasteBin(
      type: type,
      fillLevel: 0.1 + _random.nextDouble() * 0.7,
      temperature: 20 + _random.nextDouble() * 15,
      humidity: 30 + _random.nextDouble() * 30,
      airQuality: 10 + _random.nextDouble() * 40,
      lastEmptied: DateTime.now().subtract(
        Duration(seconds: 3600 + _random.nextInt(82800)),
      ),
    );
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _simulateChanges();
    });
  }

  void _simulateChanges() {
    _updateBins();
    _updateTrucks();
    notifyListeners();
  }

  void _updateBins() {
    for (var cluster in _clusters) {
      for (var bin in cluster.bins) {
        bin.fillLevel = min(1.0, bin.fillLevel + 0.0003 + _random.nextDouble() * 0.0004);
      }
    }
  }

  void _updateTrucks() {
    for (int i = 0; i < _trucks.length; i++) {
      final truck = _trucks[i];

      if (truck.capacity >= 0.95) {
        final target = _findNearestDepot(truck.coordinate);
        truck.status = 'Returning to Station';
        truck.targetClusterId = null;
        _navigateTruck(truck, target);

        if (_getDistance(truck.coordinate, target) < 0.0003) {
          truck.capacity = 0.0;
          truck.status = 'At Station';
          truck.routePoints = [];
          truck.currentPointIndex = 0;
        }
      } else if (truck.targetClusterId != null) {
        final clusterIdx = _clusters.indexWhere((c) => c.id == truck.targetClusterId);
        if (clusterIdx != -1) {
          final cluster = _clusters[clusterIdx];
          truck.status = 'En Route: ${cluster.name}';
          _navigateTruck(truck, cluster.coordinate);

          if (_getDistance(truck.coordinate, cluster.coordinate) < 0.0003) {
            _collectFromCluster(cluster.id, truck);
            truck.routePoints = [];
            truck.currentPointIndex = 0;
          }
        } else {
          truck.targetClusterId = null;
        }
      } else {
        _findNewTarget(truck);
      }

      if (_assignedTruck != null && truck.id == _assignedTruck!.id) {
        _assignedTruck = truck;
      }
    }
  }

  void _navigateTruck(CollectionTruck truck, LatLng target) {
    if (truck.lastRequestedTarget == null ||
        truck.lastRequestedTarget!.latitude != target.latitude ||
        truck.lastRequestedTarget!.longitude != target.longitude) {
      truck.lastRequestedTarget = target;
      truck.routePoints = _generateWaypoints(truck.coordinate, target);
      truck.currentPointIndex = 0;
    }

    if (truck.routePoints.isNotEmpty && truck.currentPointIndex < truck.routePoints.length) {
      final nextPoint = truck.routePoints[truck.currentPointIndex];
      _moveTowards(truck, nextPoint);

      if (_getDistance(truck.coordinate, nextPoint) < 0.0003) {
        truck.currentPointIndex++;
      }
    } else {
      _moveTowards(truck, target);
    }
  }

  List<LatLng> _generateWaypoints(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    const steps = 6;
    final latStep = (end.latitude - start.latitude) / steps;
    final lonStep = (end.longitude - start.longitude) / steps;

    for (int i = 1; i < steps; i++) {
      final jitter = (i % 2 == 0 ? 1 : -1) * 0.0006;
      points.add(
        LatLng(
          start.latitude + (latStep * i) + jitter,
          start.longitude + (lonStep * i) - jitter,
        ),
      );
    }
    points.add(end);
    return points;
  }

  void _findNewTarget(CollectionTruck truck) {
    final now = DateTime.now();
    const cooldownSeconds = 180;

    final validClusters = _clusters.where((cluster) {
      final notTargeted = !_trucks.any(
        (t) => t.targetClusterId == cluster.id && t.id != truck.id,
      );
      final isOrangeOrRed = cluster.avgFillLevel > 0.55;
      DateTime mostRecentEmptied = DateTime.fromMillisecondsSinceEpoch(0);
      for (var b in cluster.bins) {
        if (b.lastEmptied.isAfter(mostRecentEmptied)) {
          mostRecentEmptied = b.lastEmptied;
        }
      }
      final cooldownOk = now.difference(mostRecentEmptied).inSeconds > cooldownSeconds;
      return notTargeted && isOrangeOrRed && cooldownOk;
    }).toList();

    if (validClusters.isNotEmpty) {
      validClusters.sort((a, b) => b.avgFillLevel.compareTo(a.avgFillLevel));
      truck.targetClusterId = validClusters.first.id;
    } else {
      final nearestDepot = _findNearestDepot(truck.coordinate);
      if (_getDistance(truck.coordinate, nearestDepot) > 0.0003) {
        truck.status = 'Heading to Station';
        _navigateTruck(truck, nearestDepot);
      } else {
        truck.status = 'At Station';
      }
    }
  }

  void _moveTowards(CollectionTruck truck, LatLng target) {
    final latDiff = target.latitude - truck.latitude;
    final lonDiff = target.longitude - truck.longitude;
    final dist = _getDistance(truck.coordinate, target);

    if (dist > 0.00001) {
      final ratio = _movementSpeed / dist;
      truck.latitude += latDiff * min(1.0, ratio);
      truck.longitude += lonDiff * min(1.0, ratio);
    } else {
      truck.latitude = target.latitude;
      truck.longitude = target.longitude;
    }
  }

  LatLng _findNearestDepot(LatLng coord) {
    LatLng nearest = _depots.first;
    double minDistance = double.infinity;
    for (var d in _depots) {
      final dist = _getDistance(coord, d);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = d;
      }
    }
    return nearest;
  }

  void _collectFromCluster(String clusterId, CollectionTruck truck) {
    final idx = _clusters.indexWhere((c) => c.id == clusterId);
    if (idx != -1) {
      final cluster = _clusters[idx];
      truck.status = 'Collecting...';
      truck.capacity = min(1.0, truck.capacity + cluster.avgFillLevel * 0.25);
      for (var bin in cluster.bins) {
        bin.fillLevel = 0.0;
        bin.lastEmptied = DateTime.now();
      }
      truck.targetClusterId = null;
      triggerNotification('${cluster.name} waste collected successfully.');
    }
  }

  void triggerNotification(String message) {
    _lastNotification = message;
    _showNotification = true;
    notifyListeners();

    Timer(const Duration(seconds: 4), () {
      if (_lastNotification == message) {
        _showNotification = false;
        notifyListeners();
      }
    });
  }

  void dismissNotification() {
    _showNotification = false;
    notifyListeners();
  }

  void completeCurrentTask() {
    if (_assignedTruck == null) return;
    final targetId = _assignedTruck!.targetClusterId;
    if (targetId == null) return;

    _collectFromCluster(targetId, _assignedTruck!);
    _findNewTarget(_assignedTruck!);
    notifyListeners();
  }

  double _getDistance(LatLng c1, LatLng c2) {
    return sqrt(pow(c1.latitude - c2.latitude, 2) + pow(c1.longitude - c2.longitude, 2));
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
