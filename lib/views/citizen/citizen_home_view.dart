import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'citizen_settings_view.dart';
import 'photo_problem_view.dart';
import 'reports_history_view.dart';
import 'text_problem_view.dart';
import 'voice_problem_view.dart';

class CitizenHomeView extends StatefulWidget {
  const CitizenHomeView({super.key});

  @override
  State<CitizenHomeView> createState() => _CitizenHomeViewState();
}

class _CitizenHomeViewState extends State<CitizenHomeView> {
  final MapController _mapController = MapController();
  LatLng _userPosition = const LatLng(40.3725, 49.8400); // Default Baku Nizami St.
  String _userAddress = 'Nizami küçəsi, Səbail rayonu, Bakı';
  bool _isLoadingLocation = false;
  ProblemReport? _selectedReportOnMap;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = loc.coordinate;
        _userAddress = loc.address;
        _isLoadingLocation = false;
      });
      _mapController.move(_userPosition, 14.5);
    }
  }

  /// Opens the 3-option problem reporting modal
  void _openProblemPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Problemi bildir',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aşağıdakı 3 üsuldan biri ilə problemi daxil edin. Süni İntellekt (AI) problemi analiz edib yerinizi xəritədə işarələyəcək:',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
            ),
            const SizedBox(height: 20),

            // Option 1: Şəkil ilə problemi bildir
            _submissionOption(
              icon: Icons.photo_camera_rounded,
              color: AppColors.primary,
              title: 'Şəkil ilə problemi bildir',
              subtitle: 'Kamera və ya qalereyadan foto çəkin, AI qəzanı dərhal tanısın',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhotoProblemView()),
                ).then((_) => _checkMapFocus());
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Səs ilə problemi bildir
            _submissionOption(
              icon: Icons.mic_rounded,
              color: AppColors.fabricPurple,
              title: 'Səs ilə problemi bildir',
              subtitle: 'Problemi danışaraq izah edin, AI səsinizi mətnə çevirib təhlil etsin',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoiceProblemView()),
                ).then((_) => _checkMapFocus());
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Mətn ilə problemi bildir
            _submissionOption(
              icon: Icons.edit_note_rounded,
              color: AppColors.truckBlue,
              title: 'Mətn ilə problemi bildir',
              subtitle: 'Müşahidə etdiyiniz nasazlığı yazın, AI aidiyyəti qurumu müəyyən etsin',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TextProblemView()),
                ).then((_) => _checkMapFocus());
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _checkMapFocus() {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    if (reportsProvider.mapFocusCoordinate != null) {
      _mapController.move(reportsProvider.mapFocusCoordinate!, 15.5);
      if (reportsProvider.selectedReport != null) {
        setState(() {
          _selectedReportOnMap = reportsProvider.selectedReport;
        });
      }
    }
  }

  Widget _submissionOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDetailsModal(ProblemReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Resolution Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: report.isResolved
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        report.isResolved ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 16,
                        color: report.isResolved ? AppColors.primary : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.resolutionStatusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: report.isResolved ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              '№: ${report.id} • ${report.address}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const Divider(height: 24),

            // Current Stage
            const Text(
              'Cari Aşama / Mərhələ:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.linear_scale_rounded, color: AppColors.truckBlue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.currentStage.label,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Text(
                          report.currentStage.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Target Department
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aidiyyəti Qurum: ${report.targetDepartment}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsHistoryView()),
                  );
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('Bütün müraciət tarixçəsini aç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final allReports = reportsProvider.reports;
    final activeCount = allReports.where((r) => !r.isResolved).length;

    // Build Map Markers
    final markers = <Marker>[
      // User GPS Location Marker
      Marker(
        point: _userPosition,
        width: 60,
        height: 60,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const Text(
              'Siz',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                backgroundColor: Colors.white70,
              ),
            ),
          ],
        ),
      ),

      // Problem Markers on the Map!
      for (final report in allReports)
        Marker(
          point: report.coordinate,
          width: 52,
          height: 52,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedReportOnMap = report);
              _showReportDetailsModal(report);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: report.isResolved ? AppColors.primary : AppColors.critical,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (report.isResolved ? AppColors.primary : AppColors.critical)
                        .withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  report.isResolved
                      ? Icons.check_circle_rounded
                      : (report.inputType == ReportInputType.photo
                          ? Icons.camera_alt_rounded
                          : report.inputType == ReportInputType.voice
                              ? Icons.mic_rounded
                              : Icons.warning_amber_rounded),
                  size: 24,
                  color: report.isResolved ? AppColors.primary : AppColors.critical,
                ),
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // App Logo (Frame 12.png)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Image.asset(
                  'assets/images/Frame 12.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salam, ${auth.currentUser?.username ?? "Hörmətli Sakin"} 👋',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'Bakı Ağıllı Şəhər • Sakin Portalı',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 3-dots Menu Button on the top right
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textDark, size: 28),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsHistoryView()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenSettingsView()),
                );
              } else if (value == 'switch_driver') {
                auth.switchRole(UserRole.driver);
              } else if (value == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Keçmiş müraciətlər',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, color: AppColors.truckBlue, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Ayarlar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'switch_driver',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_rounded, color: AppColors.fabricPurple, size: 20),
                    SizedBox(width: 12),
                    Text('Sürücü rejiminə keç'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.critical, size: 20),
                    SizedBox(width: 12),
                    Text('Çıxış', style: TextStyle(color: AppColors.critical)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Map of Baku with Problem Markers
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition,
              initialZoom: 14.5,
              minZoom: 11.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                if (_selectedReportOnMap != null) {
                  setState(() => _selectedReportOnMap = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartline.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Top Location Bar & Active Issues Pill
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cari Məkanınız',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                ),
                                Text(
                                  _userAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                            onPressed: _fetchLocation,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick chip showing past reports status
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportsHistoryView()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: activeCount > 0 ? AppColors.warning : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              activeCount > 0
                                  ? '$activeCount aktiv problem baxılır • Tarixçəyə bax'
                                  : 'Bütün müraciətlər həll olunub • Tarixçəyə bax',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Re-Center Button
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'recenter_gps',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () {
                _mapController.move(_userPosition, 15.0);
              },
              child: const Icon(Icons.gps_fixed_rounded),
            ),
          ),

          // 4. THE PROMINENT "+" BUTTON WITH "Problemi bildir" TEXT!
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prominent Large Button: + Problemi bildir
                  GestureDetector(
                    onTap: _openProblemPicker,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF28A745), Color(0xFF1E7E34)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            '+ Problemi bildir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Şəkil, səs və ya mətnlə problemi bildirin, süni intellekt təyin etsin',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
