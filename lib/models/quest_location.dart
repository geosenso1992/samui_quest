class QuestLocation {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final double unlockRadius; // in meters
  final String question;
  final String answer;

  // 🔤 NIEUW: Letter die wordt vrijgespeeld
  final String letter;

  /// image asset name used on the map style (quest_bronze / quest_silver / quest_gold)
  final String icon;

  // optional expiration – dynamic quests live for one hour
  final DateTime? expiresAt;

  QuestLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.unlockRadius,
    required this.question,
    required this.answer,

    // 🔤 verplicht maken in constructor
    required this.letter,

    required this.icon,

    // The new field is optional so existing callers keep working
    this.expiresAt,
  });
}
