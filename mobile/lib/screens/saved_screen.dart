import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/constants.dart';
import 'package:mobile/models/place.dart';
import 'package:mobile/services/user_session.dart';
import 'package:mobile/widgets/placeholder_image.dart';
import 'package:mobile/screens/place_detail_screen.dart';
import 'package:mobile/screens/saved_itinerary_detail_screen.dart';
import 'package:mobile/widgets/ai_chat_widget.dart';

class SavedScreen extends StatefulWidget {
  final List<Place> places;
  const SavedScreen({super.key, required this.places});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncFromBackend();
  }

  @override
  void didUpdateWidget(covariant SavedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tab switched back — re-sync so any saves made elsewhere appear instantly.
    _syncFromBackend();
  }

  Future<void> _syncFromBackend() async {
    if (_syncing || !mounted) return;
    setState(() => _syncing = true);
    await UserSession.syncFromBackend();
    if (!mounted) return;
    setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final savedPlaces = List<Place>.from(UserSession.savedPlaces);
    final savedIts = UserSession.savedItineraries;

    return Scaffold(
      backgroundColor: kCream,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Saved',
                        style: Theme.of(context).textTheme.displayMedium),
                  ),
                  // Sync indicator / manual refresh button
                  if (_syncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kOrange),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.sync, color: kGray, size: 22),
                      tooltip: 'Refresh from server',
                      onPressed: _syncFromBackend,
                    ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: kOrange,
              labelColor: kOrange,
              unselectedLabelColor: kGray,
              tabs: [
                Tab(text: 'Places'),
                Tab(text: 'Roadtrips'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // ── Places tab ─────────────────────────────────────────
                  savedPlaces.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 64, color: kBorder),
                              const SizedBox(height: 12),
                              Text('No saved places yet',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, color: kGray)),
                              const SizedBox(height: 6),
                              Text('Tap ❤ on any place to save it',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: kGray)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: savedPlaces.length,
                          itemBuilder: (ctx, i) {
                            final place = savedPlaces[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kBorder),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  tileColor: kCardBg,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: placeImage(
                                        place.imageUrl, place.category,
                                        width: 60, height: 60),
                                  ),
                                  title: Text(
                                    place.name,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: kDark),
                                  ),
                                  subtitle: Text(
                                    place.safeDistrict.isNotEmpty
                                        ? '${place.category} · ${place.safeDistrict}'
                                        : place.category,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: kGray),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.favorite,
                                        color: kOrange, size: 20),
                                    tooltip: 'Remove from saved',
                                    onPressed: () async {
                                      await UserSession.toggleSave(place);
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                  onTap: () => Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PlaceDetailScreen(place: place),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                  // ── Roadtrips tab ──────────────────────────────────────
                  savedIts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_outlined,
                                  size: 64, color: kBorder),
                              const SizedBox(height: 12),
                              Text('No saved roadtrips yet',
                                  style: GoogleFonts.inter(
                                      fontSize: 16, color: kGray)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: savedIts.length,
                          itemBuilder: (ctx, i) {
                            final it = savedIts[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kBorder),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  tileColor: kCardBg,
                                  title: Text(it.title,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: kDark)),
                                  subtitle: Text(
                                    '${it.from} → ${it.to} · ${it.days} Days',
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: kGray),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    onPressed: () => setState(() {
                                      UserSession.savedItineraries.removeAt(i);
                                    }),
                                  ),
                                  onTap: () => Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SavedItineraryDetailScreen(
                                              itinerary: it),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
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
              screenContext: 'saved',
              screenData: {
                'saved_places_count': UserSession.savedPlaces.length,
                'saved_itineraries_count': UserSession.savedItineraries.length,
              },
            ),
          );
        },
        backgroundColor: kOrange,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
    );
  }
}
