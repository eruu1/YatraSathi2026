import 'package:flutter/foundation.dart';
import 'package:mobile/models/place.dart';
import 'package:mobile/models/created_itinerary.dart';
import 'package:mobile/services/user_storage.dart';
import 'package:mobile/services/saved_places_service.dart';
import 'package:mobile/services/itinerary_service.dart';
import 'package:latlong2/latlong.dart';

class UserSession {
  static String? loggedInUser;
  static String? email;

  /// IDs of saved places — kept for quick membership checks.
  static Set<String> savedPlaceIds = {};

  /// Full Place objects — the source of truth for SavedScreen.
  /// Always kept in sync with [savedPlaceIds].
  static List<Place> savedPlaces = [];

  static List<CreatedItinerary> savedItineraries = [];
  static List<CreatedItinerary> publicItineraries = [
    CreatedItinerary(
      id: 'pub1',
      title: 'A monsoon weekend in Bandipur',
      from: 'Kathmandu',
      to: 'Bandipur',
      days: 2,
      travelers: 1,
      budget: 'Rs 10,000',
      pace: 'Balanced',
      diet: 'Veg',
      author: 'Sita',
      likes: 248,
      isPublic: true,
      itinerary: {
        'Day 1': [
          {
            'time': '9:00 AM',
            'name': 'Thani Mai Temple Viewpoint',
            'category': 'Spirituality',
            'duration': '2 hrs'
          },
          {
            'time': '2:00 PM',
            'name': 'Siddha Gufa Cave',
            'category': 'Adventure',
            'duration': '3 hrs'
          },
          {
            'time': '7:00 PM',
            'name': 'Local Newari dinner',
            'category': 'Food',
            'duration': '1 hr'
          }
        ]
      },
      orderedWaypoints: [
        Place(
            id: 'start',
            name: 'Kathmandu',
            category: 'Origin',
            district: '',
            province: '',
            city: 'Kathmandu',
            description: '',
            history: '',
            latitude: 27.7172,
            longitude: 85.3240,
            images: [],
            hasTicket: false),
        Place(
            id: 'w1',
            name: 'Bandipur Bazaar',
            category: 'Culture',
            district: 'Tanahun',
            province: 'Gandaki',
            city: 'Bandipur',
            description: '',
            history: '',
            latitude: 27.9389,
            longitude: 84.4167,
            images: [],
            hasTicket: false),
        Place(
            id: 'end',
            name: 'Bandipur',
            category: 'Destination',
            district: '',
            province: '',
            city: 'Bandipur',
            description: '',
            history: '',
            latitude: 27.9389,
            longitude: 84.4167,
            images: [],
            hasTicket: false)
      ],
      routePoints: [
        const LatLng(27.7172, 85.3240),
        const LatLng(27.9389, 84.4167)
      ],
      distanceKm: 148.0,
      durationMinutes: 240.0,
    ),
    CreatedItinerary(
      id: 'pub2',
      title: 'Family loop through Chitwan',
      from: 'Kathmandu',
      to: 'Chitwan',
      days: 5,
      travelers: 4,
      budget: 'Rs 70,000',
      pace: 'Relaxed',
      diet: 'Non-veg',
      author: 'Rohan',
      likes: 412,
      isPublic: true,
      itinerary: {
        'Day 1': [
          {
            'time': '10:00 AM',
            'name': 'Chitwan National Park Safari',
            'category': 'Wildlife',
            'duration': '4 hrs'
          },
          {
            'time': '7:00 PM',
            'name': 'Tharu Culture Dance Show',
            'category': 'Culture',
            'duration': '2 hrs'
          }
        ]
      },
      orderedWaypoints: [
        Place(
            id: 'start',
            name: 'Kathmandu',
            category: 'Origin',
            district: '',
            province: '',
            city: 'Kathmandu',
            description: '',
            history: '',
            latitude: 27.7172,
            longitude: 85.3240,
            images: [],
            hasTicket: false),
        Place(
            id: 'w1',
            name: 'Sauraha Chitwan',
            category: 'Wildlife',
            district: 'Chitwan',
            province: 'Bagmati',
            city: 'Chitwan',
            description: '',
            history: '',
            latitude: 27.5291,
            longitude: 84.3542,
            images: [],
            hasTicket: false),
        Place(
            id: 'end',
            name: 'Chitwan',
            category: 'Destination',
            district: '',
            province: '',
            city: 'Chitwan',
            description: '',
            history: '',
            latitude: 27.5291,
            longitude: 84.3542,
            images: [],
            hasTicket: false)
      ],
      routePoints: [
        const LatLng(27.7172, 85.3240),
        const LatLng(27.5291, 84.3542)
      ],
      distanceKm: 160.0,
      durationMinutes: 300.0,
    ),
    // ── Default 3-day Kathmandu Valley & Pokhara itinerary ────────────────
    CreatedItinerary(
      id: 'default_3day_ktm',
      title: '3 Days in Kathmandu & Pokhara',
      from: 'Kathmandu',
      to: 'Pokhara',
      days: 3,
      travelers: 2,
      budget: 'Rs 25,000',
      pace: 'Balanced',
      diet: 'Veg',
      author: 'YatraSathi',
      likes: 512,
      isPublic: true,
      itinerary: {
        'Day 1': [
          {
            'time': '7:00 AM',
            'name': 'Pashupatinath Temple',
            'category': 'Religious Site',
            'duration': '2 hrs',
            'notes':
                'Arrive early to witness the morning aarti ceremony on the Bagmati riverbank. Dress modestly; non-Hindus view from the eastern bank.',
          },
          {
            'time': '10:00 AM',
            'name': 'Boudhanath Stupa',
            'category': 'Religious Site',
            'duration': '2 hrs',
            'notes':
                'Walk the kora (circumambulation) clockwise around the great stupa. Browse Tibetan craft shops in the surrounding lanes.',
          },
          {
            'time': '1:00 PM',
            'name': 'Thamel Lunch Break',
            'category': 'Food',
            'duration': '1 hr',
            'notes': 'Dal-bhat set meal at a rooftop restaurant in Thamel.',
          },
          {
            'time': '3:00 PM',
            'name': 'Swayambhunath Stupa (Monkey Temple)',
            'category': 'Religious Site',
            'duration': '2 hrs',
            'notes':
                'Climb the 365 stone steps for panoramic views of Kathmandu Valley. Watch resident monkeys and spinning prayer wheels.',
          },
          {
            'time': '7:00 PM',
            'name': 'Thamel Evening & Dinner',
            'category': 'Food',
            'duration': '2 hrs',
            'notes': 'Explore Thamel night market; dine on Newari momo and tongba.',
          },
        ],
        'Day 2': [
          {
            'time': '8:00 AM',
            'name': 'Bhaktapur Durbar Square',
            'category': 'Attraction',
            'duration': '2.5 hrs',
            'notes':
                'Entry fee required (Rs 1,500 for foreigners). Explore the 55-Window Palace, Golden Gate, and pottery square.',
          },
          {
            'time': '11:00 AM',
            'name': 'Nyatapola Temple',
            'category': 'Religious Site',
            'duration': '1 hr',
            'notes':
                'Climb Nepal\'s tallest pagoda-style temple for a view over Bhaktapur\'s terracotta rooftops.',
          },
          {
            'time': '12:30 PM',
            'name': '55-Window Palace',
            'category': 'Attraction',
            'duration': '45 min',
            'notes':
                'Admire intricate Newari woodcarving on the 55 latticed windows; built by King Yaksha Malla in 1427.',
          },
          {
            'time': '2:00 PM',
            'name': 'Juju Dhau (Curd) & Bhaktapur Streets',
            'category': 'Food',
            'duration': '1 hr',
            'notes':
                'Try the famous Bhaktapur yoghurt served in clay pots. Browse traditional Newari woodcraft stalls.',
          },
          {
            'time': '4:00 PM',
            'name': 'Nagarkot Sunset Drive',
            'category': 'Viewpoint',
            'duration': '3 hrs',
            'notes':
                'Short drive up to Nagarkot (1,895 m) for Himalayan panorama including Everest on clear days. Return to Kathmandu for overnight.',
          },
        ],
        'Day 3': [
          {
            'time': '6:30 AM',
            'name': 'Drive to Pokhara (tourist bus)',
            'category': 'Travel',
            'duration': '6 hrs',
            'notes':
                'Scenic Prithvi Highway following the Trishuli River. Arrive Pokhara by noon.',
          },
          {
            'time': '1:00 PM',
            'name': 'Phewa Lake Boat Ride',
            'category': 'Attraction',
            'duration': '2 hrs',
            'notes':
                'Rent a wooden rowboat (Rs 800/hr) and paddle to Tal Barahi Temple on the island. Annapurna reflections on calm mornings.',
          },
          {
            'time': '3:30 PM',
            'name': 'Davis Falls',
            'category': 'Attraction',
            'duration': '45 min',
            'notes':
                'Watch the Patale Chhango waterfall disappear into its underground tunnel. Connected to the nearby Gupteshwor Cave.',
          },
          {
            'time': '5:00 PM',
            'name': 'World Peace Pagoda',
            'category': 'Religious Site',
            'duration': '1.5 hrs',
            'notes':
                'Hike or take a boat + trail to the hilltop stupa for a 360° view of Pokhara, Phewa Lake, and the Annapurna range at sunset.',
          },
          {
            'time': '7:30 PM',
            'name': 'Lakeside Dinner',
            'category': 'Food',
            'duration': '1.5 hrs',
            'notes':
                'Dine lakeside on Fish Thali or wood-fired pizza at one of the Phewa lakeshore restaurants.',
          },
        ],
      },
      orderedWaypoints: [
        Place(
          id: 'wp_ktm',
          name: 'Kathmandu',
          category: 'Origin',
          latitude: 27.7172,
          longitude: 85.3240,
          images: ['asset_images/Pashupatinath Temple/images.jpg'],
        ),
        Place(
          id: 'wp_pashupatinath',
          name: 'Pashupatinath Temple',
          category: 'Religious Site',
          latitude: 27.7104,
          longitude: 85.3488,
          images: [
            'asset_images/Pashupatinath Temple/images.jpg',
            'asset_images/Pashupatinath Temple/images (1).jpg',
          ],
        ),
        Place(
          id: 'wp_boudhanath',
          name: 'Boudhanath Stupa',
          category: 'Religious Site',
          latitude: 27.7215,
          longitude: 85.3620,
          images: [
            'asset_images/Boudhanath Stupa/images.jpg',
            'asset_images/Boudhanath Stupa/images (1).jpg',
          ],
        ),
        Place(
          id: 'wp_swayambhu',
          name: 'Swayambhunath Stupa',
          category: 'Religious Site',
          latitude: 27.7149,
          longitude: 85.2900,
          images: [
            'asset_images/Swayambhunath Stupa/images.jpg',
            'asset_images/Swayambhunath Stupa/swayambhunath-temple-kathmandu-nepal-ECYENF.jpg',
          ],
        ),
        Place(
          id: 'wp_bhaktapur',
          name: 'Bhaktapur Durbar Square',
          category: 'Attraction',
          latitude: 27.6723,
          longitude: 85.4281,
          images: [
            'asset_images/Bhaktapur Durbar Square/images.jpg',
            'asset_images/Bhaktapur Durbar Square/images (1).jpg',
          ],
        ),
        Place(
          id: 'wp_nyatapola',
          name: 'Nyatapola Temple',
          category: 'Religious Site',
          latitude: 27.6710,
          longitude: 85.4298,
          images: [
            'asset_images/Nyatapola Temple/Nyatapola-Temple-.jpg',
            'asset_images/Nyatapola Temple/images.jpg',
          ],
        ),
        Place(
          id: 'wp_phewa',
          name: 'Phewa Lake',
          category: 'Attraction',
          latitude: 28.2096,
          longitude: 83.9596,
          images: [
            'asset_images/Phewa Lake/images.jpg',
            'asset_images/Phewa Lake/images (1).jpg',
          ],
        ),
        Place(
          id: 'wp_davis',
          name: 'Davis Falls',
          category: 'Attraction',
          latitude: 28.1918,
          longitude: 83.9583,
          images: [
            'asset_images/Davis Falls/images.jpg',
            'asset_images/Davis Falls/images (1).jpg',
          ],
        ),
        Place(
          id: 'wp_pagoda',
          name: 'World Peace Pagoda',
          category: 'Religious Site',
          latitude: 28.2007,
          longitude: 83.9446,
          images: [
            'asset_images/World Peace Pagoda/stupa.jpg',
            'asset_images/World Peace Pagoda/images.jpg',
          ],
        ),
        Place(
          id: 'wp_pkr',
          name: 'Pokhara',
          category: 'Destination',
          latitude: 28.2096,
          longitude: 83.9856,
          images: ['asset_images/Phewa Lake/images.jpg'],
        ),
      ],
      routePoints: [
        const LatLng(27.7172, 85.3240),  // Kathmandu
        const LatLng(27.7104, 85.3488),  // Pashupatinath
        const LatLng(27.7215, 85.3620),  // Boudhanath
        const LatLng(27.7149, 85.2900),  // Swayambhu
        const LatLng(27.6723, 85.4281),  // Bhaktapur
        const LatLng(27.6710, 85.4298),  // Nyatapola
        const LatLng(28.2096, 83.9596),  // Phewa Lake
        const LatLng(28.1918, 83.9583),  // Davis Falls
        const LatLng(28.2007, 83.9446),  // World Peace Pagoda
        const LatLng(28.2096, 83.9856),  // Pokhara
      ],
      distanceKm: 210.0,
      durationMinutes: 420.0,
    ),
  ];

  static Future<void> loadFromStorage() async {
    final session = await UserStorage.loadSession();
    loggedInUser = session['user'];
    email = session['email'];
    // Load full place objects first — ids are derived from them.
    savedPlaces = await UserStorage.loadPlaceObjects();
    savedPlaceIds = savedPlaces.map((p) => p.id).toSet();
    // Back-fill ids that were saved before full-object persistence existed.
    final legacyIds = await UserStorage.loadPlaceIds();
    savedPlaceIds.addAll(legacyIds);
    // If we have a logged-in user, try to sync live data from the backend.
    if (loggedInUser != null && loggedInUser!.isNotEmpty) {
      try {
        // 1) Sync saved places from server (merge remote -> local)
        final svc = SavedPlacesService();
        final remotePlaces = await svc.fetchSavedPlaces(loggedInUser!);
        // Upsert remote places into local cache
        for (final p in remotePlaces) {
          if (!savedPlaceIds.contains(p.id)) {
            savedPlaces.add(p);
            savedPlaceIds.add(p.id);
          }
        }

        // 2) Fetch created itineraries for this user
        final created = await ItineraryService.getMyItineraries();
        savedItineraries = created
            .map((m) => CreatedItinerary.fromMap(m))
            .toList(growable: true);

        // 3) Fetch public/community itineraries
        final publicList = await ItineraryService.getPublicItineraries();
        publicItineraries = publicList
            .map((m) => CreatedItinerary.fromMap(m))
            .toList(growable: true);

        // Persist merged saved places locally
        await persist();
      } catch (e) {
        debugPrint('[UserSession] backend sync failed (non-fatal): $e');
      }
    }
  }

  static Future<void> clearSessionOnLogout() async {
    loggedInUser = null;
    email = null;
    await UserStorage.clearSession();
  }

  /// Toggle save state for [place].
  /// 1. Optimistically updates in-memory state immediately.
  /// 2. Persists to local SharedPreferences.
  /// 3. Syncs to backend DB (fire-and-forget, never blocks the UI).
  static Future<void> toggleSave(Place place) async {
    final wasSaved = savedPlaceIds.contains(place.id);

    // ── 1. Optimistic local update ────────────────────────────────────
    if (wasSaved) {
      savedPlaceIds.remove(place.id);
      savedPlaces.removeWhere((p) => p.id == place.id);
    } else {
      savedPlaceIds.add(place.id);
      savedPlaces.add(place);
    }

    // ── 2. Local persistence ──────────────────────────────────────────
    await persist();

    // ── 3. Backend sync (best-effort, no throw) ───────────────────────
    final userId = loggedInUser;
    if (userId != null && userId.isNotEmpty) {
      try {
        final svc = SavedPlacesService();
        if (wasSaved) {
          await svc.unsavePlace(userId: userId, placeId: place.id);
        } else {
          await svc.savePlace(userId: userId, place: place);
        }
      } catch (e) {
        // Non-fatal — local state is already correct.
        debugPrint('[UserSession] Backend save sync failed (non-fatal): $e');
      }
    }
  }

  /// Sync saved places FROM the backend into local state.
  /// Called on app start (after login) and when SavedScreen becomes visible.
  /// Always falls back to local state if the server is unreachable.
  static Future<void> syncFromBackend() async {
    final userId = loggedInUser;
    if (userId == null || userId.isEmpty) return;
    try {
      final svc = SavedPlacesService();
      final remote = await svc.fetchSavedPlaces(userId);
      // Merge: remote is source of truth; preserve any local-only items
      // (saved while offline) by upserting them.
      final remoteIds = remote.map((p) => p.id).toSet();
      // Add local items not yet on the server
      final localOnly =
          savedPlaces.where((p) => !remoteIds.contains(p.id)).toList();
      savedPlaces = [...remote, ...localOnly];
      savedPlaceIds = savedPlaces.map((p) => p.id).toSet();
      await persist();
    } catch (e) {
      debugPrint('[UserSession] syncFromBackend failed (non-fatal): $e');
    }
  }

  static Future<void> persist() async {
    if (loggedInUser != null && email != null) {
      await UserStorage.saveSession(
          user: loggedInUser!, email: email!);
    }
    await UserStorage.savePlaceIds(savedPlaceIds);
    await UserStorage.savePlaceObjects(savedPlaces);
  }

  static String initials(String? name) {
    final value = (name ?? 'EX').trim();
    if (value.isEmpty) return 'EX';
    if (value.length == 1) return value.toUpperCase();
    return value.substring(0, 2).toUpperCase();
  }
}