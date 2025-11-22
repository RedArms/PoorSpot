import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot_models.dart';

class PoorSpotMap extends StatelessWidget {
  final List<Spot> spots;
  final String? selectedSpotId;
  final LatLng? tempPosition;
  final Function(Spot) onSpotTap;
  final Function(LatLng) onMapLongPress;

  const PoorSpotMap({
    super.key,
    required this.spots,
    this.selectedSpotId,
    this.tempPosition,
    required this.onSpotTap,
    required this.onMapLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final allMarkers = <Marker>[
      ...spots.map((spot) => _buildSpotMarker(context, spot)),
      if (tempPosition != null) _buildTempMarker(context, tempPosition!),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: const LatLng(50.8466, 4.3528),
        initialZoom: 14.0,
        onLongPress: (_, latlng) => onMapLongPress(latlng),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Carte "Voyager" (Clair/Propre)
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.poorspot.app',
        ),
        MarkerLayer(markers: allMarkers),
      ],
    );
  }

  Marker _buildSpotMarker(BuildContext context, Spot spot) {
    final isSelected = spot.id == selectedSpotId;
    final earnings = spot.averageHourlyRate;
    final color = _getRevenueColor(earnings);

    return Marker(
      point: spot.position,
      width: isSelected ? 70 : 55, // Un peu plus gros pour la lisibilité
      height: isSelected ? 70 : 55,
      child: GestureDetector(
        onTap: () => onSpotTap(spot),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Le Cercle Principal (Couleur = Argent)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getCategoryIcon(spot.category), size: 16, color: Colors.black),
                    // Affiche le montant directement sur la map !
                    Text(
                      "${earnings.toInt()}€", 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)
                    ),
                  ],
                ),
              ),
            ),
            
            // 2. Badge "Présence" (Rouge si occupé, Vert si libre)
            Positioned(
              right: -2, top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: spot.currentActiveUsers > 0 ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  "${spot.currentActiveUsers}",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Marker _buildTempMarker(BuildContext context, LatLng pos) {
    return Marker(
      point: pos, width: 50, height: 50,
      child: const Icon(Icons.add_location_alt, size: 40, color: Colors.black),
    );
  }

  Color _getRevenueColor(double rate) {
    if (rate >= 30) return const Color(0xFF00E5FF); // Cyan (Jackpot)
    if (rate >= 15) return const Color(0xFF76FF03); // Vert fluo (Bien)
    if (rate >= 5) return const Color(0xFFFFEA00); // Jaune (Moyen)
    return const Color(0xFFFF3D00); // Rouge (Misère)
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tourisme': return Icons.camera_alt;
      case 'Business': return Icons.work;
      case 'Shopping': return Icons.shopping_bag;
      default: return Icons.place;
    }
  }
}