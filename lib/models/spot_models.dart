import 'package:latlong2/latlong.dart';

// Les "Attributs" ou "Loadouts" pour maximiser le profit
enum BeggarAttribute {
  none,       // Juste soi-même
  dog,        // Animal de compagnie
  music,      // Instrument / Chant
  disability, // Handicap visible
  circus,     // Jonglage / Art de rue (Nouveau)
  family      // En famille / Avec enfant
}

class Spot {
  final String id;
  final String name;
  final String description;
  final LatLng position;
  final List<Review> reviews;
  final String category; // Tourisme, Business, etc.
  final DateTime createdAt;
  final String createdBy;
  
  // Nombre de personnes PRÉSENTES actuellement (Déclaratif)
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

  // --- CALCULS BUSINESS ---

  // Revenu Moyen (€/h)
  double get averageHourlyRate {
    if (reviews.isEmpty) return 0.0;
    // On filtre les 0 ou les valeurs absurdes (>100€) pour lisser
    final validReviews = reviews.where((r) => r.hourlyRate > 0 && r.hourlyRate < 200).toList();
    if (validReviews.isEmpty) return 0.0;
    
    return validReviews.map((r) => r.hourlyRate).reduce((a, b) => a + b) / validReviews.length;
  }

  // Quel est l'attribut qui rapporte le plus ici ?
  BeggarAttribute get bestAttribute {
    if (reviews.isEmpty) return BeggarAttribute.none;
    // Simplification : On prend l'attribut de la review qui a le meilleur taux horaire
    final bestReview = reviews.reduce((curr, next) => curr.hourlyRate > next.hourlyRate ? curr : next);
    return bestReview.attribute;
  }

  // --- ALGORYTHME DE CONSEIL INTELLIGENT ---
  
  String getSmartAdvice(List<BeggarAttribute> userSkills) {
    if (reviews.isEmpty) return "Pas assez de données. Soyez le premier !";

    final bestAttr = bestAttribute;
    final avgRate = averageHourlyRate;

    // 1. Si le lieu performe mieux avec un attribut que l'utilisateur possède
    if (userSkills.contains(bestAttr)) {
      return "🔥 FONCEZ ! Ce spot rapporte un max avec : ${_formatAttr(bestAttr)}.";
    }

    // 2. Si le lieu demande un attribut que l'utilisateur N'A PAS
    if (bestAttr != BeggarAttribute.none && !userSkills.contains(bestAttr)) {
      return "⚠️ ATTENTION. Ici, ce sont les ${_formatAttr(bestAttr)}s qui gagnent (${avgRate.toInt()}€/h). Vous risquez de gagner moins.";
    }

    // 3. Analyse par catégorie (Bonus contextuel)
    if (category == 'Business' && userSkills.contains(BeggarAttribute.music)) {
      return "✅ BON PLAN. Les zones Business paient bien pour la musique.";
    }
    
    if (category == 'Shopping' && userSkills.contains(BeggarAttribute.dog)) {
      return "🐕 EFFICACE. Les zones Shopping marchent fort avec les animaux.";
    }

    return "ℹ️ Zone standard. Le rendement moyen est de ${avgRate.toInt()}€/h.";
  }

  String _formatAttr(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return "ANIMAUX";
      case BeggarAttribute.music: return "MUSICIENS";
      case BeggarAttribute.circus: return "ACROBATES";
      case BeggarAttribute.disability: return "PERSONNES HANDICAPÉES";
      case BeggarAttribute.family: return "FAMILLES";
      default: return "MENDIANTS SOLOS";
    }
  }
}

class Review {
  final String id;
  final String authorName;
  
  final double hourlyRate; // Le Gain (€/h) est ROI
  final BeggarAttribute attribute; // Quel "Skin" utilisé ?
  
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.authorName,
    required this.hourlyRate,
    required this.attribute,
    required this.comment,
    required this.createdAt,
  });
}