import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/waste_provider.dart';
import '../../theme/app_theme.dart';
import 'map_pins.dart';

class MyRouteView extends StatefulWidget {
  const MyRouteView({super.key});

  @override
  State<MyRouteView> createState() => _MyRouteViewState();
}

class _MyRouteViewState extends State<MyRouteView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final waste = Provider.of<WasteProvider>(context);
    final truck = waste.assignedTruck;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Route Console',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (truck != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.airGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: AppColors.airGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.airGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Map & Console
        Expanded(
          child: truck == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.no_transfer_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No truck assigned.',
                        style: TextStyle(fontSize: 18, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Map view
                    _buildRouteMap(waste, truck),

                    // Floating Bottom Console Card
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Destination',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        truck.status,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Cargo Load',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(truck.capacity * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: truck.capacity > 0.8
                                            ? AppColors.critical
                                            : AppColors.truckBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: truck.capacity.clamp(0.0, 1.0),
                                backgroundColor: Colors.grey.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  truck.capacity > 0.8
                                      ? AppColors.critical
                                      : AppColors.truckBlue,
                                ),
                                minHeight: 10,
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Arrival',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Road Following',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    waste.completeCurrentTask();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRouteMap(WasteProvider waste, CollectionTruck truck) {
    final markers = <Marker>[
      Marker(
        point: truck.coordinate,
        width: 44,
        height: 48,
        child: TruckPin(truck: truck),
      ),
    ];

    final polylines = <Polyline>[];

    if (truck.targetClusterId != null) {
      final cluster = waste.clusters.firstWhere(
        (c) => c.id == truck.targetClusterId,
        orElse: () => waste.clusters.first,
      );
      markers.add(
        Marker(
          point: cluster.coordinate,
          width: 48,
          height: 52,
          child: ClusterPin(cluster: cluster),
        ),
      );

      final List<LatLng> routePoints = truck.routePoints.isNotEmpty
          ? List<LatLng>.from(truck.routePoints)
          : <LatLng>[truck.coordinate, cluster.coordinate];

      polylines.add(
        Polyline(
          points: routePoints,
          color: AppColors.truckBlue,
          strokeWidth: 5.0,
        ),
      );
    } else {
      // Station / Depot target
      final depot = waste.depots.first;
      markers.add(
        Marker(
          point: depot,
          width: 44,
          height: 48,
          child: const DepotPin(),
        ),
      );
      polylines.add(
        Polyline(
          points: [truck.coordinate, depot],
          color: AppColors.truckBlue.withValues(alpha: 0.5),
          strokeWidth: 4.0,
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: truck.coordinate,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartline.app',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
