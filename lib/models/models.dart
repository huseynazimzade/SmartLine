import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';

enum UserRole {
  citizen('Sakin', Icons.person_rounded),
  driver('Zibil maşını sürücüsü', Icons.local_shipping_rounded);

  final String label;
  final IconData icon;

  const UserRole(this.label, this.icon);

  static UserRole fromString(String val) {
    if (val.toLowerCase().contains('surucu') ||
        val.toLowerCase().contains('driver') ||
        val.toLowerCase().contains('zibil')) {
      return UserRole.driver;
    }
    return UserRole.citizen;
  }
}

enum ReportInputType {
  photo('Şəkil ilə', Icons.photo_camera_rounded),
  voice('Səs ilə', Icons.mic_rounded),
  text('Mətn ilə', Icons.edit_note_rounded);

  final String label;
  final IconData icon;

  const ReportInputType(this.label, this.icon);
}

enum ReportStage {
  received('1. Qəbul edildi', 'Vətəndaş müraciəti sistemə daxil oldu', 0.25),
  classified('2. AI Təhlil & Yönləndirmə', 'Süni intellekt problemi təyin etdi və aidiyyəti quruma göndərdi', 0.50),
  inProgress('3. İcrada', 'Əraziyə xüsusi texnika və briqada cəlb olunub', 0.75),
  resolved('4. Tam həll olundu', 'İşlər tamamlandı və vətəndaş razılığı alındı', 1.0);

  final String label;
  final String description;
  final double progress;

  const ReportStage(this.label, this.description, this.progress);

  static ReportStage fromString(String val) {
    for (final s in ReportStage.values) {
      if (s.name == val) return s;
    }
    return ReportStage.received;
  }
}

enum ReportStatus {
  pending('Baxılır', AppColors.warning),
  inProgress('İcrada', AppColors.truckBlue),
  resolved('Həll olundu', AppColors.primary);

  final String label;
  final Color color;

  const ReportStatus(this.label, this.color);

  bool get isResolved => this == ReportStatus.resolved;

  static ReportStatus fromString(String val) {
    switch (val) {
      case 'inProgress':
      case 'İcrada':
        return ReportStatus.inProgress;
      case 'resolved':
      case 'Həll olundu':
        return ReportStatus.resolved;
      case 'pending':
      case 'Baxılır':
      default:
        return ReportStatus.pending;
    }
  }
}

enum ReportUrgency {
  low('Normal', AppColors.airGreen),
  medium('Orta', AppColors.warning),
  high('Təcili / Yüksək', AppColors.critical);

  final String label;
  final Color color;

  const ReportUrgency(this.label, this.color);

  static ReportUrgency fromString(String val) {
    switch (val) {
      case 'high':
      case 'Təcili / Yüksək':
        return ReportUrgency.high;
      case 'medium':
      case 'Orta':
        return ReportUrgency.medium;
      case 'low':
      case 'Normal':
      default:
        return ReportUrgency.low;
    }
  }
}

class ProblemReport {
  final String id;
  final String title;
  final String description;
  final ReportInputType inputType;
  final String? photoPath;
  final String? voiceAudioPath;
  final String detectedProblem;
  final double aiConfidence;
  final String aiCategory;
  final String targetDepartment;
  final ReportUrgency urgency;
  ReportStatus status;
  ReportStage currentStage;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  DateTime? resolvedAt;

  ProblemReport({
    String? id,
    required this.title,
    required this.description,
    required this.inputType,
    this.photoPath,
    this.voiceAudioPath,
    required this.detectedProblem,
    required this.aiConfidence,
    required this.aiCategory,
    required this.targetDepartment,
    required this.urgency,
    this.status = ReportStatus.pending,
    this.currentStage = ReportStage.classified,
    required this.address,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
    this.resolvedAt,
  })  : id = id ?? 'SL-${DateTime.now().year}-${1000 + const Uuid().v4().hashCode.abs() % 9000}',
        timestamp = timestamp ?? DateTime.now();

  LatLng get coordinate => LatLng(latitude, longitude);

  bool get isResolved => status == ReportStatus.resolved;

  String get resolutionStatusText => isResolved ? 'Həll olundu' : 'Həll olunmayıb (Aktiv)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'inputType': inputType.name,
        'photoPath': photoPath,
        'voiceAudioPath': voiceAudioPath,
        'detectedProblem': detectedProblem,
        'aiConfidence': aiConfidence,
        'aiCategory': aiCategory,
        'targetDepartment': targetDepartment,
        'urgency': urgency.name,
        'status': status.name,
        'currentStage': currentStage.name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory ProblemReport.fromJson(Map<String, dynamic> json) => ProblemReport(
        id: json['id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        inputType: ReportInputType.values.byName(json['inputType'] as String),
        photoPath: json['photoPath'] as String?,
        voiceAudioPath: json['voiceAudioPath'] as String?,
        detectedProblem: json['detectedProblem'] as String,
        aiConfidence: (json['aiConfidence'] as num).toDouble(),
        aiCategory: json['aiCategory'] as String,
        targetDepartment: json['targetDepartment'] as String,
        urgency: ReportUrgency.fromString(json['urgency'] as String),
        status: ReportStatus.fromString(json['status'] as String),
        currentStage: json['currentStage'] != null
            ? ReportStage.fromString(json['currentStage'] as String)
            : (json['status'] == 'resolved' ? ReportStage.resolved : ReportStage.classified),
        address: json['address'] as String,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 40.37767,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 49.84508,
        timestamp: DateTime.parse(json['timestamp'] as String),
        resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      );
}

class User {
  final String id;
  final String phoneNumber;
  final bool isAuthenticated;
  final String username;
  final UserRole role;
  final String? assignedTruckId;

  User({
    String? id,
    required this.phoneNumber,
    this.isAuthenticated = true,
    String? username,
    this.role = UserRole.citizen,
    this.assignedTruckId,
  })  : id = id ?? const Uuid().v4(),
        username = username ?? (role == UserRole.driver ? 'Eko Sürücü' : 'Hörmətli Sakin');

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'isAuthenticated': isAuthenticated,
        'username': username,
        'role': role.name,
        'assignedTruckId': assignedTruckId,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String?,
        phoneNumber: json['phoneNumber'] as String,
        isAuthenticated: json['isAuthenticated'] as bool? ?? true,
        username: json['username'] as String?,
        role: UserRole.fromString(json['role'] as String? ?? 'citizen'),
        assignedTruckId: json['assignedTruckId'] as String?,
      );
}

// Waste Management Models for Driver Module
enum BinType {
  mixed('General Waste', Icons.delete_rounded, '#238B45'),
  plastic('Plastic/Metal', Icons.local_drink_rounded, '#F59E0B'),
  clothes('Clothes/Fabric', Icons.checkroom_rounded, '#8B5CF6');

  final String label;
  final IconData icon;
  final String hexColor;

  const BinType(this.label, this.icon, this.hexColor);

  Color get color => AppColors.hex(hexColor);

  static BinType fromString(String value) {
    switch (value) {
      case 'Plastic/Metal':
      case 'plastic':
        return BinType.plastic;
      case 'Clothes/Fabric':
      case 'clothes':
        return BinType.clothes;
      case 'General Waste':
      case 'mixed':
      default:
        return BinType.mixed;
    }
  }
}

class WasteBin {
  final String id;
  final BinType type;
  double fillLevel;
  double temperature;
  double humidity;
  double airQuality;
  DateTime lastEmptied;

  WasteBin({
    String? id,
    required this.type,
    required this.fillLevel,
    required this.temperature,
    required this.humidity,
    required this.airQuality,
    required this.lastEmptied,
  }) : id = id ?? const Uuid().v4();

  Color get statusColor {
    if (fillLevel > 0.85) return AppColors.critical;
    if (fillLevel > 0.6) return AppColors.warning;
    return AppColors.primary;
  }

  Color get tempColor {
    if (temperature > 40) return AppColors.critical;
    if (temperature > 30) return AppColors.warning;
    return AppColors.airGreen;
  }

  Color get humidityColor {
    if (humidity > 70) return AppColors.critical;
    return AppColors.humidityBlue;
  }

  Color get aqiColor {
    if (airQuality > 100) return AppColors.critical;
    if (airQuality > 50) return AppColors.warning;
    return AppColors.airGreen;
  }
}

class BinCluster {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final List<WasteBin> bins;

  BinCluster({
    String? id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.bins,
  }) : id = id ?? const Uuid().v4();

  LatLng get coordinate => LatLng(latitude, longitude);

  double get avgFillLevel {
    if (bins.isEmpty) return 0.0;
    final total = bins.fold<double>(0.0, (sum, bin) => sum + bin.fillLevel);
    return total / bins.length;
  }

  Color get statusColor {
    final avg = avgFillLevel;
    if (avg > 0.8) return AppColors.critical;
    if (avg > 0.5) return AppColors.warning;
    return AppColors.primary;
  }
}

class CollectionTruck {
  final String id;
  double latitude;
  double longitude;
  String status;
  double capacity;
  String? targetClusterId;
  List<LatLng> routePoints;
  int currentPointIndex;
  LatLng? lastRequestedTarget;

  CollectionTruck({
    String? id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.capacity,
    this.targetClusterId,
    List<LatLng>? routePoints,
    this.currentPointIndex = 0,
    this.lastRequestedTarget,
  })  : id = id ?? const Uuid().v4(),
        routePoints = routePoints ?? [];

  LatLng get coordinate => LatLng(latitude, longitude);
}
