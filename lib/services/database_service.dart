import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Maak een nieuw gebruikersprofiel aan in Firestore
  Future<void> createNewUser(String uid, String username) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'points': 0, // Handig voor je quest game!
        'profile': {
          'username': username,
          'avatar': 'assets/monkey_player.png',
          'explorerSince': FieldValue.serverTimestamp(),
        },
        'stats': {
          'xp': 0,
          'level': 1,
          'coins': 0,
          'totalDistanceMeters': 0.0,
          'dailyDistanceMeters': {},
          'totalXpEarned': 0.0,
          'totalCoinsEarned': 0,
          'firstPlayedAt': FieldValue.serverTimestamp(),
        },
        'inventory': {
          'fruitInventory': {},
          'animalCollection': [],
          'achievements': {},
          'unlockedAnimals': [],
          'unlockedSeeds': [],
          'unlockedFruits': [],
          'collectedSpawnCounts': {},
          'collectedFruitCounts': {},
          'visitedLocations': [],
          'unlockedLetters': [],
          'garden': [],
        },
      });
    } catch (e) {
      print("Fout bij aanmaken gebruiker in database: $e");
      rethrow;
    }
  }
}
