import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/reports_provider.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
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

  void _submitReport() {
    if (_aiResult == null) return;

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
            // Photo Preview Frame
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageFile != null && !kIsWeb)
                    Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: const Color(0xFF1E293B),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 56, color: Colors.white54),
                          SizedBox(height: 10),
                          Text(
                            'Şəkil AI analizi üçün hazırdır',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  // Scanning radar overlay if analyzing
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 14),
                          Text(
                            '🧠 AI şəkli analiz edir...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Problem növü və qurum təyin edilir...',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Determined Location Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.critical, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Müəyyən edilmiş Konum:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            if (_isLoadingLocation) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _detectedAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Text(
                          'Koordinat: ${_detectedLat.toStringAsFixed(4)}, ${_detectedLon.toStringAsFixed(4)} (Xəritədə qeyd olunacaq)',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // AI Analysis Output Card
            if (_aiResult != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
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
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Süni İntellekt Təsbit Nəticəsi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.airGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(_aiResult!.confidence * 100).toInt()}% Uyğunluq',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.airGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      _aiResult!.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _aiResult!.detectedProblem,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target Department
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded, size: 18, color: AppColors.truckBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yönləndirilən Qurum: ${_aiResult!.targetDepartment}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Optional note
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
