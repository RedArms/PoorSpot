import 'spot_models.dart';

class User {
  final String id;
  final String name;
  final List<BeggarAttribute> attributes;
  final List<String> favorites; // List of spot IDs
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.attributes,
    this.favorites = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attributes': attributes.map((e) => e.toString().split('.').last).toList(),
      'favorites': favorites,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Inconnu',
      attributes: (json['attributes'] as List<dynamic>? ?? [])
          .map((e) => BeggarAttribute.values.firstWhere(
                (attr) => attr.toString().split('.').last == e,
                orElse: () => BeggarAttribute.none,
              ))
          .toList(),
      favorites: List<String>.from(json['favorites'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper to check if a spot is favorited
  bool isFavorite(String spotId) => favorites.contains(spotId);

  // Create a copy with updated favorites
  User copyWith({
    String? id,
    String? name,
    List<BeggarAttribute>? attributes,
    List<String>? favorites,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
      favorites: favorites ?? this.favorites,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}