import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:mobile/constants.dart';
import 'package:mobile/models/place.dart';

class PlaceService {
  Future<List<Place>> fetchPlaces({
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    queryParams['limit'] = limit.toString();
    queryParams['offset'] = offset.toString();
    
    // First, try to load local `asset.json` if it exists in assets — useful
    // for static/demo data. Falls back to backend HTTP call on failure.
    try {
      final s = await rootBundle.loadString('asset.json');
      final local = json.decode(s) as Map<String, dynamic>;
      final list = local['locations'] as List? ?? [];
      // Ensure each item has an `id` field for Place compatibility.
      int idx = 0;
      return list.map((item) {
        final m = Map<String, dynamic>.from(item as Map);
        if (m['id'] == null) m['id'] = 'local-${idx++}';
        return Place.fromJson(m);
      }).toList();
    } catch (_) {
      // Local load failed — fall back to network.
      final uri = Uri.parse('$kBaseUrl/places').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data['places'] as List? ?? [];
        return list
            .map((item) => Place.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server returned ${res.statusCode}');
      }
    }
  }

  Future<List<Place>> searchPlaces(String query, {int limit = 50, int offset = 0}) async {
    final uri = Uri.parse('$kBaseUrl/places/search').replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final list = data['places'] as List? ?? [];
      return list
          .map((item) => Place.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Server returned ${res.statusCode}');
    }
  }

  Future<List<Place>> getNearbyPlaces(
    double lat,
    double lng, {
    double radius = 10.0,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radius.toString(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (category != null) queryParams['category'] = category;
    
    final uri = Uri.parse('$kBaseUrl/places/nearby').replace(queryParameters: queryParams);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final list = data['places'] as List? ?? [];
      return list
          .map((item) => Place.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Server returned ${res.statusCode}');
    }
  }

  Future<Place?> getPlace(String placeId) async {
    final res = await http.get(Uri.parse('$kBaseUrl/places/$placeId')).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Place.fromJson(data as Map<String, dynamic>);
    } else if (res.statusCode == 404) {
      return null;
    } else {
      throw Exception('Server returned ${res.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await http.get(Uri.parse('$kBaseUrl/places/categories/list')).timeout(const Duration(seconds: 10));
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final list = data['categories'] as List? ?? [];
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Server returned ${res.statusCode}');
    }
  }
}