import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartline_new/models/models.dart';
import 'package:smartline_new/providers/auth_provider.dart';
import 'package:smartline_new/providers/reports_provider.dart';
import 'package:smartline_new/services/ai_service.dart';
import 'package:smartline_new/services/api_config.dart';
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

    test('Photo vision analysis with optional context routes accurately', () async {
      final result = await AiService.analyzePhoto(
        optionalContext: 'Yolda dərin çuxur var, asfalt dağılıb',
      );
      expect(result.category, contains('Yol'));
      expect(result.targetDepartment, contains('Avtomobil Yolları'));
    });

    test('Voice analysis with simulated speech transcribes and classifies', () async {
      final speech = 'Bizim küçədə fənərlər yanmır, zülmət qaranlıqdır';
      final result = await AiService.analyzeVoice(simulatedSpeech: speech);
      expect(result.transcribedText, speech);
      expect(result.targetDepartment, contains('Azərişıq'));
      expect(result.confidence, greaterThan(0.85));
    });
  });

  group('ApiConfig Key Management Tests', () {
    test('Validates Groq, Gemini and OpenAI API keys correctly', () {
      expect(ApiConfig.isValidKey(''), false);
      expect(ApiConfig.isValidKey('BURAYA_GROQ_API_KEY_YAPISDIRIN'), false);
      expect(ApiConfig.isValidKey('BURAYA_API_KEY_YAPISDIRIN'), false);
      expect(ApiConfig.isValidKey('gsk_Abc1234567890XYZ12345'), true);
      expect(ApiConfig.isValidKey('AIzaSyAbc1234567890XYZ'), true);
      expect(ApiConfig.isValidKey('sk-proj-1234567890abcdef'), true);

      expect(ApiConfig.isGroqKey('gsk_Abc123'), true);
      expect(ApiConfig.isGeminiKey('AIzaSyAbc123'), true);
      expect(ApiConfig.isOpenAiKey('sk-proj-abc'), true);
      expect(ApiConfig.isOpenAiKey('gsk_Abc'), false);

      expect(ApiConfig.getProviderName('gsk_Abc123'), 'Groq LPU AI');
      expect(ApiConfig.getProviderName('AIzaSyAbc'), 'Google Gemini');
      expect(ApiConfig.getProviderName('sk-proj-abc'), 'OpenAI');
    });

    test('Saves, retrieves, and clears custom API key in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ApiConfig.getApiKey(), ApiConfig.defaultApiKey);

      await ApiConfig.saveApiKey('AIzaSyMockTestKeyForTestingOnly123');
      expect(await ApiConfig.getApiKey(), 'AIzaSyMockTestKeyForTestingOnly123');

      await ApiConfig.clearApiKey();
      expect(await ApiConfig.getApiKey(), ApiConfig.defaultApiKey);
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

    test('Can delete a report and remove it from history', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ReportsProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      final initialCount = provider.reports.length;

      final toDelete = provider.reports.first;
      await provider.deleteReport(toDelete.id);
      expect(provider.reports.length, initialCount - 1);
      expect(provider.reports.any((r) => r.id == toDelete.id), false);
    });
  });

  group('Citizen AuthProvider Tests', () {
    test('Can log in directly with demo or verify OTP as Citizen', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthProvider();

      expect(auth.selectedRole, UserRole.citizen);

      // Instant demo login
      await auth.loginAsCitizen();
      expect(auth.currentUser!.role, UserRole.citizen);
      expect(auth.currentUser!.isAuthenticated, true);
      expect(auth.currentUser!.username, 'Hörmətli Sakin');

      // Logout
      await auth.logout();
      expect(auth.currentUser, null);

      // Verify OTP
      final success = await auth.verifyOtp('50 999 88 77', '1111');
      expect(success, true);
      expect(auth.currentUser!.phoneNumber, '50 999 88 77');
      expect(auth.currentUser!.isAuthenticated, true);
    });
  });
}
