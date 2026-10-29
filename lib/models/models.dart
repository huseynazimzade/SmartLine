import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';

enum UserRole {
  citizen('Sakin', Icons.person_rounded);

  final String label;
  final IconData icon;

  const UserRole(this.label, this.icon);

  static UserRole fromString(String val) {
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
  pending('Gözləyir', AppColors.warning),
  sent('Göndərildi', AppColors.truckBlue),
  inProgress('İcrada', Color(0xFF2563EB)),
  resolved('Həll olundu', AppColors.primary),
  unresolved('Həll olunmadı', Color(0xFFE11D48));

  final String label;
  final Color color;

  const ReportStatus(this.label, this.color);

  bool get isResolved => this == ReportStatus.resolved;
  bool get isPending => this == ReportStatus.pending;
  bool get isSent => this == ReportStatus.sent;

  static ReportStatus fromString(String val) {
    switch (val) {
      case 'sent':
      case 'Göndərildi':
        return ReportStatus.sent;
      case 'inProgress':
      case 'İcrada':
        return ReportStatus.inProgress;
      case 'resolved':
      case 'Həll olundu':
        return ReportStatus.resolved;
      case 'unresolved':
      case 'Həll olunmadı':
        return ReportStatus.unresolved;
      case 'pending':
      case 'Baxılır':
      case 'Gözləyir':
      case 'Göndərilməyi gözləyir':
      default:
        return ReportStatus.pending;
    }
  }
}

enum ReportUrgency {
  low('Normal', AppColors.airGreen),
  medium('Orta', AppColors.warning),
  high('Yüksək', AppColors.critical),
  emergency('Təcili / Qəza', Color(0xFFDC2626));

  final String label;
  final Color color;

  const ReportUrgency(this.label, this.color);

  bool get isEmergency => this == ReportUrgency.emergency;

  static ReportUrgency fromString(String val) {
    switch (val.toLowerCase()) {
      case 'emergency':
      case 'təcili':
      case 'təcili / qəza':
      case 'qəza':
        return ReportUrgency.emergency;
      case 'high':
      case 'yüksək':
      case 'təcili / yüksək':
        return ReportUrgency.high;
      case 'medium':
      case 'orta':
        return ReportUrgency.medium;
      case 'low':
      case 'normal':
      case 'aşağı':
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
  String detectedProblem;
  double aiConfidence;
  String aiCategory;
  String targetDepartment;
  ReportUrgency urgency;
  ReportStatus status;
  ReportStage currentStage;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? locationAccuracy;
  final bool isLastKnownLocation;
  final String? emergencyContact;
  DateTime? sentAt;
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
    this.locationAccuracy,
    this.isLastKnownLocation = false,
    this.emergencyContact,
    this.sentAt,
    this.resolvedAt,
  })  : id = id ?? 'SL-${DateTime.now().year}-${1000 + const Uuid().v4().hashCode.abs() % 9000}',
        timestamp = timestamp ?? DateTime.now();

  LatLng get coordinate => LatLng(latitude, longitude);

  bool get isResolved => status == ReportStatus.resolved;
  bool get isPendingOffline => status == ReportStatus.pending;

  String get resolutionStatusText {
    switch (status) {
      case ReportStatus.resolved:
        return 'Həll olundu';
      case ReportStatus.unresolved:
        return 'Həll olunmadı';
      case ReportStatus.pending:
        return 'Gözləyir (Offline saxlandı)';
      case ReportStatus.sent:
        return 'Göndərildi (İcrada)';
      case ReportStatus.inProgress:
        return 'İcrada';
    }
  }

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
        'locationAccuracy': locationAccuracy,
        'isLastKnownLocation': isLastKnownLocation,
        'emergencyContact': emergencyContact,
        'sentAt': sentAt?.toIso8601String(),
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
        locationAccuracy: (json['locationAccuracy'] as num?)?.toDouble(),
        isLastKnownLocation: json['isLastKnownLocation'] as bool? ?? false,
        emergencyContact: json['emergencyContact'] as String?,
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
        resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      );
}

class User {
  final String id;
  final String phoneNumber;
  final bool isAuthenticated;
  final String username;
  final UserRole role;

  User({
    String? id,
    required this.phoneNumber,
    this.isAuthenticated = true,
    String? username,
    this.role = UserRole.citizen,
  })  : id = id ?? const Uuid().v4(),
        username = username ?? 'Hörmətli Sakin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'isAuthenticated': isAuthenticated,
        'username': username,
        'role': role.name,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String?,
        phoneNumber: json['phoneNumber'] as String,
        isAuthenticated: json['isAuthenticated'] as bool? ?? true,
        username: json['username'] as String?,
        role: UserRole.fromString(json['role'] as String? ?? 'citizen'),
      );
}
