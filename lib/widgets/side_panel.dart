import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/spot_models.dart';
import '../data/mock_data.dart';

class SidePanel extends StatelessWidget {
  final Spot spot;
  final VoidCallback onClose;
  final VoidCallback onAddReview;

  const SidePanel({
    super.key, 
    required this.spot, 
    required this.onClose,
    required this.onAddReview, 
  });

  @override
  Widget build(BuildContext context) {
    final globalRating = spot.globalRating;
    final themeColor = _getGraduatedColor(globalRating);
    final advice = spot.getSmartAdvice(currentUser.myAttributes);
    
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.98),
              border: Border(left: BorderSide(color: themeColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(spot.name, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(_getCategoryIcon(spot.category), color: Colors.grey, size: 14),
                                const SizedBox(width: 6),
                                Text(spot.category.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: onClose),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // NOTE GLOBALE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            globalRating.toStringAsFixed(1),
                            style: TextStyle(color: themeColor, fontSize: 48, fontWeight: FontWeight.bold, height: 1),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0, left: 4),
                            child: Text("/ 5", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ),
                        ],
                      ),
                      const Center(child: Text("NOTE GLOBALE", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2))),
                      
                      const SizedBox(height: 30),

                      // CRITÈRES (NOUVEAU LAYOUT)
                      _buildCriteriaRow("REVENU", spot.avgRevenue, Icons.attach_money),
                      const SizedBox(height: 15),
                      _buildCriteriaRow("SÉCURITÉ", spot.avgSecurity, Icons.lock_outline),
                      const SizedBox(height: 15),
                      _buildCriteriaRow("PASSAGE", spot.avgTraffic, Icons.directions_walk),

                      const SizedBox(height: 30),
                      
                      // CONSEIL
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.white70),
                                SizedBox(width: 8),
                                Text("CONSEIL DU RÉSEAU", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              advice,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Text("DERNIERS AVIS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      ...spot.reviews.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.comment, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  _buildSmallStars(r.ratingRevenue), 
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("par ${r.authorName} (${_getAttributeName(r.attribute)})", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                      )),
                      
                      const SizedBox(height: 20),
                      
                      // BOUTON ACTION
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onAddReview, 
                          icon: const Icon(Icons.add_chart, color: Colors.black),
                          label: const Text("DONNER SON AVIS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String label, double score, IconData icon) {
    final color = _getGraduatedColor(score);
    return Column(
      children: [
        // Ligne 1 : Icône + Label centrés
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        // Ligne 2 : Barre + Score
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 5.0,
                  backgroundColor: Colors.white10,
                  color: color, // Couleur dynamique Rouge -> Vert
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 30,
              child: Text(
                score.toStringAsFixed(1), 
                textAlign: TextAlign.end, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStars(double score) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < score ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 12,
        );
      }),
    );
  }

  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) {
      return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    } else {
      return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
    }
  }

  String _getAttributeName(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return "Chien";
      case BeggarAttribute.music: return "Musique";
      case BeggarAttribute.circus: return "Cirque";
      case BeggarAttribute.disability: return "Handicap";
      case BeggarAttribute.family: return "Famille";
      default: return "Solo";
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