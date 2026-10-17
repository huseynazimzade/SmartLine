import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/waste_provider.dart';
import '../../theme/app_theme.dart';
import 'cluster_detail_sheet.dart';
import 'map_pins.dart';
import 'truck_detail_sheet.dart';

class FullMapView extends StatefulWidget {
  const FullMapView({super.key});

  @override
  State<FullMapView> createState() => _FullMapViewState();
}

class _FullMapViewState extends State<FullMapView> {
  final MapController _mapController = MapController();

  void _showClusterDetail(BuildContext context, BinCluster cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ClusterDetailSheet(cluster: cluster),
      ),
    );
  }

  void _showTruckDetail(BuildContext context, CollectionTruck truck) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TruckDetailSheet(truck: truck),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waste = Provider.of<WasteProvider>(context);

    final markers = <Marker>[
      // Depots
      for (final depot in waste.depots)
        Marker(
          point: depot,
          width: 44,
          height: 48,
          child: const DepotPin(),
        ),

      // Clusters
      for (final cluster in waste.clusters)
        Marker(
          point: cluster.coordinate,
          width: 48,
          height: 52,
          child: ClusterPin(
            cluster: cluster,
            onTap: () => _showClusterDetail(context, cluster),
          ),
        ),

      // Trucks
      for (final truck in waste.trucks)
        Marker(
          point: truck.coordinate,
          width: 40,
          height: 44,
          child: TruckPin(
            truck: truck,
            onTap: () => _showTruckDetail(context, truck),
          ),
        ),
    ];

    return Stack(
      children: [
        // Interactive Map
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(40.37767, 49.84508), // Baku center
            initialZoom: 13.0,
            minZoom: 10.0,
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

        // Header floating card
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Live City Map',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${waste.clusters.length} Stations, ${waste.trucks.length} Trucks active',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                    onPressed: () {
                      _mapController.move(const LatLng(40.37767, 49.84508), 13.0);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Legend floating bar
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _legendItem(AppColors.primary, 'Empty'),
                  const SizedBox(width: 16),
                  _legendItem(AppColors.warning, 'Warning'),
                  const SizedBox(width: 16),
                  _legendItem(AppColors.critical, 'Critical'),
                  const SizedBox(width: 16),
                  _legendItem(AppColors.truckBlue, 'Truck'),
                  const SizedBox(width: 16),
                  _legendItem(AppColors.depotSlate, 'Station'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
