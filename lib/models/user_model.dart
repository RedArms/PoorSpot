import 'spot_models.dart';

class User {
  final String id;
  final String name;
  final List<BeggarAttribute> attributes;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.attributes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attributes': attributes.map((e) => e.name).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Inconnu',
      attributes: (json['attributes'] as List<dynamic>? ?? [])
          .map((e) => BeggarAttribute.values.firstWhere(
                (attr) => attr.name == e,
                orElse: () => BeggarAttribute.none,
              ))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}