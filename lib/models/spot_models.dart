import 'package:flutter/material.dart'; // Nécessaire pour les Icons/Colors si besoin, ici pour la logique
import 'package:latlong2/latlong.dart';

enum BeggarAttribute {
  none,       
  dog,        
  music,      
  disability, 
  circus,     
  family      
}

class Spot {
  final String id;
  final String name;
  final String description;
  final LatLng position;
  final List<Review> reviews;
  final String category;
  final DateTime createdAt;
  final String createdBy;
  int currentActiveUsers; 

  Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.reviews,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    this.currentActiveUsers = 0,
  });

  // --- MOYENNES DES CRITÈRES (SUR 5) ---

  double get avgRevenue => _calcAvg((r) => r.ratingRevenue);
  double get avgSecurity => _calcAvg((r) => r.ratingSecurity);
  double get avgTraffic => _calcAvg((r) => r.ratingTraffic);

  // Note Globale (Moyenne des 3 critères)
  double get globalRating {
    if (reviews.isEmpty) return 0.0;
    return (avgRevenue + avgSecurity + avgTraffic) / 3;
  }

  double _calcAvg(double Function(Review) selector) {
    if (reviews.isEmpty) return 0.0;
    return reviews.map(selector).reduce((a, b) => a + b) / reviews.length;
  }

  // --- CONSEIL COMPARATIF ---
  
  String getSmartAdvice(List<BeggarAttribute> userSkills) {
    if (reviews.isEmpty) return "Pas encore d'infos. Soyez le premier !";

    // On cherche quel attribut performe le mieux (basé sur le revenu)
    Map<BeggarAttribute, List<double>> stats = {};
    for (var r in reviews) {
      stats.putIfAbsent(r.attribute, () => []).add(r.ratingRevenue);
    }

    if (stats.isEmpty) return "Données insuffisantes pour le profilage.";

    // Calcul des moyennes par attribut
    var bestAttr = BeggarAttribute.none;
    var bestScore = -1.0;
    var worstAttr = BeggarAttribute.none;
    var worstScore = 6.0;

    stats.forEach((key, values) {
      double avg = values.reduce((a, b) => a + b) / values.length;
      if (avg > bestScore) {
        bestScore = avg;
        bestAttr = key;
      }
      if (avg < worstScore) {
        worstScore = avg;
        worstAttr = key;
      }
    });

    String advice = "";
    
    // Construction de la phrase
    if (bestAttr != BeggarAttribute.none) {
      advice += "💡 Les ${_formatAttr(bestAttr)}s gagnent mieux ici.";
    }
    
    if (worstAttr != BeggarAttribute.none && worstAttr != bestAttr) {
      advice += " Les ${_formatAttr(worstAttr)}s galèrent un peu plus.";
    }

    // Petit check perso
    bool userHasBest = userSkills.contains(bestAttr);
    if (userHasBest) {
      advice += " (C'est bon pour vous !)";
    }

    return advice;
  }

  String _formatAttr(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return "maîtres chiens";
      case BeggarAttribute.music: return "musiciens";
      case BeggarAttribute.circus: return "acrobates";
      case BeggarAttribute.disability: return "personnes handicapées";
      case BeggarAttribute.family: return "familles";
      default: return "solos";
    }
  }
}

class Review {
  final String id;
  final String authorName;
  
  // Les 3 critères sur 5
  final double ratingRevenue;
  final double ratingSecurity;
  final double ratingTraffic;

  final BeggarAttribute attribute;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.authorName,
    required this.ratingRevenue,
    required this.ratingSecurity,
    required this.ratingTraffic,
    required this.attribute,
    required this.comment,
    required this.createdAt,
  });
}