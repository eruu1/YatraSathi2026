/// Normalized place-name → primary local asset image path.
///
/// Keys are lowercase, stripped of extra words like "(monkey temple)",
/// "(lumbini)", "nepal", etc. so fuzzy lookups work across data sources.
const Map<String, String> assetsMap = {
  'swayambhunath stupa':          'asset_images/Swayambhunath Stupa/swayambhunath-temple-kathmandu-nepal-ECYENF.jpg',
  'swayambhu mahachaitya':        'asset_images/Swayambhunath Stupa/swayambhunath-temple-kathmandu-nepal-ECYENF.jpg',
  'pashupatinath temple':         'asset_images/Pashupatinath Temple/images.jpg',
  'boudhanath stupa':             'asset_images/Boudhanath Stupa/images.jpg',
  'phewa lake':                   'asset_images/Phewa Lake/images.jpg',
  'world peace pagoda':           'asset_images/World Peace Pagoda/stupa.jpg',
  'davis falls':                  'asset_images/Davis Falls/images.jpg',
  'chitwan national park':        'asset_images/Chitwan National Park/images.jpg',
  'elephant breeding center':     'asset_images/Elephant Breeding Center/images.jpg',
  'rapti river sunset point':     'asset_images/Rapti River Sunset Point/maxresdefault.jpg',
  'maya devi temple':             'asset_images/Lumbini mayadevi temple/images.jpg',
  'lumbini sacred garden':        'asset_images/Lumbini mayadevi temple/images (1).jpg',
  'bhaktapur durbar square':      'asset_images/Bhaktapur Durbar Square/images.jpg',
  'nyatapola temple':             'asset_images/Nyatapola Temple/Nyatapola-Temple-.jpg',
  '55-window palace':             'asset_images/55-Window Palace/images.jpg',
  'gosaikunda lake':              'asset_images/gosaikunda lake/images.jpg',
  'bandipur':                     'asset_images/bandipur/download.jpg',
  'janaki temple':                'asset_images/Janaki Temple/images.jpg',
  'nagarkot sunrise view park':   'asset_images/Swayambhunath Stupa/image3.jpg',
  'muktinath temple':             'asset_images/World Peace Pagoda/stupa.jpg',
  'namche bazar':                 'asset_images/Swayambhunath Stupa/image3.jpg',
};

/// Returns the local asset path for a place name, or null if not found.
/// Matching is case-insensitive and strips common suffixes for broad coverage.
String? assetImageFor(String placeName) {
  final key = placeName
      .toLowerCase()
      .replaceAll(RegExp(r'\(monkey temple\)|\(lumbini\)|, nepal'), '')
      .trim();

  // Exact match first
  if (assetsMap.containsKey(key)) return assetsMap[key];

  // Partial / contains match
  for (final entry in assetsMap.entries) {
    if (key.contains(entry.key) || entry.key.contains(key)) {
      return entry.value;
    }
  }
  return null;
}
