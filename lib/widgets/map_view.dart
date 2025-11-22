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
        initialCenter: const LatLng(50.8466, 4.3528), // Bruxelles centre
        initialZoom: 13.0,
        onLongPress: (_, latlng) => onMapLongPress(latlng),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
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
    final pinColor = _getGraduatedColor(spot.globalRating);
    final categoryIcon = _getCategoryIcon(spot.category);

    final double size = isSelected ? 65 : 50;

    return Marker(
      point: spot.position,
      width: size, 
      height: size,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => onSpotTap(spot),
        child: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // A. Le PING (Forme de goutte)
              Icon(
                Icons.location_on, 
                color: pinColor, 
                size: size,
                shadows: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              
              // B. Le PICTOGRAMME (Catégorie) à l'intérieur
              Positioned(
                top: size * 0.15,
                child: Icon(
                  categoryIcon, 
                  size: size * 0.45, 
                  color: Colors.white,
                ),
              ),
              
              // ZÉRO badge de notification ici. C'est clean.
            ],
          ),
        ),
      ),
    );
  }

  Marker _buildTempMarker(BuildContext context, LatLng pos) {
    return Marker(
      point: pos, width: 50, height: 50,
      alignment: Alignment.topCenter,
      child: const Icon(Icons.add_location_alt, size: 50, color: Colors.black),
    );
  }

  // Graduat Rouge -> Jaune -> VERT (Correction appliquée)
  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) {
      // De Rouge à Jaune
      return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    } else {
      // De Jaune à Vert Vif (0xFF00C853)
      return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tourisme': return Icons.camera_alt; 
      case 'Business': return Icons.business_center; 
      case 'Shopping': return Icons.shopping_bag; 
      case 'Nightlife': return Icons.local_bar; 
      case 'Transport': return Icons.directions_subway; 
      default: return Icons.place;
    }
  }
}