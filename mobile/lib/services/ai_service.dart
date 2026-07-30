import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/constants.dart';
import 'package:mobile/services/auth_service.dart';

/// HTTP client for the /ai backend endpoints.
/// Chat-only — editing and proposal methods have been removed.
class AIService {
  /// Send a single chat turn to the AI assistant.
  static Future<Map<String, dynamic>> chat({
    required String sessionId,
    required String message,
    String? userId,
    String? screenContext,
    Map<String, dynamic>? screenData,
    Map<String, dynamic>? itineraryContext,
    List<Map<String, dynamic>>? createdItineraries,
  }) async {
    final headers = await AuthService.getAuthHeader();
    headers['Content-Type'] = 'application/json';

    final body = <String, dynamic>{
      'session_id': sessionId,
      'message': message,
    };
    if (userId != null) body['user_id'] = userId;
    if (screenContext != null) body['screen_context'] = screenContext;
    if (screenData != null) body['screen_data'] = screenData;
    if (itineraryContext != null) body['itinerary_context'] = itineraryContext;
    if (createdItineraries != null) body['created_itineraries'] = createdItineraries;

    final response = await http
        .post(
          Uri.parse('$kBaseUrl/ai/chat'),
          headers: headers,
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      try {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(
            error['detail'] ?? 'AI chat failed (${response.statusCode})');
      } on FormatException {
        throw Exception('AI chat failed (${response.statusCode})');
      }
    }
  }

  /// Fetch the full chat history for a session.
  static Future<Map<String, dynamic>> getSession(String sessionId) async {
    final headers = await AuthService.getAuthHeader();
    final response = await http
        .get(Uri.parse('$kBaseUrl/ai/sessions/$sessionId'), headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Session not found');
    } else {
      throw Exception('Failed to fetch session (${response.statusCode})');
    }
  }

  /// Delete a session and clear its history.
  static Future<void> deleteSession(String sessionId) async {
    final headers = await AuthService.getAuthHeader();
    final response = await http
        .delete(Uri.parse('$kBaseUrl/ai/sessions/$sessionId'), headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete session (${response.statusCode})');
    }
  }

  /// Send an itinerary edit request to the AI service.
  ///
  /// This method is a placeholder for a backend endpoint that can propose
  /// itinerary changes. If the backend does not provide this endpoint,
  /// the current itinerary is returned unchanged.
  static Future<Map<String, dynamic>> editItinerary({
    required Map<String, dynamic> currentItinerary,
    required String editRequest,
    required String userId,
  }) async {
    try {
      final headers = await AuthService.getAuthHeader();
      headers['Content-Type'] = 'application/json';

      final response = await http
          .post(
            Uri.parse('$kBaseUrl/ai/edit-itinerary'),
            headers: headers,
            body: json.encode({
              'current_itinerary': currentItinerary,
              'edit_request': editRequest,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'proposed_itinerary': currentItinerary,
          'explanation': 'AI itinerary editing endpoint is unavailable.',
          'warnings': ['Edit itinerary service is unavailable on the backend.'],
        };
      }
    } catch (_) {
      return {
        'proposed_itinerary': currentItinerary,
        'explanation': 'AI itinerary editing is unavailable at this time.',
        'warnings': ['Failed to contact AI itinerary edit service.'],
      };
    }
  }

  /// Generate a unique session id.
  static String generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final seed = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[(seed + i) % chars.length]);
    }
    return buffer.toString();
  }
}
