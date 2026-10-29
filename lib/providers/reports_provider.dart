import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/offline_queue_service.dart';

class ReportsProvider extends ChangeNotifier {
  List<ProblemReport> _reports = [];
  bool _isLoaded = false;
  LatLng? _mapFocusCoordinate;
  String? _selectedReportId;

  List<ProblemReport> get reports => _reports;
  bool get isLoaded => _isLoaded;
  LatLng? get mapFocusCoordinate => _mapFocusCoordinate;
  String? get selectedReportId => _selectedReportId;

  ProblemReport? get selectedReport {
    if (_selectedReportId == null) return null;
    try {
      return _reports.firstWhere((r) => r.id == _selectedReportId);
    } catch (_) {
      return null;
    }
  }

  ReportsProvider() {
    _loadReports();
  }

  void setMapFocus(LatLng coord, {String? reportId}) {
    _mapFocusCoordinate = coord;
    _selectedReportId = reportId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedReportId = null;
    notifyListeners();
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('saved_citizen_reports_v2');

    if (jsonList != null && jsonList.isNotEmpty) {
      try {
        _reports = jsonList.map((str) => ProblemReport.fromJson(jsonDecode(str))).toList();
      } catch (e) {
        debugPrint('Error decoding reports: $e');
        _seedDefaultReports();
      }
    } else {
      _seedDefaultReports();
    }

    _isLoaded = true;
    notifyListeners();
  }

  void _seedDefaultReports() {
    _reports = [
      ProblemReport(
        id: 'SL-2026-8921',
        title: 'Nizami küçəsində zibil qutusunun daşması',
        description: 'Torqovaya ərazisində məişət tullantı qutuları dolub, ətrafa yayılır.',
        inputType: ReportInputType.photo,
        detectedProblem: 'Zibil qutularının 100% dolması və antisanitar vəziyyət',
        aiConfidence: 0.96,
        aiCategory: 'Məişət Tullantıları və Təmizlik',
        targetDepartment: 'Təmiz Şəhər ASC & BŞİH MKTB (153)',
        urgency: ReportUrgency.high,
        status: ReportStatus.inProgress,
        currentStage: ReportStage.inProgress,
        address: 'Nizami küçəsi 42, Səbail rayonu, Bakı',
        latitude: 40.3725,
        longitude: 40.3725 != 49.8400 ? 49.8400 : 49.8400,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ProblemReport(
        id: 'SL-2026-7814',
        title: 'Fəvvarələr meydanında su borusunun qəzası',
        description: 'Səkinin altındakı borudan güclü su axır, piyadaların hərəkəti çətinləşib.',
        inputType: ReportInputType.text,
        detectedProblem: 'İçməli su magistralında təzyiq qəzası və su axıntısı',
        aiConfidence: 0.94,
        aiCategory: 'Su Təchizatı və Kanalizasiya',
        targetDepartment: 'Azərsu ASC (185)',
        urgency: ReportUrgency.high,
        status: ReportStatus.resolved,
        currentStage: ReportStage.resolved,
        address: 'Fountain Square, Səbail rayonu, Bakı',
        latitude: 40.3715,
        longitude: 49.8375,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        resolvedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      ProblemReport(
        id: 'SL-2026-6102',
        title: 'Sahil Parkında küçə fənərlərinin sönməsi',
        description: 'Bulvar yaxınlığındakı fənərlər yanmır, ərazi qaranlıqdır.',
        inputType: ReportInputType.voice,
        detectedProblem: 'Elektrik kabelində xəta və fənər dirəyinin enerjisiz qalması',
        aiConfidence: 0.92,
        aiCategory: 'Enerji və Küçə İşıqlandırması',
        targetDepartment: 'Bakı Şəhər İşığı & Azərişıq (199)',
        urgency: ReportUrgency.medium,
        status: ReportStatus.pending,
        currentStage: ReportStage.classified,
        address: 'Sahil Parkı, Neftçilər prospekti, Bakı',
        latitude: 40.3750,
        longitude: 49.8486,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  Future<void> addReport(ProblemReport report) async {
    _reports.insert(0, report);
    _mapFocusCoordinate = report.coordinate;
    _selectedReportId = report.id;
    notifyListeners();
    await _saveReports();
  }

  Future<void> syncOfflineReportSent({
    required String id,
    required AiAnalysisResult analysis,
    required DateTime sentAt,
  }) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final report = _reports[idx];
      report.status = ReportStatus.sent;
      report.currentStage = ReportStage.classified;
      report.detectedProblem = analysis.detectedProblem;
      report.aiCategory = analysis.category;
      report.targetDepartment = analysis.targetDepartment;
      report.aiConfidence = analysis.confidence;
      report.urgency = analysis.urgency;
      report.sentAt = sentAt;
      notifyListeners();
      await _saveReports();
    }
  }

  Future<void> updateReportStatus(String id, ReportStatus newStatus, ReportStage newStage) async {
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _reports[idx].status = newStatus;
      _reports[idx].currentStage = newStage;
      if (newStatus == ReportStatus.resolved) {
        _reports[idx].resolvedAt = DateTime.now();
      }
      notifyListeners();
      await _saveReports();
    }
  }

  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    if (_selectedReportId == id) {
      _selectedReportId = null;
    }
    notifyListeners();
    await _saveReports();
    await OfflineQueueService.instance.removeFromQueue(id);
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('saved_citizen_reports_v2', jsonList);
  }
}
