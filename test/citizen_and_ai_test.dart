import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartline_new/models/models.dart';
import 'package:smartline_new/providers/auth_provider.dart';
import 'package:smartline_new/providers/reports_provider.dart';
import 'package:smartline_new/services/ai_service.dart';
import 'package:smartline_new/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Citizen AI Analysis Tests', () {
    test('Water pipe leak keywords route to Azərsu ASC', () async {
      final result = await AiService.analyzeText('Su borusu partlayıb, asfaltın altından su axır');
      expect(result.category, contains('Su'));
      expect(result.targetDepartment, contains('Azərsu'));
      expect(result.urgency, ReportUrgency.high);
      expect(result.confidence, greaterThan(0.8));
    });

    test('Overflowing waste bin keywords route to Təmiz Şəhər & BŞİH', () async {
      final result = await AiService.analyzeText('Zibil qutusu dolub daşır, zibillər yerə tökülüb');
      expect(result.category, contains('Tullantı'));
      expect(result.targetDepartment, contains('Təmiz Şəhər'));
      expect(result.urgency, ReportUrgency.high);
    });

    test('Street lighting keywords route to Azərişıq', () async {
      final result = await AiService.analyzeText('Küçə fənərləri yanmır, dirək sönüb');
      expect(result.targetDepartment, contains('Azərişıq'));
    });

    test('Photo vision analysis returns classified municipal issue', () async {
      final result = await AiService.analyzePhoto();
      expect(result.title.isNotEmpty, true);
      expect(result.confidence, greaterThan(0.85));
      expect(result.targetDepartment.isNotEmpty, true);
    });
  });

  group('Location Service Tests', () {
    test('Gets current or fallback Baku location', () async {
      final loc = await LocationService.getCurrentLocation();
      expect(loc.latitude, greaterThan(40.0));
      expect(loc.longitude, greaterThan(49.0));
      expect(loc.address.isNotEmpty, true);
    });
  });

  group('Citizen ReportsProvider Tests', () {
    test('Adds and saves problem report with stage and coordinates', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ReportsProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final initialCount = provider.reports.length;

      final newReport = ProblemReport(
        title: 'Su borusu qəzası',
        description: 'Təcili təmir lazımdır',
        inputType: ReportInputType.photo,
        detectedProblem: 'Su borusu partlayışı',
        aiConfidence: 0.95,
        aiCategory: 'Su Təchizatı',
        targetDepartment: 'Azərsu ASC',
        urgency: ReportUrgency.high,
        status: ReportStatus.pending,
        currentStage: ReportStage.classified,
        address: 'Nizami küçəsi 14',
        latitude: 40.3725,
        longitude: 49.8400,
      );

      await provider.addReport(newReport);
      expect(provider.reports.length, initialCount + 1);
      expect(provider.reports.first.title, 'Su borusu qəzası');
      expect(provider.reports.first.isResolved, false);
      expect(provider.reports.first.currentStage, ReportStage.classified);

      // Test resolving problem
      await provider.updateReportStatus(newReport.id, ReportStatus.resolved, ReportStage.resolved);
      expect(provider.reports.first.isResolved, true);
      expect(provider.reports.first.currentStage, ReportStage.resolved);
    });
  });

  group('Dual Role AuthProvider Tests', () {
    test('Can log in directly as Driver or Citizen and switch roles', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthProvider();

      expect(auth.selectedRole, UserRole.citizen);

      // Instant 1-tap entry as driver
      await auth.loginAsRole(UserRole.driver);
      expect(auth.currentUser!.role, UserRole.driver);
      expect(auth.selectedRole, UserRole.driver);

      // Switch to citizen
      await auth.switchRole(UserRole.citizen);
      expect(auth.currentUser!.role, UserRole.citizen);
      expect(auth.selectedRole, UserRole.citizen);
    });
  });
}
