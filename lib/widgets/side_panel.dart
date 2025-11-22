import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/spot_models.dart';

class SidePanel extends StatelessWidget {
  final Spot spot;
  final VoidCallback onClose;

  const SidePanel({super.key, required this.spot, required this.onClose});

  @override
  Widget build(BuildContext context) {
    // Calcul de la couleur de rentabilité
    final rate = spot.averageHourlyRate;
    Color rateColor = rate >= 20 ? const Color(0xFF00E5FF) : (rate >= 10 ? Colors.greenAccent : Colors.redAccent);
    
    // Calcul Occupation
    bool isCrowded = spot.currentActiveUsers >= 2;
    
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.95),
              border: Border(left: BorderSide(color: rateColor, width: 4)),
            ),
            child: Column(
              children: [
                // HEADER SIMPLE ET EFFICACE
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onClose),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCrowded ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              isCrowded ? "SATURÉ (${spot.currentActiveUsers})" : "LIBRE (${spot.currentActiveUsers})",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(spot.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(spot.category.toUpperCase(), style: const TextStyle(color: Colors.grey, letterSpacing: 2)),
                    ],
                  ),
                ),

                // LE CŒUR DU SYSTÈME : REVENU & CONSEILS
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 1. LE PROFIT
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: rateColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: rateColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("RENDEMENT", style: TextStyle(color: Colors.white, fontSize: 16)),
                            Text("${rate.toStringAsFixed(2)}€ / h", style: TextStyle(color: rateColor, fontSize: 30, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // 2. L'OPTIMISATION (Quel attribut ?)
                      if (spot.bestAttribute != BeggarAttribute.none)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.amber),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("CONSEIL D'OPTIMISATION", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    Text(
                                      "Utilisez l'attribut: ${_getAttributeName(spot.bestAttribute)}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                      const SizedBox(height: 30),
                      const Text("DERNIERS RAPPORTS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      ...spot.reviews.map((r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(_getAttributeIcon(r.attribute), color: Colors.white, size: 20),
                        ),
                        title: Text(r.comment, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        subtitle: Text(_getAttributeName(r.attribute), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        trailing: Text("${r.hourlyRate.toInt()}€", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ))
                    ],
                  ),
                ),
                
                // BOUTON D'ACTION EN BAS
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {}, // Logique de déclaration
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text("AJOUTER RAPPORT (€)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15)
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAttributeName(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return "CHIEN 🐕";
      case BeggarAttribute.music: return "MUSIQUE 🎵";
      case BeggarAttribute.circus: return "CIRQUE 🤹";
      case BeggarAttribute.disability: return "HANDICAP ♿";
      case BeggarAttribute.family: return "FAMILLE 👶";
      default: return "SOLO 👤";
    }
  }

  IconData _getAttributeIcon(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return Icons.pets;
      case BeggarAttribute.music: return Icons.music_note;
      case BeggarAttribute.circus: return Icons.sports_handball; // Jonglage approx
      case BeggarAttribute.disability: return Icons.accessible;
      case BeggarAttribute.family: return Icons.child_care;
      default: return Icons.person;
    }
  }
}