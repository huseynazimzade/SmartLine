import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/location_service.dart';
import '../../services/network_service.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMapFocusOnResume();
    });
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
    }
  }

  void _checkMapFocusOnResume() {
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
    if (reportsProvider.mapFocusCoordinate != null) {
      _openMapSheet(focusCoordinate: reportsProvider.mapFocusCoordinate, report: reportsProvider.selectedReport);
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
                );
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
                );
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
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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

  /// Interactive Map Modal Sheet to view city map with reported problems
  void _openMapSheet({LatLng? focusCoordinate, ProblemReport? report}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final reportsProvider = Provider.of<ReportsProvider>(context);
          final allReports = reportsProvider.reports;
          final targetCoord = focusCoordinate ?? _userPosition;

          final markers = <Marker>[
            // User current location marker
            Marker(
              point: _userPosition,
              width: 50,
              height: 50,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),

            // Report markers
            for (final rep in allReports)
              Marker(
                point: rep.coordinate,
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () {
                    _showReportDetailsModal(rep);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: rep.isResolved
                            ? AppColors.primary
                            : (rep.status == ReportStatus.pending
                                ? AppColors.warning
                                : (rep.status == ReportStatus.unresolved
                                    ? const Color(0xFFE11D48)
                                    : AppColors.truckBlue)),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (rep.isResolved ? AppColors.primary : AppColors.warning)
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        rep.isResolved
                            ? Icons.check_circle_rounded
                            : (rep.status == ReportStatus.pending
                                ? Icons.cloud_off_rounded
                                : Icons.warning_amber_rounded),
                        size: 22,
                        color: rep.isResolved ? AppColors.primary : AppColors.critical,
                      ),
                    ),
                  ),
                ),
              ),
          ];

          return FractionallySizedBox(
            heightFactor: 0.88,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: targetCoord,
                        initialZoom: 14.5,
                        minZoom: 11.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartline.app',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),

                    // Top Drag Bar & Close
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Bakı Şəhər Xəritəsi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FloatingActionButton.small(
                              heroTag: 'close_map_sheet',
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textDark,
                              elevation: 4,
                              onPressed: () => Navigator.pop(ctx),
                              child: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
            const SizedBox(height: 10),
            Text(
              report.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
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
          // 3-dots Menu Button on top right
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Network / AI Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: NetworkService.instance.isConnected
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: NetworkService.instance.isConnected
                          ? const Color(0xFFA5D6A7)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: NetworkService.instance.isConnected
                              ? const Color(0xFF28A745)
                              : const Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NetworkService.instance.isConnected
                            ? 'Şəbəkə aktivdir • AI Təhlil hazır'
                            : 'Oflayn rejim • Müraciətlər telefonda saxlanır',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NetworkService.instance.isConnected
                              ? const Color(0xFF1E7E34)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Current GPS Location Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _userAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _fetchLocation,
                        child: _isLoadingLocation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // 3. Central Title: "Problemi bildir"
                const Text(
                  'Problemi bildir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Ətrafınızdakı zibil, su, işıq, yol və ya digər kommunal nasazlığı bildirmək üçün düyməyə toxunun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // 4. THE PROMINENT GREEN CIRCULAR BUTTON IN THE CENTER WITH WHITE "+"
                GestureDetector(
                  onTap: _openProblemPicker,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF28A745),
                          Color(0xFF1E7E34),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF28A745).withValues(alpha: 0.38),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(0xFF28A745).withValues(alpha: 0.16),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 54,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // 5. Past Reports Quick Access Card
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsHistoryView()),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF28A745),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Müraciətlərim və Statuslar',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                allReports.isEmpty
                                    ? 'Hələ müraciətiniz yoxdur'
                                    : (activeCount > 0
                                        ? '$activeCount aktiv problem baxılır • Tarixçə'
                                        : '${allReports.length} müraciət qeydə alınıb • Həll olunub'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 6. View City Map Card
                InkWell(
                  onTap: () => _openMapSheet(),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: AppColors.truckBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Canlı Bakı Xəritəsi',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Problemləri və məkanınızı xəritədə işarələnmiş görün',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
