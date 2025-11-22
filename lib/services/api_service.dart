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

  // --- AUTH ---

  Future<User?> register(String username, String password, List<BeggarAttribute> attributes) async {
    try {
      final body = {
        "username": username,
        "password": password,
        "attributes": attributes.map((e) => e.name).toList()
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        print("Erreur Register: ${response.body}");
      }
    } catch (e) {
      print("Exception Register: $e");
    }
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
      } else {
        print("Erreur Login: ${response.body}");
      }
    } catch (e) {
      print("Exception Login: $e");
    }
    return null;
  }

  Future<bool> updateUserTags(String userId, List<BeggarAttribute> attributes) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/attributes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(attributes.map((e) => e.name).toList()),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // --- DATA ---

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
}