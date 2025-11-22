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