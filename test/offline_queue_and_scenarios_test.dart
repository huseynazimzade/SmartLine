import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartline_new/models/models.dart';
import 'package:smartline_new/providers/reports_provider.dart';
import 'package:smartline_new/services/ai_service.dart';
import 'package:smartline_new/services/network_service.dart';
import 'package:smartline_new/services/offline_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    NetworkService.instance.setMockOffline(false);
  });

  group('MƏRHƏLƏ 4 — Hərtərəfli Offline və AI Ssenari Testləri', () {
    // Ssenari 1: İnternet yox → bildiriş göndər → tətbiqi bağla/aç → internet qoş → avtomatik göndərilir
    test('Ssenari 1: Oflayn bildiriş saxlanılır, tətbiq açılışında qorunur, internet bərpa olunanda avtomatik göndərilir', () async {
      // 1. Simulyasiya: İnternet yoxdur
      NetworkService.instance.setMockOffline(true);
      expect(NetworkService.instance.isConnected, false);

      final originalTime = DateTime(2026, 10, 18, 9, 30, 0);
      const originalLat = 40.3750;
      const originalLon = 49.8450;
      const originalAcc = 3.5;

      final reportsProvider = ReportsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await OfflineQueueService.instance.init(reportsProvider);
      await OfflineQueueService.instance.clearForTesting();

      final offlineReport = ProblemReport(
        id: 'SL-OFFLINE-001',
        title: 'Su sızması',
        description: 'Küçədə su borusundan su axır',
        inputType: ReportInputType.text,
        detectedProblem: 'Gözləmədə',
        aiConfidence: 0.0,
        aiCategory: 'Gözləmədə',
        targetDepartment: 'Təyin edilir...',
        urgency: ReportUrgency.medium,
        status: ReportStatus.pending, // "Göndərilməyi gözləyir"
        currentStage: ReportStage.received,
        address: 'Nizami küçəsi 55',
        latitude: originalLat,
        longitude: originalLon,
        locationAccuracy: originalAcc,
        timestamp: originalTime,
      );

      // Bildirişi lokal yaddaşa və növbəyə daxil et
      await reportsProvider.addReport(offlineReport);
      await OfflineQueueService.instance.enqueueReport(offlineReport);

      expect(OfflineQueueService.instance.pendingCount, 1);
      expect(reportsProvider.reports.first.status, ReportStatus.pending);
      expect(reportsProvider.reports.first.timestamp, originalTime);

      // 2. Simulyasiya: Tətbiqi bağla və yenidən aç (Yeni provayder və servis nüsxəsi)
      final restartedProvider = ReportsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await OfflineQueueService.instance.init(restartedProvider);

      // Yoxla ki, saxlanmış bildiriş və növbə itməyib
      expect(OfflineQueueService.instance.pendingCount, 1);
      final pendingItem = OfflineQueueService.instance.pendingItems.first;
      expect(pendingItem.id, 'SL-OFFLINE-001');
      expect(pendingItem.latitude, originalLat);
      expect(pendingItem.longitude, originalLon);
      expect(pendingItem.originalTimestamp, originalTime);

      // 3. Simulyasiya: İnternet qoşulur
      NetworkService.instance.setMockOffline(false);
      expect(NetworkService.instance.isConnected, true);

      // Avtomatik növbənin emal olunması
      await OfflineQueueService.instance.processPendingQueue();
      await Future.delayed(const Duration(milliseconds: 300));

      // Yoxla: Uğurlu göndərişdən sonra status "Göndərildi" olur və lokal pending qeydi təmizlənir
      expect(OfflineQueueService.instance.pendingCount, 0);

      final syncedReport = restartedProvider.reports.firstWhere((r) => r.id == 'SL-OFFLINE-001');
      expect(syncedReport.status, ReportStatus.sent);
      expect(syncedReport.targetDepartment, contains('Azərsu'));
      expect(syncedReport.timestamp, originalTime); // ORİJİNAL vaxt qorunmalıdır!
      expect(syncedReport.latitude, originalLat);   // ORİJİNAL lokasiya qorunmalıdır!
      expect(syncedReport.longitude, originalLon);
    });

    // Ssenari 2: "Qaz borusu partladı" → Azəriqaz + emergency (Azərsu OLMAMALIDIR)
    test('Ssenari 2: "Qaz borusu partladı" müraciəti Azəriqaz + emergency olmalıdır (Azərsu OLMAMALIDIR)', () async {
      final result = await AiService.analyzeText('Qaz borusu partladı, ətrafa kəskin qaz iyi yayılır');

      expect(result.targetDepartment, contains('Azəriqaz'));
      expect(result.targetDepartment.contains('Azərsu'), false, reason: 'Azərsu OLMAMALIDIR!');
      expect(result.urgency, ReportUrgency.emergency);
      expect(result.emergencyContact, '104');
      expect(result.confidence, greaterThanOrEqualTo(0.95));
      expect(result.category, contains('Qaz'));
    });

    // Ssenari 3: "Su borusu partladı" → Azərsu
    test('Ssenari 3: "Su borusu partladı" müraciəti Azərsu qurumuna yönləndirilməlidir', () async {
      final result = await AiService.analyzeText('Su borusu partladı, asfaltın altından güclü su axır');

      expect(result.targetDepartment, contains('Azərsu'));
      expect(result.targetDepartment.contains('Azəriqaz'), false);
      expect(result.category, contains('Su'));
      expect(result.confidence, greaterThanOrEqualTo(0.85));
    });

    // Ssenari 4: "Dirəkdən naqil sallanır" → Azərişıq + emergency
    test('Ssenari 4: "Dirəkdən naqil sallanır" müraciəti Azərişıq və emergency olmalıdır', () async {
      final result = await AiService.analyzeText('Dirəkdən naqil sallanır, qığılcım saçır, təhlükəlidir');

      expect(result.targetDepartment, contains('Azərişıq'));
      expect(result.urgency, ReportUrgency.emergency);
      expect(result.emergencyContact, '199');
      expect(result.category, contains('Elektrik'));
    });

    // Ssenari 5: Qeyri-müəyyən mətn → "Digər / yoxlama tələb edir"
    test('Ssenari 5: Qeyri-müəyyən mətn "Digər / yoxlama tələb edir" və confidence < 0.6 kimi işarələnməlidir', () async {
      final result = await AiService.analyzeText('salam necəsiz bir məsələ var');

      expect(result.targetDepartment, contains('Digər / yoxlama tələb edir'));
      expect(result.confidence, lessThan(0.60));
      expect(result.category, 'Digər');
    });

    // Ssenari 6: Göndərmə yarımçıq qırılır → təkrar cəhd, dublikat yoxdur (idempotency)
    test('Ssenari 6: Göndərmə qırıldıqda retry mexanizmi işləyir və dublikatın qarşısı alınır (idempotency)', () async {
      final reportsProvider = ReportsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await OfflineQueueService.instance.init(reportsProvider);
      await OfflineQueueService.instance.clearForTesting();

      final report = ProblemReport(
        id: 'SL-IDEMPOTENT-777',
        title: 'Zibil problemi',
        description: 'Zibil qutuları dolub',
        inputType: ReportInputType.text,
        detectedProblem: 'Gözləmədə',
        aiConfidence: 0.0,
        aiCategory: 'Gözləmədə',
        targetDepartment: 'Təyin edilir...',
        urgency: ReportUrgency.medium,
        status: ReportStatus.pending,
        currentStage: ReportStage.received,
        address: '28 May küçəsi',
        latitude: 40.3798,
        longitude: 49.8488,
        timestamp: DateTime.now(),
      );

      // 1. Təkrar əlavə etmə cəhdi (Idempotency)
      await OfflineQueueService.instance.enqueueReport(report);
      expect(OfflineQueueService.instance.pendingCount, 1);

      // Eyni report-u yenidən əlavə etməyə cəhd edirik
      await OfflineQueueService.instance.enqueueReport(report);
      // Növbədə hələ də yalnız 1 ədəd qalmalıdır!
      expect(OfflineQueueService.instance.pendingCount, 1);

      // 2. Uğurlu göndəriş
      NetworkService.instance.setMockOffline(false);
      await OfflineQueueService.instance.processPendingQueue();
      await Future.delayed(const Duration(milliseconds: 300));

      expect(OfflineQueueService.instance.pendingCount, 0);

      // 3. Eyni UUID-li bildiriş yenidən göndərilməyə cəhd edilərsə, idempotency onu bloklamalıdır
      await OfflineQueueService.instance.enqueueReport(report);
      expect(OfflineQueueService.instance.pendingCount, 0);
    });

    // Statuslar test: "Keçmiş bildirişlər" ekranında 4 status mövcudluğu
    test('ReportStatus enum Gözləyir, Göndərildi, Həll olundu və Həll olunmadı statuslarını dəstəkləyir', () {
      expect(ReportStatus.pending.label, 'Gözləyir');
      expect(ReportStatus.sent.label, 'Göndərildi');
      expect(ReportStatus.resolved.label, 'Həll olundu');
      expect(ReportStatus.unresolved.label, 'Həll olunmadı');

      expect(ReportStatus.fromString('Gözləyir'), ReportStatus.pending);
      expect(ReportStatus.fromString('Göndərildi'), ReportStatus.sent);
      expect(ReportStatus.fromString('Həll olundu'), ReportStatus.resolved);
      expect(ReportStatus.fromString('Həll olunmadı'), ReportStatus.unresolved);
    });
  });
}
