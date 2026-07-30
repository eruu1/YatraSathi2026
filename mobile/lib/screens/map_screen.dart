import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/constants.dart';
import 'package:mobile/models/place.dart';
import 'package:mobile/services/place_service.dart';
import 'package:mobile/services/route_service.dart';
import 'package:mobile/services/user_session.dart';
import 'package:mobile/widgets/placeholder_image.dart';
import 'package:mobile/screens/place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Place> places;
  final VoidCallback onBack;

  const MapScreen({
    super.key,
    required this.places,
    required this.onBack,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Place? _selectedPlace;
  List<LatLng> _routePoints = [];
  double? _routeDistance, _routeDuration;
  bool _isRoutingLoading = false;
  final LatLng _ktm = const LatLng(27.7172, 85.3240);
  final RouteService _routeService = RouteService();
  final PlaceService _placeService = PlaceService();

  // Map-level search
  final TextEditingController _searchController = TextEditingController();
  List<Place> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchOnMap(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _showSearchResults = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final result = await _placeService.searchPlaces(query.trim(), limit: 20);
      if (!mounted) return;
      setState(() {
        _searchResults = result;
        _showSearchResults = true;
        _isSearching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Place p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedPlace = p;
      _showSearchResults = false;
      _searchController.clear();
    });
    _mapController.move(
        LatLng(p.safeLatitude - 0.04, p.safeLongitude), 13.0);
  }

  Color _markerColor(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'hindu temple':
      case 'buddhist temple':
      case 'place of worship':
      case 'pilgrimage place':
        return const Color(0xFFFF9800);
      case 'mountain range':
      case 'mountain peak':
      case 'hiking area':
        return const Color(0xFFE53935);
      case 'museum':
      case 'historical landmark':
        return const Color(0xFF7B1FA2);
      case 'lake':
      case 'river':
      case 'nature preserve':
      case 'national park':
        return const Color(0xFF2E7D32);
      case 'park':
      case 'campground':
        return const Color(0xFF43A047);
      default:
        return kOrange;
    }
  }

  IconData _markerIcon(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'hindu temple':
      case 'buddhist temple':
      case 'place of worship':
      case 'pilgrimage place':
        return Icons.temple_hindu;
      case 'mountain range':
      case 'mountain peak':
        return Icons.terrain;
      case 'hiking area':
        return Icons.directions_walk;
      case 'museum':
      case 'historical landmark':
        return Icons.account_balance;
      case 'lake':
      case 'river':
        return Icons.water;
      case 'national park':
      case 'nature preserve':
        return Icons.park;
      case 'church':
      case 'religious institution':
        return Icons.church;
      case 'campground':
        return Icons.cabin;
      default:
        return Icons.location_on;
    }
  }

  Future<void> _getRoute(Place dest) async {
    setState(() {
      _isRoutingLoading = true;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });
    
    try {
      debugPrint('Fetching route to ${dest.name}');
      final data = await _routeService.getRoute(
          _ktm, LatLng(dest.safeLatitude, dest.safeLongitude));
      debugPrint('Route data received: ${data.keys}');
      
      final geometry = data['geometry'];
      if (geometry != null && geometry['coordinates'] != null) {
        final coords = geometry['coordinates'] as List;
        debugPrint('Processing ${coords.length} route coordinates');
        
        setState(() {
          _routePoints = coords
              .map((c) {
                if (c is List && c.length >= 2) {
                  return LatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble());
                }
                return null;
              })
              .where((latLng) => latLng != null)
              .cast<LatLng>()
              .toList();
          _routeDistance =
              (data['distance_km'] as num?)?.toDouble();
          _routeDuration =
              (data['duration_minutes'] as num?)
                  ?.toDouble();
        });
        
        debugPrint('Route loaded: ${_routePoints.length} points, ${_routeDistance}km');
        
        if (_routePoints.isNotEmpty) {
          _mapController.fitCamera(CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([
              _ktm,
              LatLng(dest.safeLatitude, dest.safeLongitude),
              ..._routePoints
            ]),
            padding: const EdgeInsets.all(60),
          ));
        }
      } else {
        debugPrint('Invalid geometry in route response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Route data was empty. Try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Route error: $e');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Route service unavailable. ${e.toString().split(":").last.trim()}')),
        );
    } finally {
      if (mounted)
        setState(() => _isRoutingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.3949, 84.1240),
              initialZoom: 7.0,
              onTap: (_, __) => setState(() {
                _selectedPlace = null;
                _routePoints = [];
                _showSearchResults = false;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yatrasathi.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: <Polyline<Object>>[
                    Polyline(
                      points: _routePoints,
                      color: kOrange,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: [
                Marker(
                  point: _ktm,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location,
                        color: Colors.blue, size: 26),
                  ),
                ),
                ...widget.places.map((p) {
                  final selected = _selectedPlace?.id == p.id;
                  final color = _markerColor(p.category);
                  return Marker(
                    point: LatLng(p.safeLatitude, p.safeLongitude),
                    width: selected ? 52 : 40,
                    height: selected ? 52 : 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlace = p);
                        _mapController.move(
                            LatLng(p.safeLatitude - 0.04, p.safeLongitude),
                            12.0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : color,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: Icon(_markerIcon(p.category),
                            color: selected ? color : Colors.white,
                            size: selected ? 26 : 18),
                      ),
                    ),
                  );
                }),
                // Extra markers for search results not in widget.places
                ..._searchResults
                    .where((p) =>
                        !widget.places.any((wp) => wp.id == p.id))
                    .map((p) {
                  final selected = _selectedPlace?.id == p.id;
                  final color = _markerColor(p.category);
                  return Marker(
                    point: LatLng(p.safeLatitude, p.safeLongitude),
                    width: selected ? 52 : 40,
                    height: selected ? 52 : 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlace = p);
                        _mapController.move(
                            LatLng(p.safeLatitude - 0.04, p.safeLongitude),
                            12.0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : color,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: Icon(_markerIcon(p.category),
                            color: selected ? color : Colors.white,
                            size: selected ? 26 : 18),
                      ),
                    ),
                  );
                }),
              ]),
            ],
          ),

          // ── Top bar: back + search ──────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: kDark, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // Search bar
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _searchOnMap,
                      decoration: InputDecoration(
                        hintText: 'Search places on map...',
                        hintStyle: GoogleFonts.inter(
                            color: kGray, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: kGray, size: 18),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: kOrange),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close,
                                        color: kGray, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _showSearchResults = false;
                                      });
                                    },
                                  )
                                : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Search results dropdown ─────────────────────────────────────
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: topPad + 68,
              left: 72,
              right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: kBorder),
                    itemBuilder: (context, i) {
                      final p = _searchResults[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(_markerIcon(p.category),
                            color: _markerColor(p.category), size: 20),
                        title: Text(p.name,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${p.category}${p.safeDistrict.isNotEmpty ? " · ${p.safeDistrict}" : ""}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: kGray),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        onTap: () => _selectSearchResult(p),
                      );
                    },
                  ),
                ),
              ),
            ),

          // ── Place detail card ───────────────────────────────────────────
          if (_selectedPlace != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: _buildDetailCard(_selectedPlace!),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(Place place) {
    final isSaved = UserSession.savedPlaceIds.contains(place.id);
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: placeImage(place.imageUrl, place.category,
                    width: 72, height: 72),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kDark)),
                    const SizedBox(height: 2),
                    Text(
                        '${place.category}${place.safeDistrict.isNotEmpty ? " · ${place.safeDistrict}" : ""}',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: kGray)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star, size: 14, color: kOrange),
                      const SizedBox(width: 3),
                      Text(place.safeRating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kDark)),
                    ]),
                  ],
                ),
              ),
              // ── Save / unsave button ──────────────────────────────
              GestureDetector(
                onTap: () async {
                  await UserSession.toggleSave(place);
                  setState(() {}); // rebuild to reflect new save state
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          UserSession.savedPlaceIds.contains(place.id)
                              ? '${place.name} saved'
                              : '${place.name} removed from saved',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        backgroundColor:
                            UserSession.savedPlaceIds.contains(place.id)
                                ? kOrange
                                : kGray,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSaved
                        ? kOrange.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isSaved ? kOrange : kBorder, width: 1.5),
                  ),
                  child: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? kOrange : kGray,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Close button
              IconButton(
                onPressed: () => setState(() {
                  _selectedPlace = null;
                  _routePoints = [];
                }),
                icon: const Icon(Icons.close, color: kGray),
              ),
            ],
          ),
          if (_routeDistance != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: kOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [
                    const Icon(Icons.directions_car,
                        color: kOrange, size: 16),
                    const SizedBox(width: 4),
                    Text('${_routeDistance!.toStringAsFixed(0)} km',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: kDark,
                            fontSize: 13)),
                  ]),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        color: kOrange, size: 16),
                    const SizedBox(width: 4),
                    Text('${_routeDuration!.toStringAsFixed(0)} mins',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: kDark,
                            fontSize: 13)),
                  ]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isRoutingLoading ? null : () => _getRoute(place),
                icon: _isRoutingLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.navigation_outlined, size: 18),
                label: Text(
                    _routeDistance != null ? 'Reroute' : 'Route from KTM'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlaceDetailScreen(place: place))),
              style: OutlinedButton.styleFrom(
                foregroundColor: kDark,
                side: const BorderSide(color: kBorder),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
              child: Text('Details',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }
}