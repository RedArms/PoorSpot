import 'package:latlong2/latlong.dart';

enum BeggarAttribute {
  none,       
  dog,        
  music,      
  disability, 
  circus,     
  family      
}

// FIX: Réintégration de l'extension pour la compatibilité avec les versions de Dart // qui ne supportent pas nativement .name sur les enums. 
//
extension BeggarAttributeExtension on BeggarAttribute { String get name => toString().split('.').last; }
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

  // --- JSON SERIALIZATION ---

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'currentActiveUsers': currentActiveUsers,
      'reviews': reviews.map((x) => x.toJson()).toList(),
    };
  }

  factory Spot.fromJson(Map<String, dynamic> json) {
    return Spot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble()
      ),
      category: json['category'] ?? 'Autre',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      createdBy: json['createdBy'] ?? 'Inconnu',
      currentActiveUsers: json['currentActiveUsers'] ?? 0,
      reviews: List<Review>.from(
        (json['reviews'] as List<dynamic>? ?? []).map((x) => Review.fromJson(x)),
      ),
    );
  }

  // --- CALCULS MÉTIER ---

  double get avgRevenue => _calcAvg((r) => r.ratingRevenue);
  double get avgSecurity => _calcAvg((r) => r.ratingSecurity);
  double get avgTraffic => _calcAvg((r) => r.ratingTraffic);

  double get globalRating {
    if (reviews.isEmpty) return 0.0;
    return (avgRevenue + avgSecurity + avgTraffic) / 3;
  }

  double _calcAvg(double Function(Review) selector) {
    if (reviews.isEmpty) return 0.0;
    return reviews.map(selector).reduce((a, b) => a + b) / reviews.length;
  }

  String getSmartAdvice(List<BeggarAttribute> userSkills) {
    if (reviews.isEmpty) return "Pas encore d'infos. Soyez le premier !";

    Map<BeggarAttribute, List<double>> stats = {};
    for (var r in reviews) {
      stats.putIfAbsent(r.attribute, () => []).add(r.ratingRevenue);
    }

    if (stats.isEmpty) return "Données insuffisantes.";

    var bestAttr = BeggarAttribute.none;
    var bestScore = -1.0;

    stats.forEach((key, values) {
      double avg = values.reduce((a, b) => a + b) / values.length;
      if (avg > bestScore) {
        bestScore = avg;
        bestAttr = key;
      }
    });

    String advice = "";
    if (bestAttr != BeggarAttribute.none) {
      advice += "💡 Les ${_formatAttr(bestAttr)}s gagnent mieux ici.";
    }
    if (userSkills.contains(bestAttr)) advice += " (C'est bon pour vous !)";
    return advice;
  }

  String _formatAttr(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return "maîtres chiens";
      case BeggarAttribute.music: return "musiciens";
      case BeggarAttribute.circus: return "acrobates";
      case BeggarAttribute.disability: return "handicapés";
      case BeggarAttribute.family: return "familles";
      default: return "solos";
    }
  }
}

class Review {
  final String id;
  final String authorName;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'ratingRevenue': ratingRevenue,
      'ratingSecurity': ratingSecurity,
      'ratingTraffic': ratingTraffic,
      'attribute': attribute.name, // Utilise l'extension ou la propriété native
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      authorName: json['authorName'] ?? 'Anonyme',
      ratingRevenue: (json['ratingRevenue'] as num).toDouble(),
      ratingSecurity: (json['ratingSecurity'] as num).toDouble(),
      ratingTraffic: (json['ratingTraffic'] as num).toDouble(),
      attribute: BeggarAttribute.values.firstWhere(
        (e) => e.name == json['attribute'], orElse: () => BeggarAttribute.none
      ),
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}