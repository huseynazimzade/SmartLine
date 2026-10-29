import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/reports_provider.dart';
import '../../theme/app_theme.dart';

class ReportsHistoryView extends StatefulWidget {
  const ReportsHistoryView({super.key});

  @override
  State<ReportsHistoryView> createState() => _ReportsHistoryViewState();
}

class _ReportsHistoryViewState extends State<ReportsHistoryView> {
  String _filter = 'all'; // 'all', 'pending', 'sent', 'resolved', 'unresolved'

  void _showReportDetail(BuildContext context, ProblemReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.90,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    // Top Bar with Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(report.status),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Müraciət №: ${report.id}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const Divider(height: 24),

                    // Emergency Banner if applicable
                    if (report.urgency == ReportUrgency.emergency) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TƏCİLİ TƏHLÜKƏLİ VƏZİYYƏT',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qaynar Xətt: ${report.emergencyContact ?? "112"} ilə təcili əlaqə saxlayın.',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Stage Progress Timeline
                    const Text(
                      'İCRA MƏRHƏLƏSİ / AŞAMA:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStageStepper(report),

                    const SizedBox(height: 20),

                    // AI Insights
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Süni İntellekt Təhlili',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                report.aiConfidence > 0
                                    ? '${(report.aiConfidence * 100).toInt()}% uyğunluq'
                                    : 'Gözləmədə',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            report.detectedProblem,
                            style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Department
                    _detailTile(
                      icon: Icons.apartment_rounded,
                      color: AppColors.truckBlue,
                      title: 'Cavabdeh Dövlət Qurumu',
                      value: report.targetDepartment,
                    ),
                    const SizedBox(height: 12),

                    // Original Timestamp
                    _detailTile(
                      icon: Icons.access_time_filled_rounded,
                      color: Colors.deepPurple,
                      title: 'ORİJİNAL Qeydiyyat Vaxtı',
                      value: DateFormat('dd MMMM yyyy, HH:mm:ss').format(report.timestamp) +
                          (report.sentAt != null
                              ? '\n(Serverə çatdırıldı: ${DateFormat('dd.MM.yyyy HH:mm:ss').format(report.sentAt!)})'
                              : '\n(Lokal növbədə saxlanılıb, internet gözlənilir)'),
                    ),
                    const SizedBox(height: 12),

                    // Original Location
                    _detailTile(
                      icon: Icons.location_on_rounded,
                      color: AppColors.critical,
                      title: 'ORİJİNAL Məkan və GPS Koordinatları',
                      value: [
                        '${report.address}\nKoordinatlar: (${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)})',
                        if (report.locationAccuracy != null) 'GPS Dəqiqlik: ±${report.locationAccuracy!.toStringAsFixed(1)} m',
                        if (report.isLastKnownLocation) 'Qeyd: Ən son məlum koordinat istifadə edilib',
                      ].join('\n'),
                    ),
                    const SizedBox(height: 12),

                    // Method
                    _detailTile(
                      icon: report.inputType.icon,
                      color: AppColors.fabricPurple,
                      title: 'Müraciət Forması',
                      value: '${report.inputType.label} daxil edilmişdir',
                    ),
                    const SizedBox(height: 20),

                    // Show on Map Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Provider.of<ReportsProvider>(context, listen: false)
                              .setMapFocus(report.coordinate, reportId: report.id);
                          Navigator.pop(context); // Go back to Home Map
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('Xəritədə Bu Nöqtəni Göstər'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Delete Report Button in Detail Modal
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteReport(context, report);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.critical, size: 20),
                        label: const Text(
                          'Müraciəti sil',
                          style: TextStyle(
                            color: AppColors.critical,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.critical, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    switch (status) {
      case ReportStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        icon = Icons.schedule_rounded;
        text = 'Gözləyir (Oflayn)';
        break;
      case ReportStatus.sent:
        bg = AppColors.truckBlue.withValues(alpha: 0.15);
        fg = AppColors.truckBlue;
        icon = Icons.mark_email_read_rounded;
        text = 'Göndərildi';
        break;
      case ReportStatus.inProgress:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade700;
        icon = Icons.engineering_rounded;
        text = 'İcrada';
        break;
      case ReportStatus.resolved:
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        icon = Icons.check_circle_rounded;
        text = 'Həll olundu';
        break;
      case ReportStatus.unresolved:
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        icon = Icons.cancel_rounded;
        text = 'Həll olunmadı';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildStageStepper(ProblemReport report) {
    final stages = [
      {'stage': ReportStage.received, 'title': 'Qəbul edildi', 'sub': 'Sistemə daxil oldu'},
      {'stage': ReportStage.classified, 'title': 'AI Təhlil & Yönləndirmə', 'sub': 'Quruma çatdırıldı'},
      {'stage': ReportStage.inProgress, 'title': 'İcrada', 'sub': 'Briqada ərazidədir'},
      {'stage': ReportStage.resolved, 'title': 'Həll olundu', 'sub': 'İşlər tamamlandı'},
    ];

    int currentIndex = 0;
    if (report.status == ReportStatus.resolved) {
      currentIndex = 3;
    } else if (report.status == ReportStatus.inProgress) {
      currentIndex = 2;
    } else if (report.status == ReportStatus.sent) {
      currentIndex = 1;
    } else {
      currentIndex = 0;
    }

    return Column(
      children: List.generate(stages.length, (index) {
        final isDone = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final item = stages[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDone ? (report.isResolved && index == 3 ? AppColors.primary : AppColors.truckBlue) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                  ),
                ),
                if (index < stages.length - 1)
                  Container(
                    width: 2,
                    height: 22,
                    color: index < currentIndex ? AppColors.truckBlue : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isDone ? AppColors.textDark : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    item['sub'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? AppColors.truckBlue : AppColors.textMuted,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDeleteReport(BuildContext context, ProblemReport report) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dlgContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.critical, size: 28),
            SizedBox(width: 10),
            Text(
              'Müraciəti sil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu müraciəti silmək istədiyinizdən əminsiniz?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              '«${report.title}» (${report.id}) müraciəti tarixçədən həmişəlik silinəcək.',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.35),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext, false),
            child: const Text(
              'Ləğv et',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dlgContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Bəli, sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      if (context.mounted) {
        final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
        await reportsProvider.deleteReport(report.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('«${report.id}» nömrəli müraciət uğurla silindi.'),
              backgroundColor: AppColors.textDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final allReports = reportsProvider.reports;

    final filteredReports = allReports.where((r) {
      if (_filter == 'pending') return r.status == ReportStatus.pending;
      if (_filter == 'sent') return r.status == ReportStatus.sent || r.status == ReportStatus.inProgress;
      if (_filter == 'resolved') return r.status == ReportStatus.resolved;
      if (_filter == 'unresolved') return r.status == ReportStatus.unresolved;
      return true;
    }).toList();

    final pendingCount = allReports.where((r) => r.status == ReportStatus.pending).length;
    final sentCount = allReports.where((r) => r.status == ReportStatus.sent || r.status == ReportStatus.inProgress).length;
    final resolvedCount = allReports.where((r) => r.status == ReportStatus.resolved).length;
    final unresolvedCount = allReports.where((r) => r.status == ReportStatus.unresolved).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Keçmiş Müraciətlər',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips (Hamısı, Gözləyir, Göndərildi, Həll olundu, Həll olunmadı)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('Hamısı (${allReports.length})', 'all'),
                const SizedBox(width: 8),
                _filterChip('Gözləyir ($pendingCount)', 'pending'),
                const SizedBox(width: 8),
                _filterChip('Göndərildi ($sentCount)', 'sent'),
                const SizedBox(width: 8),
                _filterChip('Həll olundu ($resolvedCount)', 'resolved'),
                if (unresolvedCount > 0) ...[
                  const SizedBox(width: 8),
                  _filterChip('Həll olunmadı ($unresolvedCount)', 'unresolved'),
                ],
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: filteredReports.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 56, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'Bu bölmədə müraciət tapılmadı',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredReports.length,
                    itemBuilder: (ctx, index) {
                      final item = filteredReports[index];

                      return Dismissible(
                        key: ValueKey('report_${item.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDeleteReport(context, item),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.critical,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sil',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: item.isResolved
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : (item.status == ReportStatus.pending
                                      ? Colors.orange.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2)),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _showReportDetail(context, item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top row: ID and Status Badge + Delete Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(item.inputType.icon, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.id,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            _buildStatusBadge(item.status),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _confirmDeleteReport(context, item),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AppColors.critical,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Title
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // Stage info
                                    Row(
                                      children: [
                                        const Icon(Icons.tune_rounded, size: 14, color: AppColors.truckBlue),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Aşama: ${item.currentStage.label}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.truckBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Address & Department
                                    Text(
                                      '${item.targetDepartment} • ${item.address}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),

                                    // Bottom Row: Date & Action
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('dd.MM.yyyy HH:mm').format(item.timestamp),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        const Row(
                                          children: [
                                            Text(
                                              'Ətraflı & Xəritə',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String title, String filterKey) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = filterKey),
    );
  }
}
