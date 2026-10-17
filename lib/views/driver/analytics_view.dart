import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/waste_provider.dart';
import '../../theme/app_theme.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final waste = Provider.of<WasteProvider>(context);

    int totalBins = 0;
    int mixedBins = 0;
    int plasticBins = 0;
    int clothesBins = 0;

    for (var c in waste.clusters) {
      for (var b in c.bins) {
        totalBins++;
        if (b.type == BinType.mixed) mixedBins++;
        if (b.type == BinType.plastic) plasticBins++;
        if (b.type == BinType.clothes) clothesBins++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Statistical Insights',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF238B45), Color(0xFF1B6A34)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pie_chart_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Collection efficiency is up 12% this week',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Baku Eco-fleet optimization active across 24 zones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Metrics Grid
          const Text(
            'City-Wide Metrics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _metricTile(
                title: 'Total Active Bins',
                value: '$totalBins',
                icon: Icons.delete_outline_rounded,
                color: AppColors.primary,
              ),
              _metricTile(
                title: 'Active Trucks',
                value: '${waste.trucks.length}',
                icon: Icons.local_shipping_outlined,
                color: AppColors.truckBlue,
              ),
              _metricTile(
                title: 'Depot Stations',
                value: '${waste.depots.length}',
                icon: Icons.home_work_outlined,
                color: AppColors.depotSlate,
              ),
              _metricTile(
                title: 'CO₂ Avoided',
                value: '428 kg',
                icon: Icons.eco_outlined,
                color: AppColors.airGreen,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bin Categories Breakdown
          const Text(
            'Bin Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _categoryRow(
                  label: 'General Waste',
                  count: mixedBins,
                  total: totalBins,
                  color: AppColors.primary,
                  icon: Icons.delete_rounded,
                ),
                const Divider(height: 24),
                _categoryRow(
                  label: 'Plastic & Metal',
                  count: plasticBins,
                  total: totalBins,
                  color: AppColors.warning,
                  icon: Icons.local_drink_rounded,
                ),
                const Divider(height: 24),
                _categoryRow(
                  label: 'Clothes & Fabric',
                  count: clothesBins,
                  total: totalBins,
                  color: AppColors.fabricPurple,
                  icon: Icons.checkroom_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Text(
              '$count bins (${(ratio * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
