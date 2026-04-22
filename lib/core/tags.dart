// Controlled vocabulary for shop tags.
// Keep this in sync with the admin ingestion tool's tag picker.
// Tags are lowercase, snake_case, ASCII-only.
const List<String> kShopTagVocabulary = [
  // Vibe
  'quiet',
  'lively',
  'cozy',
  'minimalist',
  'traditional',
  'instagrammable',
  // Work suitability
  'wifi',
  'power_outlets',
  'work_friendly',
  'meeting_friendly',
  // Setting
  'outdoor',
  'rooftop',
  'garden',
  'alleyway',
  'view',
  // Coffee style
  'specialty',
  'vietnamese_traditional',
  'egg_coffee',
  'coconut_coffee',
  'drip_phin',
  'pour_over',
  'espresso',
  // Menu beyond coffee
  'food',
  'brunch',
  'bakery',
  'tea',
  // Practicality
  'open_late',
  'open_early',
  'pet_friendly',
  'cash_only',
  'smoking_allowed',
  'car_parking',
  'cake',
];

bool isKnownTag(String tag) => kShopTagVocabulary.contains(tag);

/// Human-readable display names for tags shown in the UI.
const Map<String, String> kTagDisplayNames = {
  'quiet': 'Quiet',
  'lively': 'Lively',
  'cozy': 'Cozy',
  'minimalist': 'Minimalist',
  'traditional': 'Traditional',
  'instagrammable': 'Instagrammable',
  'wifi': 'Wi-Fi',
  'power_outlets': 'Power Outlets',
  'work_friendly': 'Work Friendly',
  'meeting_friendly': 'Meeting Friendly',
  'outdoor': 'Outdoor',
  'rooftop': 'Rooftop',
  'garden': 'Garden',
  'alleyway': 'Alleyway',
  'view': 'With a View',
  'specialty': 'Specialty',
  'vietnamese_traditional': 'Vietnamese Style',
  'egg_coffee': 'Egg Coffee',
  'coconut_coffee': 'Coconut Coffee',
  'drip_phin': 'Drip Phin',
  'pour_over': 'Pour Over',
  'espresso': 'Espresso',
  'food': 'Food',
  'brunch': 'Brunch',
  'bakery': 'Bakery',
  'tea': 'Tea',
  'open_late': 'Open Late',
  'open_early': 'Opens Early',
  'pet_friendly': 'Pet Friendly',
  'cash_only': 'Cash Only',
  'smoking_allowed': 'Smoking OK',
  'car_parking': 'Parking',
  'cake': 'Cakes',
};

/// Returns a display-ready label for [tag].
/// Falls back to title-casing the snake_case identifier.
String displayTag(String tag) {
  if (kTagDisplayNames.containsKey(tag)) return kTagDisplayNames[tag]!;
  return tag
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
