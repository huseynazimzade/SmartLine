import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/reports_provider.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class VoiceProblemView extends StatefulWidget {
  const VoiceProblemView({super.key});

  @override
  State<VoiceProblemView> createState() => _VoiceProblemViewState();
}

class _VoiceProblemViewState extends State<VoiceProblemView> with SingleTickerProviderStateMixin {
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

  final List<String> _sampleVoicePhrases = [
    'Salam, bizim məhəllədə zibil qutusu dolub daşıb, üfunət iyi yayılır, təcili zibil maşını göndərin.',
    'Salam, Sahil parkının yaxınlığında su borusu partlayıb, asfaltın altından güclü su axır.',
    'Axşamınız xeyir, küçə fənərləri iki gündür yanmır, zülmət qaranlıqdır, elektrik naqili qırılıb.',
    'Yolda böyük çuxur əmələ gəlib, maşınların təkərləri zədələnir, təmir lazımdır.',
  ];

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
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _toggleListening({String? simulatedSpeech}) {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening(simulatedSpeech: simulatedSpeech);
    }
  }

  void _startListening({String? simulatedSpeech}) {
    setState(() {
      _isListening = true;
      _recordingSeconds = 0;
      _transcribedText = '';
      _aiResult = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingSeconds++);
      if (_recordingSeconds >= 4) {
        _stopListening(simulatedSpeech: simulatedSpeech);
      }
    });
  }

  Future<void> _stopListening({String? simulatedSpeech}) async {
    _timer?.cancel();
    setState(() {
      _isListening = false;
      _isAnalyzing = true;
      _transcribedText = simulatedSpeech ?? _sampleVoicePhrases.first;
    });

    final result = await AiService.analyzeText(_transcribedText);

    if (mounted) {
      setState(() {
        _aiResult = result;
        _isAnalyzing = false;
      });
    }
  }

  void _submitReport() {
    if (_aiResult == null) return;

    final report = ProblemReport(
      title: _aiResult!.title,
      description: _transcribedText,
      inputType: ReportInputType.voice,
      detectedProblem: _aiResult!.detectedProblem,
      aiConfidence: _aiResult!.confidence,
      aiCategory: _aiResult!.category,
      targetDepartment: _aiResult!.targetDepartment,
      urgency: _aiResult!.urgency,
      status: ReportStatus.pending,
      currentStage: ReportStage.classified,
      address: _detectedAddress,
      latitude: _detectedLat,
      longitude: _detectedLon,
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
          children: [
            const SizedBox(height: 8),
            Text(
              _isListening
                  ? 'Dinlənilir... Danışın... (${_recordingSeconds}s)'
                  : _isAnalyzing
                      ? '🧠 Süni İntellekt səsi dinləyir və təhlil edir...'
                      : 'Problemi səsli olaraq danışın',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI nitqi mətnə çevirərək problemin növünü və aidiyyəti dövlət qurumunu avtomatik təyin edəcək.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // Pulsing Disc
            Center(
              child: GestureDetector(
                onTap: () => _toggleListening(),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final scale = _isListening ? 1.0 + _animController.value * 0.15 : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? AppColors.critical : AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? AppColors.critical : AppColors.primary)
                                  .withValues(alpha: 0.35),
                              blurRadius: _isListening ? 28 : 16,
                              spreadRadius: _isListening ? 8 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isListening ? 'Dayandırmaq üçün toxunun' : 'Danışmaq üçün mikrofona toxunun',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Location Box
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
                        const Text(
                          'Müəyyən edilmiş Konum:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
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
            const SizedBox(height: 20),

            // Quick Samples for test
            if (!_isListening && _aiResult == null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Və ya hazır səs nümunəsini sınayın:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              ..._sampleVoicePhrases.map((phrase) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _toggleListening(simulatedSpeech: phrase),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                phrase,
                                style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],

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
                        const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Səs Təhlili və AI Nəticəsi',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.airGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_aiResult!.confidence * 100).toInt()}% Tanındı',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.airGreen),
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
