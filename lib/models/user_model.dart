import 'spot_models.dart';

class CheckInLog {
  final String spotId;
  final String spotName;
  final DateTime timestamp;
  int durationSeconds; 

  CheckInLog({
    required this.spotId, 
    required this.spotName, 
    required this.timestamp,
    this.durationSeconds = 0,
  });

  factory CheckInLog.fromJson(Map<String, dynamic> json) {
    return CheckInLog(
      spotId: json['spotId'] ?? '',
      spotName: json['spotName'] ?? 'Spot inconnu',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      durationSeconds: json['durationSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'spotId': spotId,
    'spotName': spotName,
    'timestamp': timestamp.toIso8601String(),
    'durationSeconds': durationSeconds,
  };

  // Affichage propre de la durée
  String get formattedDuration {
    if (durationSeconds <= 0) return "En cours...";
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    
    if (h > 0) {
      return "${h}h ${m.toString().padLeft(2, '0')}";
    }
    return "$m min";
  }

}

class AchievementDef {
  final String id;
  final String name;
  final String desc;
  final int points;
  final String icon;

  AchievementDef({required this.id, required this.name, required this.desc, required this.points, required this.icon});

  factory AchievementDef.fromJson(Map<String, dynamic> json) {
    return AchievementDef(
      id: json['id'],
      name: json['name'],
      desc: json['desc'],
      points: json['points'],
      icon: json['icon'],
    );
  }
}

class User {
  final String id;
  final String name;
  final List<BeggarAttribute> attributes;
  final List<String> favorites;
  final List<CheckInLog> history;
  final DateTime createdAt;
  int points; // Modifiable localement
  List<String> achievements; // IDs des succès

  User({
    required this.id,
    required this.name,
    required this.attributes,
    this.favorites = const [],
    this.history = const [],
    required this.createdAt,
    this.points = 0,
    this.achievements = const [],
  });

  // Affichage propre du temps total
  String get totalBeggingTime {
    int totalSeconds = 0;
    for (var log in history) {
      totalSeconds += log.durationSeconds;
    }
    if (totalSeconds == 0) return "0 min";

    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    
    if (h > 0) {
      return "${h}h ${m.toString().padLeft(2, '0')}";
    }
    return "$m min";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attributes': attributes.map((e) => e.toString().split('.').last).toList(),
      'favorites': favorites,
      'history': history.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Inconnu',
      attributes: (json['attributes'] as List<dynamic>? ?? []).map((e) => BeggarAttribute.values.firstWhere((attr) => attr.toString().split('.').last == e, orElse: () => BeggarAttribute.none)).toList(),
      favorites: List<String>.from(json['favorites'] ?? []),
      history: List<CheckInLog>.from((json['history'] as List<dynamic>? ?? []).map((x) => CheckInLog.fromJson(x))),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      points: json['points'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }
  
  bool isFavorite(String spotId) => favorites.contains(spotId);

  User copyWith({
    String? id,
    String? name,
    List<BeggarAttribute>? attributes,
    List<String>? favorites,
    List<CheckInLog>? history,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
      favorites: favorites ?? this.favorites,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}