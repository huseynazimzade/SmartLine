import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/reports_provider.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/network_service.dart';
import '../../services/offline_queue_service.dart';
import '../../theme/app_theme.dart';

class PhotoProblemView extends StatefulWidget {
  const PhotoProblemView({super.key});

  @override
  State<PhotoProblemView> createState() => _PhotoProblemViewState();
}

class _PhotoProblemViewState extends State<PhotoProblemView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isAnalyzing = false;
  bool _isLoadingLocation = false;
  AiAnalysisResult? _aiResult;
  final TextEditingController _notesController = TextEditingController();

  double _detectedLat = 40.3725;
  double _detectedLon = 49.8400;
  String _detectedAddress = 'Nizami küçəsi 48, Səbail rayonu, Bakı';
  double _detectedAccuracy = 5.0;
  bool _isLastKnownLocation = false;

  bool get _isOffline => !NetworkService.instance.isConnected;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndPickImage();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndPickImage() async {
    setState(() => _isLoadingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _detectedLat = loc.latitude;
        _detectedLon = loc.longitude;
        _detectedAddress = loc.address;
        _detectedAccuracy = loc.accuracy;
        _isLastKnownLocation = loc.isLastKnownLocation;
        _isLoadingLocation = false;
      });
    }
    _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = picked;
          _isAnalyzing = true;
          _aiResult = null;
        });
        _runAiAnalysis();
      } else if (_imageFile == null) {
        // Fallback simulation if camera closed without capturing
        setState(() {
          _isAnalyzing = true;
          _aiResult = null;
        });
        _runAiAnalysis();
      }
    } catch (e) {
      debugPrint('Image picking error: $e');
      setState(() {
        _isAnalyzing = true;
        _aiResult = null;
      });
      _runAiAnalysis();
    }
  }

  Future<void> _runAiAnalysis() async {
    if (_isOffline) {
      setState(() => _isAnalyzing = false);
      return;
    }

    final result = await AiService.analyzePhoto(
      photoPath: _imageFile?.path,
      optionalContext: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _aiResult = result;
        _isAnalyzing = false;
      });
    }
  }

  void _submitOfflineReport() {
    final report = ProblemReport(
      title: _notesController.text.trim().isEmpty ? 'Şəkil ilə bildirilən problem' : _notesController.text.trim(),
      description: _notesController.text.trim().isEmpty
          ? 'Şəkil ilə çəkilmiş kommunal problem (şəbəkə bərpa olunduqda AI analizi aparılacaq)'
          : _notesController.text.trim(),
      inputType: ReportInputType.photo,
      photoPath: _imageFile?.path,
      detectedProblem: 'İnternet bağlantısı gözlənilir (Şəkil serverə çatdıqda AI tərəfindən analiz ediləcək)',
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
      timestamp: DateTime.now(), // Original capture time
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
              'Qeydiyyat №: ${report.id}\nFoto və orijinal GPS koordinatları telefonda saxlanıldı.',
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
                  Navigator.pop(context); // Return to home map
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
      description: _notesController.text.trim().isEmpty
          ? _aiResult!.detectedProblem
          : _notesController.text.trim(),
      inputType: ReportInputType.photo,
      photoPath: _imageFile?.path,
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
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Qeydiyyat №: ${report.id}\n📍 Məkan təyin olundu və xəritədə qeyd edildi.\n🏢 "${report.targetDepartment}" idarəsinə yönləndirildi.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
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
                  Navigator.pop(context); // Return to home map
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          'Şəkil ilə Problemi Bildir',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
            tooltip: 'Qalereyadan seç',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
            tooltip: 'Yenidən çək',
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Offline Banner
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
                        'Oflayn Rejim: İnternet yoxdur. Foto telefonda saxlanılacaq və şəbəkə bərpa olunan kimi avtomatik göndəriləcək.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textDark, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Image Preview Card
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageFile != null
                  ? Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          'Şəkil çəkilmədi və ya seçilmədi',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                          label: const Text('Şəkil çək'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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
                          _isLoadingLocation ? 'Lokasiya təyin edilir...' : _detectedAddress,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // If offline, show direct submit button
            if (_isOffline) ...[
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Əlavə qeydiniz (istəyə görə)',
                  hintText: 'Məs: bina 14 qarşısındakı meydança...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 20),
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
            ],

            // AI Vision Analysis loading
            if (_isAnalyzing && !_isOffline) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Süni İntellekt Analiz Edir...',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                          Text(
                            'Görüntü skan edilir, problem növü və aidiyyəti idarə təyin olunur',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // AI Result Card
            if (_aiResult != null && !_isOffline) ...[
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
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'AI Görüntü Analizi Nəticəsi',
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
                            'Yönləndirilən Qurum: ${_aiResult!.targetDepartment}',
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
              const SizedBox(height: 18),

              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Əlavə qeydiniz (istəyə görə)',
                  hintText: 'Məs: bina 14 qarşısındakı meydança...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 22),

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
