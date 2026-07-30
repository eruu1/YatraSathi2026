import 'package:latlong2/latlong.dart';
import 'package:mobile/models/place.dart';

class CreatedItinerary {
  final String id;
  String title;
  final String from;
  final String to;
  final int days;
  final int travelers;
  final String budget;
  final String pace;
  final String diet;
  final String author;
  int likes;
  bool isPublic;
  final Map<String, List<Map<String, dynamic>>> itinerary;
  final List<Place> orderedWaypoints;
  final List<LatLng> routePoints;
  final double distanceKm;
  final double durationMinutes;

  CreatedItinerary({
    required this.id,
    required this.title,
    required this.from,
    required this.to,
    required this.days,
    required this.travelers,
    required this.budget,
    required this.pace,
    required this.diet,
    required this.author,
    this.likes = 0,
    this.isPublic = false,
    required this.itinerary,
    required this.orderedWaypoints,
    required this.routePoints,
    required this.distanceKm,
    required this.durationMinutes,
  });

  factory CreatedItinerary.fromMap(Map<String, dynamic> m) {
    // Provide sensible defaults for fields that may be missing from a
    // lightweight backend response used for profile counts.
    return CreatedItinerary(
      id: m['id']?.toString() ?? '',
      title: m['title'] ?? (m['name'] ?? 'Untitled Trip'),
      from: m['from'] ?? '',
      to: m['to'] ?? '',
      days: m['days'] ?? 1,
      travelers: m['travelers'] ?? 1,
      budget: m['budget'] ?? '',
      pace: m['pace'] ?? '',
      diet: m['diet'] ?? '',
      author: m['author'] ?? m['author_username'] ?? 'Unknown',
      likes: m['likes'] ?? 0,
      isPublic: m['is_public'] ?? false,
      itinerary: Map<String, List<Map<String, dynamic>>>.from(m['itinerary'] ?? {}),
      orderedWaypoints: [],
      routePoints: [],
      distanceKm: (m['distance_km'] is num) ? (m['distance_km'] as num).toDouble() : 0.0,
      durationMinutes: (m['duration_minutes'] is num) ? (m['duration_minutes'] as num).toDouble() : 0.0,
    );
  }
}