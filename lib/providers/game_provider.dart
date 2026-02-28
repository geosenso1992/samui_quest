import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/quest_location.dart';
import '../services/location_service.dart';
import '../utils/distance_helper.dart';
import '../services/spawn_service.dart';
import '../models/map_spawn.dart';

class GameProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final SpawnService _spawnService = SpawnService();

  // ================= SPAWN SYSTEM =================

  List<MapSpawn> get activeSpawns => _spawnService.activeSpawns;

  void setSpawnVisibility(String id, bool visible) {
  final spawn = _spawnService.activeSpawns
      .firstWhere((s) => s.id == id);

  spawn.isVisible = visible;
  notifyListeners();
}

  // =================================================

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  double _heading = 0.0;
  double get heading => _heading;

  List<QuestLocation> _locations = [];
  List<QuestLocation> get locations => _locations;

  final Set<String> _unlockedLocations = {};
  Set<String> get unlockedLocations => _unlockedLocations;

  final Set<String> _visitedLocations = {};
  Set<String> get visitedLocations => _visitedLocations;

  final Set<String> _unlockedLetters = {};
  Set<String> get unlockedLetters => _unlockedLetters;

  StreamSubscription<Position>? _positionSubscription;

  // ================= XP SYSTEM =================

  int _xp = 0;
  int _level = 1;

  int get xp => _xp;
  int get level => _level;
  int get xpNeeded => _level * 100;

  void addXP(int amount) {
    _xp += amount;

    while (_xp >= xpNeeded) {
      _xp -= xpNeeded;
      _level++;
    }

    notifyListeners();
  }

  // ================= SPAWN COLLECTION =================

  void collectSpawn(MapSpawn spawn) {
    if (spawn.type == SpawnType.animal) {
      addXP(5);
      _unlockedAnimals.add(spawn.asset);
    } else {
      addXP(1);
      _unlockedSeeds.add(spawn.asset);
    }

    _spawnService.removeSpawn(spawn.id);

    notifyListeners();
  }

  // ================= ANIMAL & SEED SYSTEM =================

  final Set<String> _unlockedAnimals = {};
  final Set<String> _unlockedSeeds = {};

  Set<String> get unlockedAnimals => _unlockedAnimals;
  Set<String> get unlockedSeeds => _unlockedSeeds;

  bool isAnimalUnlocked(String type) =>
      _unlockedAnimals.contains(type);

  bool isSeedUnlocked(String type) =>
      _unlockedSeeds.contains(type);

  // ================= LETTER SYSTEM =================

  void unlockLetter(String letter) {
    letter = letter.toUpperCase();

    if (!_unlockedLetters.contains(letter)) {
      _unlockedLetters.add(letter);
      notifyListeners();
    }
  }

  String? getLetterForLocation(String locationId) {
    try {
      final location =
          _locations.firstWhere((loc) => loc.id == locationId);
      return location.letter.toUpperCase();
    } catch (_) {
      return null;
    }
  }

  // ================= QUEST LOGIC =================

  QuestLocation? get nearestLocation {
    if (_currentPosition == null || _locations.isEmpty) {
      return null;
    }

    QuestLocation? nearest;
    double minDistance = double.infinity;

    for (var location in _locations) {
      if (_visitedLocations.contains(location.id)) continue;

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        location.latitude,
        location.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }

    return nearest;
  }

  double get nearestDistance {
    final nearest = nearestLocation;
    if (nearest == null || _currentPosition == null) return 0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      nearest.latitude,
      nearest.longitude,
    );
  }

  // ================= LOAD LOCATIONS =================

  void loadLocations() {
    _locations = [
      QuestLocation(
        id: "1",
        title: "Samui Pizzeria",
        description: "Start your adventure here.",
        latitude: 9.564639,
        longitude: 99.983011,
        unlockRadius: 60,
        question: "What is the name of the Pizzeria?",
        answer: "Via 7",
        letter: "K",
      ),
      QuestLocation(
        id: "2",
        title: "Koh Pha Ngan Main Pier",
        description: "Discover the main pier.",
        latitude: 9.584361,
        longitude: 99.970806,
        unlockRadius: 70,
        question: "What is the name of the Main pier?",
        answer: "Thong Sala",
        letter: "I",
      ),
      QuestLocation(
        id: "3",
        title: "Big Buddha",
        description: "Visit the famous statue.",
        latitude: 9.570778,
        longitude: 100.059861,
        unlockRadius: 80,
        question: "What statue stands here?",
        answer: "Buddha",
        letter: "N",
      ),
      QuestLocation(
        id: "4",
        title: "Rabbit",
        description: "Find the Rabbit landmark.",
        latitude: 9.554722,
        longitude: 100.043861,
        unlockRadius: 60,
        question: "Which animal is this place named after?",
        answer: "Rabbit",
        letter: "G",
      ),
      QuestLocation(
        id: "5",
        title: "D360 Viewpoint",
        description: "Enjoy a 360° view.",
        latitude: 9.423556,
        longitude: 99.930583,
        unlockRadius: 80,
        question: "What number is in the name?",
        answer: "360",
        letter: "C",
      ),
      QuestLocation(
        id: "6",
        title: "Mangrove Forest",
        description: "Explore the mangroves.",
        latitude: 9.421722,
        longitude: 99.936306,
        unlockRadius: 60,
        question: "What type of forest is this?",
        answer: "Mangrove",
        letter: "O",
      ),
      QuestLocation(
        id: "7",
        title: "Stadium",
        description: "Muay Thai fights happen here.",
        latitude: 9.435167,
        longitude: 100.007639,
        unlockRadius: 70,
        question: "What sport happens here?",
        answer: "Muay Thai",
        letter: "B",
      ),
      QuestLocation(
        id: "8",
        title: "Mae Viewpoint",
        description: "Climb to the viewpoint.",
        latitude: 9.587194,
        longitude: 99.982750,
        unlockRadius: 70,
        question: "What do you see here?",
        answer: "View",
        letter: "R",
      ),
      QuestLocation(
        id: "9",
        title: "Pagoda Viewpoint",
        description: "Visit the pagoda.",
        latitude: 9.537111,
        longitude: 100.058833,
        unlockRadius: 70,
        question: "What structure stands here?",
        answer: "Pagoda",
        letter: "A",
      ),
    ];

    notifyListeners();
  }

  // ================= GPS =================

Future<void> startTracking() async {
  bool hasPermission =
      await _locationService.requestPermission();
  if (!hasPermission) return;

  _positionSubscription =
      _locationService.getPositionStream().listen((position) {

    _currentPosition = position;

    if (position.heading >= 0) {
      _heading = position.heading;
    }

    _checkUnlocks();

    // 🔥 SPAWNS ALTIJD UPDATEN
    final playerLatLng =
        LatLng(position.latitude, position.longitude);

    _spawnService.updateSpawns(playerLatLng);

    notifyListeners();
  });
}

  void stopTracking() {
    _positionSubscription?.cancel();
  }

  // ================= UNLOCK =================

  void _checkUnlocks() {
    if (_currentPosition == null) return;

    for (var location in _locations) {
      bool unlocked = DistanceHelper.isWithinRadius(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        location.latitude,
        location.longitude,
        location.unlockRadius,
      );

      if (unlocked) {
        _unlockedLocations.add(location.id);
      }
    }
  }

  bool isUnlocked(String locationId) =>
      _unlockedLocations.contains(locationId);

  bool markVisited(String id) {
    if (_visitedLocations.contains(id)) return false;

    _visitedLocations.add(id);
    addXP(10);

    notifyListeners();
    return true;
  }
}