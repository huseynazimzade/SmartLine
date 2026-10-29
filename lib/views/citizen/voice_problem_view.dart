import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../models/models.dart';
import '../../providers/reports_provider.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/network_service.dart';
import '../../services/offline_queue_service.dart';
import '../../theme/app_theme.dart';

class VoiceProblemView extends StatefulWidget {
  const VoiceProblemView({super.key});

  @override
  State<VoiceProblemView> createState() => _VoiceProblemViewState();
}

class _VoiceProblemViewState extends State<VoiceProblemView> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedAudioPath;

  bool _isListening = false;
  bool _isAnalyzing = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String _transcribedText = '';
  AiAnalysisResult? _aiResult;
  late AnimationController _animController;

  double _detectedLat = 40.3725;
  double _detectedLon = 49.8400;
  String _detectedAddress = 'Nizami küçəsi 48, Səbail rayonu, Bakı';
  double _detectedAccuracy = 5.0;
  bool _isLastKnownLocation = false;

  final List<String> _sampleVoicePhrases = [
    'Qaz borusu partlayıb, həyətdə kəskin qaz iyi yayılır, təcili kömək lazımdır.',
    'Salam, Sahil parkının yaxınlığında su borusu partlayıb, asfaltın altından güclü su axır.',
    'Axşamınız xeyir, dirəkdən açıq naqil sallanır, qığılcım saçır, təhlükəlidir.',
    'Salam, bizim məhəllədə zibil qutusu dolub daşıb, üfunət iyi yayılır, təcili zibil maşını göndərin.',
  ];

  bool get _isOffline => !NetworkService.instance.isConnected;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
    _timer?.cancel();
    _animController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _toggleListening({String? simulatedSpeech}) {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening(simulatedSpeech: simulatedSpeech);
    }
  }

  Future<void> _startListening({String? simulatedSpeech}) async {
    if (simulatedSpeech != null) {
      if (_isOffline) {
        setState(() {
          _isListening = false;
          _transcribedText = simulatedSpeech;
          _aiResult = null;
        });
        return;
      }

      setState(() {
        _isListening = false;
        _isAnalyzing = true;
        _transcribedText = simulatedSpeech;
        _aiResult = null;
      });

      final result = await AiService.analyzeVoice(simulatedSpeech: simulatedSpeech);

      if (mounted) {
        setState(() {
          _aiResult = result;
          _transcribedText = result.transcribedText ?? simulatedSpeech;
          _isAnalyzing = false;
        });
      }
      return;
    }

    // Start real audio recording
    setState(() {
      _isListening = true;
      _recordingSeconds = 0;
      _transcribedText = '';
      _aiResult = null;
      _recordedAudioPath = null;
    });

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/smartline_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        _recordedAudioPath = path;
      }
    } catch (e) {
      debugPrint('[VoiceProblemView] Mikrofon xətası: $e');
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingSeconds++);
      if (_recordingSeconds >= 25) {
        _stopListening();
      }
    });
  }

  Future<void> _stopListening() async {
    _timer?.cancel();
    String? finalPath = _recordedAudioPath;

    try {
      if (await _audioRecorder.isRecording()) {
        finalPath = await _audioRecorder.stop() ?? _recordedAudioPath;
      }
    } catch (e) {
      debugPrint('[VoiceProblemView] Dayandırma xətası: $e');
    }

    if (_isOffline) {
      setState(() {
        _isListening = false;
        _transcribedText = 'Səs yazısı tamamlandı (Oflayn saxlandı).';
        _isAnalyzing = false;
      });
      return;
    }

    setState(() {
      _isListening = false;
      _isAnalyzing = true;
    });

    final result = await AiService.analyzeVoice(
      audioPath: finalPath,
    );

    if (mounted) {
      setState(() {
        _aiResult = result;
        _transcribedText = result.transcribedText ?? 'Səs analizi uğurla tamamlandı.';
        _isAnalyzing = false;
      });
    }
  }

  void _submitOfflineReport() {
    final title = _transcribedText.isNotEmpty && !_transcribedText.contains('Oflayn')
        ? (_transcribedText.length > 35 ? '${_transcribedText.substring(0, 35)}...' : _transcribedText)
        : 'Səsli müraciət';

    final report = ProblemReport(
      title: title,
      description: _transcribedText.isNotEmpty ? _transcribedText : 'Səs faylı ilə daxil edilmiş müraciət',
      inputType: ReportInputType.voice,
      voiceAudioPath: _recordedAudioPath,
      detectedProblem: 'İnternet bağlantısı gözlənilir (Səs faylı serverə çatanda AI tərəfindən transkripsiya və analiz ediləcək)',
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
      timestamp: DateTime.now(), // Original recording time
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
              'Qeydiyyat №: ${report.id}\nSəs faylı və orijinal GPS koordinatları telefonda saxlanıldı.',
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
      description: _transcribedText,
      inputType: ReportInputType.voice,
      voiceAudioPath: _recordedAudioPath,
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
              'Səsli Problem Xəritədə İşarələndi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Qeydiyyat №: ${report.id}\nSəsiniz AI vasitəsilə təhlil edildi, konum təyin olundu və "${report.targetDepartment}" idarəsinə göndərildi.',
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
                    const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TƏCİLİ HAL! Qaynar xətt: ${report.emergencyContact}',
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
                  Navigator.pop(context); // Back to map
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
          'Səs ilə Problemi Bildir',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                        'Oflayn Rejim: İnternet yoxdur. Səs yazısı telefonda saxlanılacaq və şəbəkə bərpa olunan kimi avtomatik göndəriləcək.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

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
            const SizedBox(height: 24),

            // Microphone recording sphere
            GestureDetector(
              onTap: () => _toggleListening(),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? AppColors.critical.withValues(alpha: 0.15 + _animController.value * 0.15)
                          : AppColors.fabricPurple.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? AppColors.critical : AppColors.fabricPurple,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? AppColors.critical : AppColors.fabricPurple).withValues(alpha: 0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            Text(
              _isListening
                  ? 'Danışın... ($_recordingSeconds saniyə)'
                  : (_recordedAudioPath != null || _transcribedText.isNotEmpty)
                      ? 'Yazıldı. Yenidən danışmaq üçün toxunun'
                      : 'Danışmaq üçün mikrofon ikonuna toxunun',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isListening ? AppColors.critical : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Problemin növünü, ünvanını və ya baş verən qəzanı izah edin',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // If offline, provide direct save button
            if (_isOffline && (_recordedAudioPath != null || _transcribedText.isNotEmpty)) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitOfflineReport,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text(
                    'Oflayn Saxla və Göndərməyi Gözlət',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sample Voice Phrases Chips
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'və ya sınaq cümlələrindən birini seçin:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 8),

            Column(
              children: _sampleVoicePhrases.map((phrase) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _startListening(simulatedSpeech: phrase),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_outline_rounded, size: 20, color: AppColors.fabricPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phrase,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Loading AI
            if (_isAnalyzing) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.fabricPurple.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: AppColors.fabricPurple, strokeWidth: 2.5),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Səs transkripsiya edilir və AI təhlili aparılır...',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.fabricPurple),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // AI Result Card
            if (_aiResult != null && !_isOffline) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.fabricPurple.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.fabricPurple.withValues(alpha: 0.08),
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
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.fabricPurple, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Səs Təhlilinin Nəticəsi',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.fabricPurple),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _aiResult!.confidence < 0.6
                                ? Colors.grey.withValues(alpha: 0.15)
                                : AppColors.airGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_aiResult!.confidence * 100).toInt()}% Tanındı',
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
                    const Text(
                      'TRANSKRİPSİYA:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"$_transcribedText"',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
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
                            'Yönləndirilir: ${_aiResult!.targetDepartment}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
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

              // Submit Button
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
