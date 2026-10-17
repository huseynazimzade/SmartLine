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
  String _filter = 'all'; // 'all', 'resolved', 'active'

  void _showReportDetail(BuildContext context, ProblemReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
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
                    // Top Bar with Resolution Badge
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
                                report.isResolved ? 'HƏLL OLUNDU' : 'HƏLL OLUNMAYIB (AKTİV)',
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
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Müraciət №: ${report.id} • ${DateFormat('dd MMM yyyy, HH:mm').format(report.timestamp)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const Divider(height: 24),

                    // Stage Progress Timeline (Hansı aşamada olduğu)
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
                                '${(report.aiConfidence * 100).toInt()}% uyğunluq',
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

                    // Location
                    _detailTile(
                      icon: Icons.location_on_rounded,
                      color: AppColors.critical,
                      title: 'Məkan və Xəritə Koordinatı',
                      value: '${report.address}\n(${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)})',
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

                    // Interactive Status Switcher (for demoing resolve/inProgress)
                    OutlinedButton.icon(
                      onPressed: () {
                        final newStatus = report.isResolved ? ReportStatus.inProgress : ReportStatus.resolved;
                        final newStage = report.isResolved ? ReportStage.inProgress : ReportStage.resolved;
                        Provider.of<ReportsProvider>(context, listen: false)
                            .updateReportStatus(report.id, newStatus, newStage);
                        Navigator.pop(ctx);
                      },
                      icon: Icon(
                        report.isResolved ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
                        color: report.isResolved ? AppColors.warning : AppColors.primary,
                      ),
                      label: Text(
                        report.isResolved ? 'Statusu "İcrada" olaraq dəyiş' : 'Statusu "Həll olundu" olaraq qeyd et',
                        style: TextStyle(
                          color: report.isResolved ? AppColors.warning : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: report.isResolved ? AppColors.warning : AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildStageStepper(ProblemReport report) {
    final stages = [
      {'stage': ReportStage.received, 'title': 'Qəbul edildi', 'sub': 'Müraciət qeydə alındı'},
      {'stage': ReportStage.classified, 'title': 'AI Təhlili & Yönləndirmə', 'sub': 'Quruma göndərildi'},
      {'stage': ReportStage.inProgress, 'title': 'İcrada', 'sub': 'Briqada əraziyə cəlb olunub'},
      {'stage': ReportStage.resolved, 'title': 'Həll olundu', 'sub': 'İşlər tamamlandı'},
    ];

    int currentIndex = 0;
    if (report.status == ReportStatus.resolved) {
      currentIndex = 3;
    } else if (report.status == ReportStatus.inProgress) {
      currentIndex = 2;
    } else {
      currentIndex = 1;
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? (report.isResolved && index == 3 ? AppColors.primary : AppColors.truckBlue) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                  ),
                ),
                if (index < stages.length - 1)
                  Container(
                    width: 2,
                    height: 24,
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
                      fontSize: 13,
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

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final allReports = reportsProvider.reports;

    final filteredReports = allReports.where((r) {
      if (_filter == 'resolved') return r.isResolved;
      if (_filter == 'active') return !r.isResolved;
      return true;
    }).toList();

    final resolvedCount = allReports.where((r) => r.isResolved).length;
    final activeCount = allReports.where((r) => !r.isResolved).length;

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
          // Filter Chips (Hamısı, Həll olunub, Həll olunmayıb)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('Hamısı (${allReports.length})', 'all'),
                const SizedBox(width: 8),
                _filterChip('Həll olunmayıb ($activeCount)', 'active'),
                const SizedBox(width: 8),
                _filterChip('Həll olundu ($resolvedCount)', 'resolved'),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.isResolved
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : Colors.grey.withValues(alpha: 0.2),
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
                                  // Top row: ID and Resolution Badge
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

                                      // Clearly shows "problemin həll olub-olmadığı"
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.isResolved
                                              ? AppColors.primary.withValues(alpha: 0.12)
                                              : AppColors.warning.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              item.isResolved
                                                  ? Icons.check_circle_rounded
                                                  : Icons.hourglass_top_rounded,
                                              size: 13,
                                              color: item.isResolved ? AppColors.primary : AppColors.warning,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.isResolved ? 'Həll olundu' : 'Həll olunmayıb',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: item.isResolved ? AppColors.primary : AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ),
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

                                  // Stage info (Hansı aşamada olduğu)
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
