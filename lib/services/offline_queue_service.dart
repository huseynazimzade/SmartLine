import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/reports_provider.dart';
import 'ai_service.dart';
import 'network_service.dart';

class OfflineQueueItem {
  final String id;
  final String? text;
  final String? photoPath;
  final String? voiceAudioPath;
  final DateTime originalTimestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isLastKnownLocation;
  final String address;
  final ReportInputType inputType;
  int retryCount;
  DateTime? lastAttempt;
  String status;

  OfflineQueueItem({
    required this.id,
    this.text,
    this.photoPath,
    this.voiceAudioPath,
    required this.originalTimestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.isLastKnownLocation = false,
    required this.address,
    required this.inputType,
    this.retryCount = 0,
    this.lastAttempt,
    this.status = 'Göndərilməyi gözləyir',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'photoPath': photoPath,
        'voiceAudioPath': voiceAudioPath,
        'originalTimestamp': originalTimestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'isLastKnownLocation': isLastKnownLocation,
        'address': address,
        'inputType': inputType.name,
        'retryCount': retryCount,
        'lastAttempt': lastAttempt?.toIso8601String(),
        'status': status,
      };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) => OfflineQueueItem(
        id: json['id'] as String,
        text: json['text'] as String?,
        photoPath: json['photoPath'] as String?,
        voiceAudioPath: json['voiceAudioPath'] as String?,
        originalTimestamp: DateTime.parse(json['originalTimestamp'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        isLastKnownLocation: json['isLastKnownLocation'] as bool? ?? false,
        address: json['address'] as String? ?? 'Bakı şəhəri',
        inputType: ReportInputType.values.byName(json['inputType'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt'] as String) : null,
        status: json['status'] as String? ?? 'Göndərilməyi gözləyir',
      );
}

class OfflineQueueService {
  static final OfflineQueueService instance = OfflineQueueService._internal();

  OfflineQueueService._internal();

  static const String _prefQueueKey = 'smartline_offline_queue_v2';
  static const String _prefProcessedKey = 'smartline_processed_ids_v2';
  static const int maxRetries = 5;

  List<OfflineQueueItem> _queue = [];
  Set<String> _processedIds = {};
  bool _isProcessing = false;
  ReportsProvider? _reportsProvider;
  StreamSubscription? _netSubscription;

  List<OfflineQueueItem> get pendingItems => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;

  /// Registers ReportsProvider and sets up connectivity listening
  Future<void> init(ReportsProvider reportsProvider) async {
    _reportsProvider = reportsProvider;
    await _loadFromStorage();

    _netSubscription?.cancel();
    _netSubscription = NetworkService.instance.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('[OfflineQueueService] İnternet aşkarlandı, növbədəki bildirişlər göndərilir...');
        processPendingQueue();
      }
    });

    if (NetworkService.instance.isConnected && _queue.isNotEmpty) {
      processPendingQueue();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefQueueKey);
      if (list != null) {
        _queue = list.map((item) => OfflineQueueItem.fromJson(jsonDecode(item))).toList();
      }

      final processed = prefs.getStringList(_prefProcessedKey);
      if (processed != null) {
        _processedIds = processed.toSet();
      }
    } catch (e) {
      debugPrint('[OfflineQueueService] Storage load error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _queue.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_prefQueueKey, list);
      await prefs.setStringList(_prefProcessedKey, _processedIds.toList());
    } catch (e) {
      debugPrint('[OfflineQueueService] Storage save error: $e');
    }
  }

  /// Adds a new report to the offline queue
  Future<void> enqueueReport(ProblemReport report) async {
    // Prevent duplicate queuing of the same ID (idempotency)
    if (_processedIds.contains(report.id) || _queue.any((q) => q.id == report.id)) {
      debugPrint('[OfflineQueueService] Report ${report.id} already queued or processed.');
      return;
    }

    final item = OfflineQueueItem(
      id: report.id,
      text: report.description,
      photoPath: report.photoPath,
      voiceAudioPath: report.voiceAudioPath,
      originalTimestamp: report.timestamp, // Original creation time
      latitude: report.latitude,           // Original latitude
      longitude: report.longitude,         // Original longitude
      accuracy: report.locationAccuracy,   // Original GPS accuracy
      isLastKnownLocation: report.isLastKnownLocation,
      address: report.address,
      inputType: report.inputType,
      status: 'Göndərilməyi gözləyir',
    );

    _queue.add(item);
    await _saveToStorage();
    debugPrint('[OfflineQueueService] Report ${report.id} offline növbəyə əlavə edildi (Cəmi pending: ${_queue.length})');

    // If online right now, try processing immediately
    if (NetworkService.instance.isConnected) {
      processPendingQueue();
    }
  }

  /// Removes a report from the offline queue (e.g. when deleted by user)
  Future<void> removeFromQueue(String id) async {
    _queue.removeWhere((item) => item.id == id);
    _processedIds.remove(id);
    await _saveToStorage();
    debugPrint('[OfflineQueueService] Report $id növbədən silindi.');
  }

  /// Processes all pending reports from oldest to newest (FIFO)
  Future<void> processPendingQueue() async {
    if (_isProcessing) return;
    if (_queue.isEmpty) return;
    if (!NetworkService.instance.isConnected) {
      debugPrint('[OfflineQueueService] İnternet yoxdur, növbə gözləmə rejimində qalır.');
      return;
    }

    _isProcessing = true;

    try {
      // Sort oldest to newest by original creation timestamp
      _queue.sort((a, b) => a.originalTimestamp.compareTo(b.originalTimestamp));

      final itemsToProcess = List<OfflineQueueItem>.from(_queue);

      for (final item in itemsToProcess) {
        // Idempotency: skip if already processed
        if (_processedIds.contains(item.id)) {
          _queue.removeWhere((q) => q.id == item.id);
          await _saveToStorage();
          continue;
        }

        // Exponential backoff check
        if (item.retryCount > 0 && item.lastAttempt != null) {
          final waitSeconds = min(60, pow(2, item.retryCount).toInt());
          if (DateTime.now().difference(item.lastAttempt!).inSeconds < waitSeconds) {
            debugPrint('[OfflineQueueService] Item ${item.id} backoff gözləməsindədir (${waitSeconds}s)');
            continue;
          }
        }

        bool success = false;
        try {
          debugPrint('[OfflineQueueService] Bildiriş göndərilir: ${item.id} (Orijinal vaxt: ${item.originalTimestamp})');

          // Send to Server / AI Pipeline with ORIGINAL metadata
          AiAnalysisResult analysis;
          if (item.inputType == ReportInputType.photo) {
            analysis = await AiService.analyzePhoto(
              photoPath: item.photoPath,
              optionalContext: item.text,
            );
          } else if (item.inputType == ReportInputType.voice) {
            analysis = await AiService.analyzeVoice(
              audioPath: item.voiceAudioPath,
              simulatedSpeech: item.text,
            );
          } else {
            analysis = await AiService.analyzeText(item.text ?? '');
          }

          // Mark as processed successfully
          _processedIds.add(item.id);

          // Update ReportsProvider so user sees status "Göndərildi" and classified institution
          if (_reportsProvider != null) {
            await _reportsProvider!.syncOfflineReportSent(
              id: item.id,
              analysis: analysis,
              sentAt: DateTime.now(),
            );
          }

          // Remove from local pending queue
          _queue.removeWhere((q) => q.id == item.id);
          await _saveToStorage();
          success = true;
          debugPrint('[OfflineQueueService] Bildiriş uğurla serverə çatdırıldı və status "Göndərildi" oldu: ${item.id}');
        } catch (e) {
          debugPrint('[OfflineQueueService] Göndərmə xətası (ID: ${item.id}): $e');
          item.retryCount++;
          item.lastAttempt = DateTime.now();
          item.status = 'Xəta: Təkrar cəhd ediləcək (${item.retryCount}/$maxRetries)';
          await _saveToStorage();
        }

        // Small pause between multiple queued requests
        if (success) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Clears queue for testing
  Future<void> clearForTesting() async {
    _queue.clear();
    _processedIds.clear();
    await _saveToStorage();
  }
}
