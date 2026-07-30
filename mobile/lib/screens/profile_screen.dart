import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/constants.dart';
import 'package:mobile/services/user_session.dart';
import 'package:mobile/screens/auth_gate.dart';
import 'package:mobile/widgets/ai_chat_widget.dart';
import 'package:mobile/services/place_service.dart';
import 'package:mobile/models/place.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Place> _localPlaces = [];

  @override
  void initState() {
    super.initState();
    _refreshSessionData();
  }

  Future<void> _refreshSessionData() async {
    // Try to refresh backend-backed session data; non-fatal if it fails.
    await UserSession.loadFromStorage();
    // Load static assets for display in profile (non-blocking)
    try {
      final service = PlaceService();
      final places = await service.fetchPlaces();
      if (mounted) setState(() => _localPlaces = places.take(6).toList());
    } catch (e) {
      debugPrint('[ProfileScreen] failed to load local assets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Image.asset('yatrasathi_logo.jpeg', width: 64, height: 64),
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: kOrange,
                    child: Text(
                      UserSession.initials(
                          UserSession.loggedInUser),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      UserSession.loggedInUser ??
                          'Explorer',
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kDark)),
                  const SizedBox(height: 4),
                  Text(
                      UserSession.email ??
                          'guest@yatrasathi.com',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: kGray)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Static asset preview section
            if (_localPlaces.isNotEmpty) ...[
              Text('RECOMMENDED PLACES',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _localPlaces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final p = _localPlaces[i];
                    final img = p.imageUrl.isNotEmpty
                        ? p.imageUrl
                        : null;
                    return Container(
                      width: 200,
                      decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: (img != null && img.startsWith('http'))
                                  ? Image.network(img, fit: BoxFit.cover, width: double.infinity)
                                  : (img != null ? Image.asset(img, fit: BoxFit.cover, width: double.infinity) : Container(color: kBorder)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],
            Row(
              children: [
                _statCard('Trips Created',
                    '${UserSession.savedItineraries.length}'),
                const SizedBox(width: 12),
                _statCard('Places Saved',
                    '${UserSession.savedPlaceIds.length}'),
                const SizedBox(width: 12),
                _statCard('Community Trips',
                    '${UserSession.publicItineraries.length}'),
              ],
            ),
            const SizedBox(height: 28),
            Text('SETTINGS',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    backgroundColor: kCardBg,
                    collapsedBackgroundColor: kCardBg,
                    leading: Icon(Icons.help_outline,
                        color: kGray, size: 20),
                    title: Text('Help & Support',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kDark)),
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Get help with itinerary planning, bookings, and app features. Our support team is ready to assist with travel recommendations, saved places, and route details.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: kGray),
                      ),
                      const SizedBox(height: 10),
                      Text('Support email: support@yatrasathi.com',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: kDark)),
                      const SizedBox(height: 6),
                      Text('Tip: Use this section when you need help with planning a trip or managing saved routes.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: kGray)),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    backgroundColor: kCardBg,
                    collapsedBackgroundColor: kCardBg,
                    leading: Icon(Icons.info_outline,
                        color: kGray, size: 20),
                    title: Text('About Us',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kDark)),
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'YatraSathi is your travel companion for creating personalized itineraries, discovering new places, and saving trips for later.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: kGray),
                      ),
                      const SizedBox(height: 10),
                      Text('Built to simplify travel planning, share community trips, and help you explore routes with confidence.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: kGray)),
                      const SizedBox(height: 10),
                      Text('App version: 1.0.0',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: kDark)),
                    ],
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    tileColor: kCardBg,
                    leading: Icon(Icons.logout,
                        color: kOrange, size: 20),
                    title: Text('Logout',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kDark)),
                    trailing: const Icon(Icons.chevron_right,
                        color: kGray, size: 20),
                    onTap: () {
                      UserSession.clearSessionOnLogout();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthGate()));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AIChatWidget(
              screenContext: 'profile',
              screenData: {
                'username': UserSession.loggedInUser,
                'email': UserSession.email,
              },
            ),
          );
        },
        backgroundColor: kOrange,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
    );
  }

  Widget _statCard(String label, String value) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
              vertical: 14),
          decoration: BoxDecoration(
              color: kCardBg,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(color: kBorder)),
          child: Column(children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: kOrange)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: kGray),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}