import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/models/created_itinerary.dart';
import 'package:mobile/models/place.dart';

/// Persists user session and saved data locally.
class UserStorage {
  static const _userKey = 'logged_in_user';
  static const _emailKey = 'user_email';
  static const _savedPlacesKey = 'saved_place_ids';
  static const _savedPlaceObjectsKey = 'saved_place_objects';
  static const _savedItinerariesKey = 'saved_itineraries';

  static Future<void> saveSession({required String user, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user);
    await prefs.setString(_emailKey, email);
  }

  static Future<Map<String, String?>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user': prefs.getString(_userKey),
      'email': prefs.getString(_emailKey),
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_emailKey);
  }

  static Future<void> savePlaceIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedPlacesKey, ids.toList());
  }

  static Future<Set<String>> loadPlaceIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_savedPlacesKey) ?? []).toSet();
  }

  static Future<void> saveSavedItineraries(List<CreatedItinerary> itineraries) async {
    final prefs = await SharedPreferences.getInstance();
    final items = itineraries.map((it) => {
      'id': it.id,
      'title': it.title,
      'from': it.from,
      'to': it.to,
      'days': it.days,
      'travelers': it.travelers,
      'budget': it.budget,
      'pace': it.pace,
      'author': it.author,
      'likes': it.likes,
      'isPublic': it.isPublic,
      'itinerary': it.itinerary,
      'distanceKm': it.distanceKm,
      'durationMinutes': it.durationMinutes,
    }).toList();
    final encoded = items.map((e) => json.encode(e)).toList();
    await prefs.setStringList(_savedItinerariesKey, encoded);
  }

  static Future<void> saveItineraries(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((e) => json.encode(_itineraryToJson(e))).toList();
    await prefs.setStringList(_savedItinerariesKey, encoded);
  }

  static Future<List<Map<String, dynamic>>> loadItineraries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedItinerariesKey) ?? [];
    return raw.map((s) => json.decode(s) as Map<String, dynamic>).toList();
  }

  static Map<String, dynamic> _itineraryToJson(Map<String, dynamic> item) {
    return {
      'id': item['id'],
      'title': item['title'],
      'from': item['from'],
      'to': item['to'],
      'days': item['days'],
      'author': item['author'],
      'likes': item['likes'],
      'isPublic': item['isPublic'],
    };
  }

  // ── Full Place object persistence ─────────────────────────────────────────

  /// Persists the full list of saved [Place] objects so they can be restored
  /// even if the place is not present in the initial loaded list.
  static Future<void> savePlaceObjects(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        places.map((p) => json.encode(p.toJson())).toList();
    await prefs.setStringList(_savedPlaceObjectsKey, encoded);
  }

  /// Loads persisted [Place] objects. Returns an empty list on first run.
  static Future<List<Place>> loadPlaceObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_savedPlaceObjectsKey) ?? [];
    return raw.map((s) {
      try {
        return Place.fromJson(json.decode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Place>().toList();
  }
}
