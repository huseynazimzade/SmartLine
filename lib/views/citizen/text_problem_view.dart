import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/reports_provider.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/network_service.dart';
import '../../services/offline_queue_service.dart';
import '../../theme/app_theme.dart';

class TextProblemView extends StatefulWidget {
  const TextProblemView({super.key});

  @override
  State<TextProblemView> createState() => _TextProblemViewState();
}

class _TextProblemViewState extends State<TextProblemView> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;
  AiAnalysisResult? _aiResult;

  double _detectedLat = 40.3725;
  double _detectedLon = 49.8400;
  String _detectedAddress = 'Nizami küçəsi 48, Səbail rayonu, Bakı';
  double _detectedAccuracy = 5.0;
  bool _isLastKnownLocation = false;

  final List<String> _quickChips = [
    'Qaz borusu partladı, kəskin qaz iyi gəlir',
    'Su borusu partlayıb, asfaltın altından su axır',
    'Dirəkdən naqil sallanır, qığılcım saçır',
    'Zibil qutuları dolub daşır, antisanitar vəziyyətdir',
    'Yolda dərin çuxur var, avtomobillər zədələnir',
    'Yanğın baş verib, ətrafı tüstü bürüyüb',
  ];

  bool get _isOffline => !NetworkService.instance.isConnected;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _detectedLat = loc.latitude;
        _detectedLon = loc.longitude;
        _detectedAddress = loc.address;
        _detectedAccuracy = loc.accuracy;
        _isLastKnownLocation = loc.isLastKnownLocation;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (_isOffline) {
      _submitOfflineReport();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiResult = null;
    });

    final result = await AiService.analyzeText(text);

    if (mounted) {
      setState(() {
        _aiResult = result;
        _isAnalyzing = false;
      });
    }
  }

  void _submitOfflineReport() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final report = ProblemReport(
      title: text.length > 35 ? '${text.substring(0, 35)}...' : text,
      description: text,
      inputType: ReportInputType.text,
      detectedProblem: 'İnternet bağlantısı gözlənilir (AI təhlili onlayn rejimdə aparılacaq)',
      aiConfidence: 0.0,
      aiCategory: 'Gözləmədə',
      targetDepartment: 'Təyin edilir...',
      urgency: ReportUrgency.medium,
      status: ReportStatus.pending,
      currentStage: ReportStage.received,
      address: _detectedAddress,
      latitude: _detectedLat,
      longitude: _detectedLon,
      locationAccuracy: _detectedAccuracy,
      isLastKnownLocation: _isLastKnownLocation,
      timestamp: DateTime.now(), // Original creation time
    );

    Provider.of<ReportsProvider>(context, listen: false).addReport(report);
    OfflineQueueService.instance.enqueueReport(report);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.warning,
                size: 52,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oflayn Saxlandı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'İnternet yoxdur. Bildiriş telefonda saxlandı, internet gələndə avtomatik göndəriləcək.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Qeydiyyat №: ${report.id}\nOrijinal GPS və vaxt etibarlı şəkildə qorundu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Return to map
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anladım, Xəritəyə qayıt'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport() {
    if (_aiResult == null) {
      if (_isOffline) {
        _submitOfflineReport();
      }
      return;
    }

    final report = ProblemReport(
      title: _aiResult!.title,
      description: _textController.text.trim(),
      inputType: ReportInputType.text,
      detectedProblem: _aiResult!.detectedProblem,
      aiConfidence: _aiResult!.confidence,
      aiCategory: _aiResult!.category,
      targetDepartment: _aiResult!.targetDepartment,
      urgency: _aiResult!.urgency,
      status: ReportStatus.sent,
      currentStage: ReportStage.classified,
      address: _detectedAddress,
      latitude: _detectedLat,
      longitude: _detectedLon,
      locationAccuracy: _detectedAccuracy,
      isLastKnownLocation: _isLastKnownLocation,
      emergencyContact: _aiResult!.emergencyContact,
      sentAt: DateTime.now(),
    );

    Provider.of<ReportsProvider>(context, listen: false).addReport(report);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 54,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Problem Xəritədə İşarələndi!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Qeydiyyat №: ${report.id}\nMüraciətiniz qəbul edildi, konum xəritədə işarələndi və "${report.targetDepartment}" idarəsinə yönləndirildi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            if (report.urgency == ReportUrgency.emergency && report.emergencyContact != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Təcili vəziyyət! Qaynar xətt: ${report.emergencyContact}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Return to map
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xəritəyə qayıt və İzlə'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Mətn ilə Problemi Bildir',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline Warning Banner
            if (_isOffline)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Oflayn Rejim: İnternet yoxdur. Bildiriş telefonda saxlanılacaq və şəbəkə bərpa olunan kimi avtomatik göndəriləcək.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'Problemi yazılı olaraq təsvir edin:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),

            // Text input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Məs: Qaz borusu partlayıb və ya zibil qutuları dolub...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick suggestion chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickChips.map((chipText) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(chipText, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      onPressed: () {
                        _textController.text = chipText;
                        setState(() {});
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Location card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.critical, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Müəyyən edilmiş Konum:',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            if (_isLastKnownLocation) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Son məlum',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _detectedAddress,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // AI Analyze or Offline Submit Button
            if (_isOffline) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _textController.text.trim().isEmpty ? null : _submitOfflineReport,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text(
                    'Oflayn Saxla və Göndərməyi Gözlət',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _textController.text.trim().isEmpty || _isAnalyzing ? null : _analyzeText,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _isAnalyzing ? 'Süni İntellekt analiz edir...' : 'Süni İntellekt ilə Təhlil Et',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // AI Result Card
            if (_aiResult != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Təhlili və Quruma Yönləndirmə',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _aiResult!.confidence < 0.6
                                ? Colors.grey.withValues(alpha: 0.15)
                                : AppColors.airGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_aiResult!.confidence * 100).toInt()}% Uyğunluq',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _aiResult!.confidence < 0.6 ? Colors.grey : AppColors.airGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      _aiResult!.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _aiResult!.detectedProblem,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, size: 18, color: AppColors.truckBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aidiyyəti Qurum: ${_aiResult!.targetDepartment}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                    if (_aiResult!.urgency == ReportUrgency.emergency) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'TƏCİLİ HAL! Qaynar xətt: ${_aiResult!.emergencyContact ?? "112"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Final Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitReport,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Müraciəti Təsdiqlə və Xəritədə Qeyd Et',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
