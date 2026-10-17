import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ClusterPin extends StatelessWidget {
  final BinCluster cluster;
  final VoidCallback? onTap;

  const ClusterPin({super.key, required this.cluster, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = cluster.statusColor;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _TrianglePainter(color),
          ),
        ],
      ),
    );
  }
}

class TruckPin extends StatelessWidget {
  final CollectionTruck truck;
  final VoidCallback? onTap;

  const TruckPin({super.key, required this.truck, this.onTap});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.truckBlue;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          CustomPaint(
            size: const Size(8, 5),
            painter: _TrianglePainter(color),
          ),
        ],
      ),
    );
  }
}

class DepotPin extends StatelessWidget {
  final VoidCallback? onTap;

  const DepotPin({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.depotSlate;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _TrianglePainter(color),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
