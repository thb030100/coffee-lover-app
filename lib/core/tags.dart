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
];

bool isKnownTag(String tag) => kShopTagVocabulary.contains(tag);
