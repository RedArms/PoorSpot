import 'package:flutter/material.dart';
import '../data/mock_data.dart'; 
import '../models/spot_models.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulation User
    final user = currentUser;
    
    // On simule un historique pour l'affichage (on prend quelques reviews au hasard des mocks)
    final myHistory = mockSpots.expand((s) => s.reviews).take(5).toList();
    final int contributionCount = myHistory.length + 42; // Faux nombre total

    // Logique Ranking (Basée sur l'expérience/contributions)
    String rank = "NPC";
    Color rankColor = Colors.grey;
    double progress = 0.0;

    if (contributionCount > 100) {
      rank = "SYSTEM ADMIN";
      rankColor = const Color(0xFF00E5FF);
      progress = 1.0;
    } else if (contributionCount > 50) {
      rank = "GUIDE";
      rankColor = Colors.greenAccent;
      progress = 0.75;
    } else if (contributionCount > 10) {
      rank = "EXPLORATEUR";
      rankColor = Colors.amberAccent;
      progress = 0.40;
    } else {
      rank = "NOVICE";
      rankColor = Colors.grey;
      progress = 0.1;
    }

    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
              border: Border(bottom: BorderSide(color: Color(0xFF00E5FF), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[900],
                      child: Icon(Icons.fingerprint, color: rankColor, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 20, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: rankColor.withOpacity(0.2), border: Border.all(color: rankColor)),
                          child: Text(rank, style: TextStyle(color: rankColor, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[900],
                  color: rankColor,
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text("RÉPUTATION: $contributionCount PTS", style: TextStyle(color: rankColor, fontSize: 8, fontFamily: 'Courier')),
              ],
            ),
          ),

          // STATS
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildColdStat("ZONES", "12"),
                _buildColdStat("AVIS", "$contributionCount"),
                _buildColdStat("KARMA", "High"),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 20, bottom: 10),
            child: Text("DERNIÈRES ACTIVITÉS", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, letterSpacing: 1, fontFamily: 'Courier')),
          ),

          // LISTE HISTORIQUE (Corrigée pour utiliser les notes /5)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: myHistory.map((review) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10))
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.rate_review, size: 16, color: Colors.grey),
                    title: Text(review.comment, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontFamily: 'Courier', fontSize: 12)),
                    // Affiche la note Revenu en étoiles
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) => Icon(
                        index < review.ratingRevenue ? Icons.star : Icons.star_border,
                        size: 10, 
                        color: rankColor
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {}, 
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
              label: const Text("DÉCONNEXION SYSTÈME", style: TextStyle(color: Colors.redAccent, letterSpacing: 2)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildColdStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Courier')),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }
}