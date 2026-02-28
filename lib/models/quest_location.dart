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
  });
}