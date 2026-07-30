import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/constants.dart';
import 'package:mobile/models/place.dart';
import 'package:mobile/services/place_service.dart';
import 'package:mobile/services/user_session.dart';
import 'package:mobile/screens/map_screen.dart';
import 'package:mobile/screens/place_detail_screen.dart';
import 'package:mobile/widgets/explore_card.dart';
import 'package:mobile/widgets/ai_chat_widget.dart';

class ExploreScreen extends StatefulWidget {
  final List<Place> places;
  const ExploreScreen({super.key, required this.places});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  bool _showMap = false;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final PlaceService _placeService = PlaceService();
  List<Place>? _searchResults; // null = not searched yet, use local filter
  bool _isSearching = false;
  String? _searchError;

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent rebuilt (tab switched back) — refresh save-state icons.
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Local filter on the base list — used when no backend search is active.
  List<Place> get _localFiltered {
    if (_searchQuery.isEmpty) return widget.places;
    final q = _searchQuery.toLowerCase();
    return widget.places.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.safeDistrict.toLowerCase().contains(q) ||
          p.safeDescription.toLowerCase().contains(q);
    }).toList();
  }

  /// The list currently displayed.
  List<Place> get _displayedPlaces =>
      _searchResults ?? _localFiltered;

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = null;
    });

    try {
      final results = await _placeService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Search failed. Check your connection.';
        _isSearching = false;
        _searchResults = null;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = null;
      _searchError = null;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMap) return _buildMapView();

    final bool hasActiveSearch = _searchResults != null;

    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('yatrasathi_logo.jpeg', width: 40, height: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Discover Nepal',
                            style: Theme.of(context).textTheme.displayMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onSubmitted: (_) => _runSearch(),
                    decoration: InputDecoration(
                      hintText: 'Lakes, temples, mountain roads...',
                      hintStyle: GoogleFonts.inter(color: kGray),
                      prefixIcon:
                          const Icon(Icons.search, color: kGray, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSearching)
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: kOrange),
                                    ),
                                  )
                                else ...[
                                  IconButton(
                                    icon: const Icon(Icons.search,
                                        color: kOrange, size: 20),
                                    tooltip: 'Search',
                                    onPressed: _runSearch,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: kGray, size: 20),
                                    tooltip: 'Clear',
                                    onPressed: _clearSearch,
                                  ),
                                ],
                              ],
                            )
                          : null,
                    ),
                  ),
                  // Active search badge
                  if (hasActiveSearch) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            '${_displayedPlaces.length} result${_displayedPlaces.length == 1 ? '' : 's'} for "${_searchController.text.trim()}"',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: kOrange,
                          deleteIcon: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                          onDeleted: _clearSearch,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                  if (_searchError != null) ...[
                    const SizedBox(height: 6),
                    Text(_searchError!,
                        style:
                            GoogleFonts.inter(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: kOrange))
                  : _displayedPlaces.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off,
                                  size: 48, color: kGray),
                              const SizedBox(height: 12),
                              Text(
                                hasActiveSearch
                                    ? 'No places found for "${_searchController.text.trim()}"'
                                    : 'No places found',
                                style: GoogleFonts.inter(color: kGray),
                                textAlign: TextAlign.center,
                              ),
                              if (hasActiveSearch) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _clearSearch,
                                  child: Text('Clear search',
                                      style: GoogleFonts.inter(
                                          color: kOrange,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _displayedPlaces.length,
                          itemBuilder: (context, i) {
                            final place = _displayedPlaces[i];
                            return ExploreCard(
                              place: place,
                              isSaved: UserSession.savedPlaceIds
                                  .contains(place.id),
                              onSave: () async {
                                await UserSession.toggleSave(place);
                                setState(() {});
                              },
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PlaceDetailScreen(place: place))),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'ai_chat',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AIChatWidget(
                  screenContext: 'explore',
                  screenData: {
                    'search_query': _searchController.text.trim(),
                  },
                ),
              );
            },
            backgroundColor: kOrange,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'map',
            onPressed: () => setState(() => _showMap = true),
            backgroundColor: kDark,
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            label: Text('See map',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return MapScreen(
      places: widget.places,
      onBack: () => setState(() => _showMap = false),
    );
  }
}
