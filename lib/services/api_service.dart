import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http;
import '../models/spot_models.dart';
import '../models/user_model.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000'; 
  }

  // --- AUTH --- (Inchangé)
  Future<User?> register(String username, String password, List<BeggarAttribute> attributes) async {
    try {
      final body = {
        "username": username,
        "password": password,
        "attributes": attributes.map((e) => e.toString().split('.').last).toList()
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) { print("Err Register: $e"); }
    return null;
  }

  Future<User?> login(String username, String password) async {
    try {
      final body = {
        "username": username,
        "password": password
      };

      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) { print("Err Login: $e"); }
    return null;
  }

  Future<bool> updateUserTags(String userId, List<BeggarAttribute> attributes) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/attributes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(attributes.map((e) => e.toString().split('.').last).toList()),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- FAVORITES --- (Inchangé)
  Future<bool> addFavorite(String userId, String spotId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/users/$userId/favorites/$spotId'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> removeFavorite(String userId, String spotId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/users/$userId/favorites/$spotId'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- OCCUPATION ---

  Future<Map<String, dynamic>> fetchOccupations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/occupations'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) { print("Err fetchOccupations: $e"); }
    return {};
  }

  Future<bool> occupySpot(String spotId, String userId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/spots/$spotId/occupy?user_id=$userId'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- DATA --- (Inchangé)
  Future<List<Spot>> fetchSpots() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/spots'));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(responseBody);
        return data.map((json) => Spot.fromJson(json)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<Spot?> createSpot(Spot spot) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/spots'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(spot.toJson()),
      );
      if (response.statusCode == 200) {
        return Spot.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) { print(e); }
    return null;
  }

  Future<bool> addReview(String spotId, Review review) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/spots/$spotId/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(review.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
// Retourne une Map avec durée et succès
  Future<Map<String, dynamic>> releaseSpotFull(String spotId, String userId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/spots/$spotId/release?user_id=$userId'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) { print("Err release: $e"); }
    return {};
  }

  Future<List<AchievementDef>> fetchAllAchievements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/achievements/list'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((e) => AchievementDef.fromJson(e)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(String period, String sortBy) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/top?period=$period&sort_by=$sortBy'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) { print("Err top: $e"); }
    return [];
  }
  
  // Garder l'ancienne méthode pour compatibilité si besoin, ou la rediriger
 // Garder l'ancienne méthode pour compatibilité si besoin, ou la rediriger
  Future<int?> releaseSpot(String spotId, String userId) async {
    final res = await releaseSpotFull(spotId, userId);
    return res['duration'] as int?;
  }

}