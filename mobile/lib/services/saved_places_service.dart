import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/constants.dart';
import 'package:mobile/models/place.dart';

/// HTTP client for the /saved-places backend endpoints.
///
/// All methods are fire-and-forget safe — callers should catch exceptions
/// and fall back to local storage when the server is unreachable.
class SavedPlacesService {
  // ── Save ────────────────────────────────────────────────────────────────
  /// Persist a saved place to the database.
  /// Idempotent — safe to call even if already saved.
  Future<void> savePlace({
    required String userId,
    required Place place,
  }) async {
    final uri = Uri.parse('$kBaseUrl/saved-places');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': userId,
            'place_id': place.id,
            'place_snapshot': place.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('savePlace failed: ${res.statusCode} ${res.body}');
    }
  }

  // ── Unsave ──────────────────────────────────────────────────────────────
  /// Remove a saved place from the database.
  /// Does NOT throw if the place was never saved (404 is swallowed).
  Future<void> unsavePlace({
    required String userId,
    required String placeId,
  }) async {
    final uri = Uri.parse('$kBaseUrl/saved-places/$placeId')
        .replace(queryParameters: {'user_id': userId});
    final res = await http
        .delete(uri)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200 && res.statusCode != 404) {
      throw Exception('unsavePlace failed: ${res.statusCode} ${res.body}');
    }
  }

  // ── Fetch all ───────────────────────────────────────────────────────────
  /// Load all saved places for a user from the database.
  /// Returns an empty list if the server is unreachable.
  Future<List<Place>> fetchSavedPlaces(String userId) async {
    final uri = Uri.parse('$kBaseUrl/saved-places')
        .replace(queryParameters: {'user_id': userId});
    final res = await http
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = data['places'] as List? ?? [];
      return list
          .map((item) => Place.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('fetchSavedPlaces failed: ${res.statusCode}');
    }
  }

  // ── Check ───────────────────────────────────────────────────────────────
  /// Returns true if the place is saved in the DB for this user.
  Future<bool> isSaved({
    required String userId,
    required String placeId,
  }) async {
    final uri = Uri.parse('$kBaseUrl/saved-places/$placeId/check')
        .replace(queryParameters: {'user_id': userId});
    final res = await http
        .get(uri)
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['is_saved'] as bool? ?? false;
    }
    return false;
  }
}
