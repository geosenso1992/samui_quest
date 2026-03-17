import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Belangrijk voor _persistToFirestore
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quest_location.dart';
import '../services/location_service.dart';
import '../utils/distance_helper.dart';
import '../services/spawn_service.dart';
import '../models/map_spawn.dart';
import '../models/animal_metadata.dart';
import '../models/seed_metadata.dart';
import '../models/fruit_metadata.dart';

// --- DATA CLASSES & ENUMS ---

enum ResearchUpgrade {
  spawnRadius,
  moreAnimals,
  moreSeeds,
  rareSpawns,
  specialSpawns,
  seedGrowthSpeed,
  spawnLifetime,
}

class ResearchDefinition {
  final ResearchUpgrade id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int maxLevel;
  final int baseXpCost;
  final int baseCoinCost;

  const ResearchDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.maxLevel,
    required this.baseXpCost,
    required this.baseCoinCost,
  });
}

class GardenPlot {
  final String seedId;
  final DateTime plantedAt;
  final Duration growDuration;
  final bool isHarvested;

  const GardenPlot({
    required this.seedId,
    required this.plantedAt,
    required this.growDuration,
    this.isHarvested = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'seedId': seedId,
      'plantedAt': Timestamp.fromDate(plantedAt),
      'growDurationMinutes': growDuration.inMinutes,
      'isHarvested': isHarvested,
    };
  }

  factory GardenPlot.fromMap(Map<String, dynamic> map) {
    return GardenPlot(
      seedId: map['seedId'] ?? '',
      plantedAt: (map['plantedAt'] as Timestamp).toDate(),
      growDuration: Duration(minutes: map['growDurationMinutes'] ?? 0),
      isHarvested: map['isHarvested'] ?? false,
    );
  }
}

class FruitSellResult {
  final String fruitId;
  final int sold;
  final int coinsGained;
  final int xpGained;

  const FruitSellResult({
    required this.fruitId,
    required this.sold,
    required this.coinsGained,
    required this.xpGained,
  });
}

class AnimalSellResult {
  final String animalId;
  final int sold;
  final int coinsGained;

  const AnimalSellResult({
    required this.animalId,
    required this.sold,
    required this.coinsGained,
  });
}

enum AreaDensity { rural, semiUrban, urban }

Future<AreaDensity> classifyArea(LatLng pos) async {
  return AreaDensity.semiUrban;
}

// --- DE MAIN PROVIDER CLASS ---

enum CollectionKind { seed, fruit, animal }

class GameProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final SpawnService _spawnService = SpawnService();
  final math.Random _random = math.Random();
  static const Duration _questRefreshInterval = Duration(hours: 24);
  static const double _minDistanceThresholdMeters = 2.0;
  static const Duration _distancePersistInterval = Duration(minutes: 2);

  // --- GEBRUIKERSGEGEVENS & INVENTARIS ---
  int points = 0;
  String username = "";
  
  Map<String, int> fruitInventory = {};    
  List<String> animalCollection = [];      
  Map<String, bool> achievements = {};     
  List<GardenPlot> get gardenPlots => _gardenPlots.values.toList();

  GameProvider() {
    _applyResearchEffects();
  }

  String _currentAvatar = 'assets/monkey_player.png';

  DateTime? _firstPlayedAt;
  DateTime? _clientUpdatedAt;
  double _totalDistanceMeters = 0.0;
  final Map<String, double> _dailyDistanceMeters = {};
  double _totalXpEarned = 0.0;
  int _totalCoinsEarned = 0;
  int _totalFruitSalesValue = 0;
  final Set<String> _unseenAnimals = {};
  final Set<String> _unseenSeeds = {};
  final Set<String> _unseenFruits = {};
  final Set<String> _unseenBadges = {};
  Position? _lastDistancePosition;
  double _pendingDistanceMeters = 0.0;
  DateTime _lastDistancePersist = DateTime.fromMillisecondsSinceEpoch(0);

String get currentAvatar => _currentAvatar;

  set currentAvatar(String value) {
    _currentAvatar = value;
    notifyListeners();
  }

  List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  Map<String, int> _intMapFrom(dynamic value) {
    if (value is Map) {
      final result = <String, int>{};
      value.forEach((key, val) {
        if (key is String) {
          if (val is int) {
            result[key] = val;
          } else if (val is num) {
            result[key] = val.toInt();
          }
        }
      });
      return result;
    }
    return const {};
  }

  DateTime? _dateTimeFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, double> _doubleMapFrom(dynamic value) {
    if (value is Map) {
      final result = <String, double>{};
      value.forEach((key, val) {
        if (key is String) {
          if (val is num) {
            result[key] = val.toDouble();
          }
        }
      });
      return result;
    }
    return const {};
  }

  double _doubleFrom(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  QuestLocation? _questFromMap(dynamic value) {
    if (value is! Map) return null;
    final id = value['id'];
    final title = value['title'];
    final description = value['description'];
    final latitude = value['latitude'];
    final longitude = value['longitude'];
    final unlockRadius = value['unlockRadius'];
    final question = value['question'];
    final answer = value['answer'];
    final letter = value['letter'];
    final icon = value['icon'];
    if (id is! String ||
        title is! String ||
        description is! String ||
        latitude is! num ||
        longitude is! num ||
        unlockRadius is! num ||
        question is! String ||
        answer is! String ||
        letter is! String ||
        icon is! String) {
      return null;
    }
    return QuestLocation(
      id: id,
      title: title,
      description: description,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      unlockRadius: unlockRadius.toDouble(),
      question: question,
      answer: answer,
      letter: letter,
      icon: icon,
      expiresAt: _dateTimeFrom(value['expiresAt']),
    );
  }

  DateTime? get explorerSince => _firstPlayedAt;

  double get totalDistanceKm => _totalDistanceMeters / 1000.0;

  double get avgDistanceKmPerDay {
    final days = _dailyDistanceMeters.isEmpty ? 0 : _dailyDistanceMeters.length;
    if (days == 0) return 0.0;
    return totalDistanceKm / days;
  }

  int get animalsCaughtCount {
    var total = 0;
    _collectedSpawnCounts.forEach((id, spawnCount) {
      if (kAnimalMetadataByName.containsKey(id)) {
        total += spawnCount;
      }
    });
    return total;
  }

  int get seedsCollectedCount {
    var total = 0;
    _collectedSpawnCounts.forEach((id, spawnCount) {
      if (kSeedMetadataByName.containsKey(id)) {
        total += spawnCount;
      }
    });
    return total;
  }

  int get fruitsCollectedCount {
    var total = 0;
    _collectedFruitCounts.forEach((_, fruitCount) => total += fruitCount);
    return total;
  }

  bool get hasUnseenCollectionItems =>
      _unseenAnimals.isNotEmpty ||
      _unseenSeeds.isNotEmpty ||
      _unseenFruits.isNotEmpty;

  bool get hasUnseenBadges => _unseenBadges.isNotEmpty;

  bool get hasAffordableResearch {
    for (final def in researchDefinitions) {
      if (canUpgradeResearch(def.id)) return true;
    }
    return false;
  }

  bool isUnseenAnimal(String id) => _unseenAnimals.contains(id);
  bool isUnseenSeed(String id) => _unseenSeeds.contains(id);
  bool isUnseenFruit(String id) => _unseenFruits.contains(id);

  void markCollectionItemSeen(CollectionKind kind, String id) {
    switch (kind) {
      case CollectionKind.animal:
        _unseenAnimals.remove(id);
        break;
      case CollectionKind.seed:
        _unseenSeeds.remove(id);
        break;
      case CollectionKind.fruit:
        _unseenFruits.remove(id);
        break;
    }
    notifyListeners();
    unawaited(_persistToFirestore());
  }

  void markBadgesSeen() {
    if (_unseenBadges.isEmpty) return;
    _unseenBadges.clear();
    notifyListeners();
    unawaited(_persistToFirestore());
  }

  double get animalCatchRatioPercent {
    final animals = animalsCaughtCount;
    final seeds = seedsCollectedCount;
    final total = animals + seeds;
    if (total == 0) return 0;
    return (animals / total) * 100;
  }

  double get totalXpEarned => _totalXpEarned;
  int get totalCoinsEarned => _totalCoinsEarned;
  int get totalFruitSalesValue => _totalFruitSalesValue;

  Map<String, dynamic> _questToMap(QuestLocation quest) {
    return {
      'id': quest.id,
      'title': quest.title,
      'description': quest.description,
      'latitude': quest.latitude,
      'longitude': quest.longitude,
      'unlockRadius': quest.unlockRadius,
      'question': quest.question,
      'answer': quest.answer,
      'letter': quest.letter,
      'icon': quest.icon,
      'expiresAt':
          quest.expiresAt == null ? null : Timestamp.fromDate(quest.expiresAt!),
    };
  }

  Map<String, dynamic> _buildLocalSnapshot() {
    final now = DateTime.now();
    final stats = {
      'xp': _xp,
      'level': _level,
      'coins': _coins,
      'totalDistanceMeters': _totalDistanceMeters,
      'dailyDistanceMeters': _dailyDistanceMeters,
      'totalXpEarned': _totalXpEarned,
      'totalCoinsEarned': _totalCoinsEarned,
      'totalFruitSalesValue': _totalFruitSalesValue,
      'unseenBadges': _unseenBadges.toList(),
      'firstPlayedAt': _firstPlayedAt?.toIso8601String(),
      'clientUpdatedAt': now.toIso8601String(),
      'dynamicQuests': _dynamicQuestLocations.map(_questToMap).toList(),
      'questRefreshAt': _lastQuestRefresh?.toIso8601String(),
      'questCenterLat': _lastQuestCenter?.latitude,
      'questCenterLng': _lastQuestCenter?.longitude,
    };
    final inventory = {
      'fruitInventory': fruitInventory,
      'animalCollection': animalCollection,
      'achievements': achievements,
      'unlockedAnimals': _unlockedAnimals.toList(),
      'unlockedSeeds': _unlockedSeeds.toList(),
      'unlockedFruits': _unlockedFruits.toList(),
      'collectedSpawnCounts': _collectedSpawnCounts,
      'collectedFruitCounts': _collectedFruitCounts,
      'visitedLocations': _visitedLocations.toList(),
      'unlockedLetters': _unlockedLetters.toList(),
      'garden': gardenPlots.map((plot) => plot.toMap()).toList(),
      'gardenPaths': _gardenPathCells.toList(),
      'unseenAnimals': _unseenAnimals.toList(),
      'unseenSeeds': _unseenSeeds.toList(),
      'unseenFruits': _unseenFruits.toList(),
    };
    final profile = {
      'username': username,
      'avatar': _currentAvatar,
      'explorerSince': _firstPlayedAt?.toIso8601String(),
    };
    return {
      'profile': profile,
      'stats': stats,
      'inventory': inventory,
      'points': points,
      'username': username,
      'selectedAvatar': _currentAvatar,
      'clientUpdatedAt': now.toIso8601String(),
    };
  }

  Future<void> saveLocalSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'local_snapshot',
        jsonEncode(_buildLocalSnapshot()),
      );
    } catch (_) {
      // best-effort
    }
  }

  Future<bool> loadLocalSnapshot(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_snapshot');
      if (raw == null || raw.isEmpty) return false;
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        _applyUserData(uid, data);
        return true;
      }
    } catch (_) {
      // ignore
    }
    return false;
  }

  void _applyUserData(String uid, Map<String, dynamic> data) {
    final profile = data['profile'];
    final stats = data['stats'];
    final inventory = data['inventory'];
    _clientUpdatedAt = _dateTimeFrom(
      (stats is Map ? stats['clientUpdatedAt'] : null) ??
          data['clientUpdatedAt'],
    );

    final storedAvatar =
        (profile is Map ? profile['avatar'] : null) ?? data['selectedAvatar'];
    final needsAvatarMigration = storedAvatar == null ||
        (storedAvatar is String &&
            (storedAvatar.isEmpty || storedAvatar == 'default'));
    if (storedAvatar is String && storedAvatar.isNotEmpty) {
      _currentAvatar =
          storedAvatar == 'default' ? 'assets/monkey_player.png' : storedAvatar;
    } else {
      _currentAvatar = 'assets/monkey_player.png';
    }
    if (needsAvatarMigration && uid.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'selectedAvatar': _currentAvatar});
    }

    points = data['points'] ?? 0;
    username = (profile is Map ? profile['username'] : null) ??
        data['username'] ??
        'Onbekende Speler';
    _xp = (stats is Map ? stats['xp'] : null) ?? data['xp'] ?? 0;
    _level = (stats is Map ? stats['level'] : null) ?? data['level'] ?? 1;
    _coins = (stats is Map ? stats['coins'] : null) ?? data['coins'] ?? 0;

    _totalDistanceMeters = _doubleFrom(
      (stats is Map ? stats['totalDistanceMeters'] : null) ??
          data['totalDistanceMeters'],
    );
    _dailyDistanceMeters
      ..clear()
      ..addAll(_doubleMapFrom(
          (stats is Map ? stats['dailyDistanceMeters'] : null) ??
              data['dailyDistanceMeters']));
    _totalXpEarned = _doubleFrom(
      (stats is Map ? stats['totalXpEarned'] : null) ??
          data['totalXpEarned'],
    );
    final coinsEarnedValue =
        (stats is Map ? stats['totalCoinsEarned'] : null) ??
            data['totalCoinsEarned'];
    _totalCoinsEarned = coinsEarnedValue is num ? coinsEarnedValue.toInt() : 0;
    final fruitSalesValue =
        (stats is Map ? stats['totalFruitSalesValue'] : null) ??
            data['totalFruitSalesValue'];
    _totalFruitSalesValue = fruitSalesValue is num ? fruitSalesValue.toInt() : 0;
    _unseenBadges
      ..clear()
      ..addAll(_stringListFrom(
          (stats is Map ? stats['unseenBadges'] : null) ??
              data['unseenBadges']));

    if (_totalXpEarned == 0 && _xp > 0) {
      _totalXpEarned = _xp.toDouble();
    }
    if (_totalCoinsEarned == 0 && _coins > 0) {
      _totalCoinsEarned = _coins;
    }

    _firstPlayedAt = _dateTimeFrom(
          (profile is Map ? profile['explorerSince'] : null) ?? data['createdAt'],
        ) ??
        _dateTimeFrom((stats is Map ? stats['firstPlayedAt'] : null));

    fruitInventory =
        _intMapFrom((inventory is Map ? inventory['fruitInventory'] : null) ??
            data['fruitInventory']);
    animalCollection = _stringListFrom(
        (inventory is Map ? inventory['animalCollection'] : null) ??
            data['animalCollection']);
    achievements = Map<String, bool>.from(
        (inventory is Map ? inventory['achievements'] : null) ??
            data['achievements'] ??
            {});

    _unlockedAnimals
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unlockedAnimals'] : null) ??
              data['unlockedAnimals']));
    if (_unlockedAnimals.isEmpty && animalCollection.isNotEmpty) {
      _unlockedAnimals.addAll(animalCollection);
    }
    _unlockedSeeds
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unlockedSeeds'] : null) ??
              data['unlockedSeeds']));
    _unlockedFruits
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unlockedFruits'] : null) ??
              data['unlockedFruits']));
    _unseenAnimals
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unseenAnimals'] : null) ??
              data['unseenAnimals']));
    _unseenSeeds
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unseenSeeds'] : null) ??
              data['unseenSeeds']));
    _unseenFruits
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unseenFruits'] : null) ??
              data['unseenFruits']));
    _collectedSpawnCounts
      ..clear()
      ..addAll(_intMapFrom(
          (inventory is Map ? inventory['collectedSpawnCounts'] : null) ??
              data['collectedSpawnCounts']));
    _collectedFruitCounts
      ..clear()
      ..addAll(_intMapFrom(
          (inventory is Map ? inventory['collectedFruitCounts'] : null) ??
              data['collectedFruitCounts']));
    if (_unlockedAnimals.isEmpty || _unlockedSeeds.isEmpty) {
      for (final id in _collectedSpawnCounts.keys) {
        if (kAnimalMetadataByName.containsKey(id)) {
          _unlockedAnimals.add(id);
        } else if (kSeedMetadataByName.containsKey(id)) {
          _unlockedSeeds.add(id);
        }
      }
    }
    if (_unlockedFruits.isEmpty) {
      _unlockedFruits.addAll(_collectedFruitCounts.keys);
    }

    _visitedLocations
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['visitedLocations'] : null) ??
              data['visitedLocations']));
    _unlockedLetters
      ..clear()
      ..addAll(_stringListFrom(
          (inventory is Map ? inventory['unlockedLetters'] : null) ??
              data['unlockedLetters']));

    final gardenSource =
        (inventory is Map ? inventory['garden'] : null) ?? data['garden'];
    if (gardenSource is List) {
      final List gardenData = gardenSource;
      _gardenPlots.clear();
      for (int i = 0; i < gardenData.length; i++) {
        _gardenPlots[i] = GardenPlot.fromMap(gardenData[i]);
      }
    }
    final gardenPathsSource =
        (inventory is Map ? inventory['gardenPaths'] : null) ??
            data['gardenPaths'];
    if (gardenPathsSource is List) {
      _gardenPathCells
        ..clear()
        ..addAll(gardenPathsSource.whereType<int>());
    }

    final questRefreshAt = _dateTimeFrom(
      (stats is Map ? stats['questRefreshAt'] : null) ?? data['questRefreshAt'],
    );
    final questCenterLat =
        (stats is Map ? stats['questCenterLat'] : null) ?? data['questCenterLat'];
    final questCenterLng =
        (stats is Map ? stats['questCenterLng'] : null) ?? data['questCenterLng'];
    final now = DateTime.now();
    final questsFresh = questRefreshAt != null &&
        now.difference(questRefreshAt) <= _questRefreshInterval;
    final questList =
        (stats is Map ? stats['dynamicQuests'] : null) ?? data['dynamicQuests'];
    if (questsFresh && questList is List) {
      _dynamicQuestLocations
        ..clear()
        ..addAll(questList.map(_questFromMap).whereType<QuestLocation>());
      _lastQuestRefresh = questRefreshAt;
      if (questCenterLat is num && questCenterLng is num) {
        _lastQuestCenter =
            LatLng(questCenterLat.toDouble(), questCenterLng.toDouble());
      }
    } else {
      _dynamicQuestLocations.clear();
      _lastQuestRefresh = null;
      _lastQuestCenter = null;
    }

    _firstPlayedAt ??= DateTime.now();
    _shownBadgeTitles
      ..clear()
      ..addAll(_computeUnlockedBadgeTitles());
    notifyListeners();
  }

  /// Haalt ALLE gebruikersdata op uit de cloud bij inloggen
  Future<void> syncUserData(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        _applyUserData(uid, doc.data()!);
        print("✅ Volledige sync voltooid voor: $username (Level: $_level)");
      }
    } catch (e) {
      print("❌ Fout bij synchroniseren data: $e");
      rethrow;
    }
  }

  /// Probeert server, valt terug op cache als nodig.
  Future<bool> syncUserDataWithFallback(String uid) async {
    DateTime? cacheUpdatedAt;
    bool appliedCache = false;

    try {
      final cacheDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 4));
      if (cacheDoc.exists) {
        _applyUserData(uid, cacheDoc.data()!);
        cacheUpdatedAt = _clientUpdatedAt;
        appliedCache = true;
      }
    } catch (_) {
      // ignore cache errors
    }

    try {
      final serverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      if (serverDoc.exists) {
        final serverUpdatedAt = _dateTimeFrom(
          (serverDoc.data()?['stats'] as Map?)?['clientUpdatedAt'] ??
              serverDoc.data()?['clientUpdatedAt'],
        );
        final shouldApplyServer = !appliedCache ||
            cacheUpdatedAt == null ||
            (serverUpdatedAt != null &&
                serverUpdatedAt.isAfter(cacheUpdatedAt));
        if (shouldApplyServer) {
          _applyUserData(uid, serverDoc.data()!);
        }
        return true;
      }
    } catch (_) {
      // ignore server errors
    }

    if (!appliedCache) {
      final loadedLocal = await loadLocalSnapshot(uid);
      return loadedLocal;
    }

    return appliedCache;
  }

  /// Slaat de huidige status van de provider op in Firestore (Zender)
  Future<void> _persistToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      unawaited(saveLocalSnapshot());
      final now = DateTime.now();
      final profile = {
        'username': username,
      'avatar': _currentAvatar,
      'explorerSince': _firstPlayedAt == null
          ? null
          : Timestamp.fromDate(_firstPlayedAt!),
    };
    final stats = {
      'xp': _xp,
      'level': _level,
      'coins': _coins,
      'totalDistanceMeters': _totalDistanceMeters,
      'dailyDistanceMeters': _dailyDistanceMeters,
      'totalXpEarned': _totalXpEarned,
      'totalCoinsEarned': _totalCoinsEarned,
      'totalFruitSalesValue': _totalFruitSalesValue,
      'unseenBadges': _unseenBadges.toList(),
      'firstPlayedAt': _firstPlayedAt == null
          ? null
          : Timestamp.fromDate(_firstPlayedAt!),
      'clientUpdatedAt': Timestamp.fromDate(now),
      'dynamicQuests':
          _dynamicQuestLocations.map(_questToMap).toList(growable: false),
      'questRefreshAt': _lastQuestRefresh == null
          ? null
          : Timestamp.fromDate(_lastQuestRefresh!),
      'questCenterLat': _lastQuestCenter?.latitude,
      'questCenterLng': _lastQuestCenter?.longitude,
      };
      final inventory = {
        'fruitInventory': fruitInventory,
        'animalCollection': animalCollection,
        'achievements': achievements,
        'unlockedAnimals': _unlockedAnimals.toList(),
        'unlockedSeeds': _unlockedSeeds.toList(),
        'unlockedFruits': _unlockedFruits.toList(),
        'collectedSpawnCounts': _collectedSpawnCounts,
        'collectedFruitCounts': _collectedFruitCounts,
        'visitedLocations': _visitedLocations.toList(),
        'unlockedLetters': _unlockedLetters.toList(),
        'garden': gardenPlots.map((plot) => plot.toMap()).toList(),
        'gardenPaths': _gardenPathCells.toList(),
        'unseenAnimals': _unseenAnimals.toList(),
        'unseenSeeds': _unseenSeeds.toList(),
        'unseenFruits': _unseenFruits.toList(),
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'points': points,
        'xp': _xp,
        'level': _level,
        'coins': _coins,
        'fruitInventory': fruitInventory,
        'animalCollection': animalCollection,
        'achievements': achievements,
        'garden': gardenPlots.map((plot) => plot.toMap()).toList(),
        'gardenPaths': _gardenPathCells.toList(),
        'selectedAvatar': _currentAvatar,
        'unlockedAnimals': _unlockedAnimals.toList(),
        'unlockedSeeds': _unlockedSeeds.toList(),
        'unlockedFruits': _unlockedFruits.toList(),
        'collectedSpawnCounts': _collectedSpawnCounts,
        'collectedFruitCounts': _collectedFruitCounts,
        'visitedLocations': _visitedLocations.toList(),
        'unlockedLetters': _unlockedLetters.toList(),
        'dynamicQuests':
            _dynamicQuestLocations.map(_questToMap).toList(growable: false),
        'questRefreshAt': _lastQuestRefresh == null
            ? null
            : Timestamp.fromDate(_lastQuestRefresh!),
        'questCenterLat': _lastQuestCenter?.latitude,
        'questCenterLng': _lastQuestCenter?.longitude,
        'totalDistanceMeters': _totalDistanceMeters,
        'dailyDistanceMeters': _dailyDistanceMeters,
        'totalXpEarned': _totalXpEarned,
        'totalCoinsEarned': _totalCoinsEarned,
        'totalFruitSalesValue': _totalFruitSalesValue,
        'unseenBadges': _unseenBadges.toList(),
        'clientUpdatedAt': Timestamp.fromDate(now),
        'profile': profile,
        'stats': stats,
        'inventory': inventory,
      });
      print("☁️ Progressie succesvol gesynchroniseerd met de cloud!");
    } catch (e) {
      unawaited(saveLocalSnapshot());
      print("❌ Fout bij opslaan naar Firestore: $e");
    }
  }

  Future<void> persistNow() async {
    await _persistToFirestore();
  }

  Future<void> _persistQuestSnapshot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final stats = {
        'xp': _xp,
        'level': _level,
        'coins': _coins,
        'totalDistanceMeters': _totalDistanceMeters,
        'dailyDistanceMeters': _dailyDistanceMeters,
        'totalXpEarned': _totalXpEarned,
        'totalCoinsEarned': _totalCoinsEarned,
        'totalFruitSalesValue': _totalFruitSalesValue,
        'unseenBadges': _unseenBadges.toList(),
        'firstPlayedAt': _firstPlayedAt == null
            ? null
            : Timestamp.fromDate(_firstPlayedAt!),
        'clientUpdatedAt': Timestamp.fromDate(now),
        'dynamicQuests':
            _dynamicQuestLocations.map(_questToMap).toList(growable: false),
        'questRefreshAt': _lastQuestRefresh == null
            ? null
            : Timestamp.fromDate(_lastQuestRefresh!),
        'questCenterLat': _lastQuestCenter?.latitude,
        'questCenterLng': _lastQuestCenter?.longitude,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'dynamicQuests':
            _dynamicQuestLocations.map(_questToMap).toList(growable: false),
        'questRefreshAt': _lastQuestRefresh == null
            ? null
            : Timestamp.fromDate(_lastQuestRefresh!),
        'questCenterLat': _lastQuestCenter?.latitude,
        'questCenterLng': _lastQuestCenter?.longitude,
        'clientUpdatedAt': Timestamp.fromDate(now),
        'stats': stats,
      });
    } catch (e) {
      print("❌ Fout bij opslaan quest snapshot: $e");
    }
  }

  Future<void> _persistStatsSnapshot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final stats = {
        'xp': _xp,
        'level': _level,
        'coins': _coins,
        'totalDistanceMeters': _totalDistanceMeters,
        'dailyDistanceMeters': _dailyDistanceMeters,
        'totalXpEarned': _totalXpEarned,
        'totalCoinsEarned': _totalCoinsEarned,
        'totalFruitSalesValue': _totalFruitSalesValue,
        'unseenBadges': _unseenBadges.toList(),
        'firstPlayedAt': _firstPlayedAt == null
            ? null
            : Timestamp.fromDate(_firstPlayedAt!),
        'clientUpdatedAt': Timestamp.fromDate(now),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'xp': _xp,
        'level': _level,
        'coins': _coins,
        'totalDistanceMeters': _totalDistanceMeters,
        'dailyDistanceMeters': _dailyDistanceMeters,
        'totalXpEarned': _totalXpEarned,
        'totalCoinsEarned': _totalCoinsEarned,
        'totalFruitSalesValue': _totalFruitSalesValue,
        'unseenBadges': _unseenBadges.toList(),
        'clientUpdatedAt': Timestamp.fromDate(now),
        'stats': stats,
      });
    } catch (e) {
      print("❌ Fout bij opslaan stats snapshot: $e");
    }
  }

  // ================= SPAWN SYSTEM =================

  List<MapSpawn> get activeSpawns =>
      List<MapSpawn>.from(_spawnService.activeSpawns);
  
  // Hieronder volgen je overige functies...

  void setSpawnVisibility(String id, bool visible) {
    final spawn = _spawnService.activeSpawns.firstWhere((s) => s.id == id);

    spawn.isVisible = visible;
    notifyListeners();
  }

  int collectSpawn(MapSpawn spawn) {
    if (spawn.isCollected) return 0;
    spawn.isCollected = true;
    _collectedSpawnCounts[spawn.asset] =
        (_collectedSpawnCounts[spawn.asset] ?? 0) + 1;

    if (spawn.type == SpawnType.animal) {
      final wasUnlocked = _unlockedAnimals.contains(spawn.asset);
      _unlockedAnimals.add(spawn.asset);
      if (!wasUnlocked) {
        _unseenAnimals.add(spawn.asset);
      }
    } else {
      final wasUnlocked = _unlockedSeeds.contains(spawn.asset);
      _unlockedSeeds.add(spawn.asset);
      if (!wasUnlocked) {
        _unseenSeeds.add(spawn.asset);
      }
    }

    _spawnService.removeSpawn(spawn.id);
    final coinsEarned = spawn.type == SpawnType.animal ? 3 : 1;
    _coins += coinsEarned;
    _totalCoinsEarned += coinsEarned;

    final baseXp = spawn.type == SpawnType.animal
        ? (kAnimalMetadataByName[spawn.asset]?.xpWhenCaught ?? 5)
        : (kSeedMetadataByName[spawn.asset]?.xpWhenCollected ?? 1);
    _xp += baseXp;
    _totalXpEarned += baseXp;
    while (_xp >= xpNeeded) {
      _xp -= xpNeeded;
      _level++;
    }
    _queueNewBadgesIfAny();
    notifyListeners();
    _persistToFirestore();
    return baseXp;
  }

  // =================================================

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  double _heading = 0.0;
  double get heading => _heading;

  // Throttle heading updates so the mini-radar cone refreshes slower.
  DateTime _lastHeadingUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _headingUpdateInterval = Duration(seconds: 5);

  // dynamic quest locations that are generated around the player
  final List<QuestLocation> _dynamicQuestLocations = [];
  DateTime? _lastQuestRefresh;
  LatLng? _lastQuestCenter;

  /// public getter used by UI code – always returns at most the 10 closest
  List<QuestLocation> get locations {
    _cleanupExpiredQuests();
    if (_currentPosition == null) {
      return List.unmodifiable(_dynamicQuestLocations);
    }

    _dynamicQuestLocations.sort((a, b) {
      final da = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.latitude,
        a.longitude,
      );
      final db = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.latitude,
        b.longitude,
      );
      return da.compareTo(db);
    });

    return List.unmodifiable(_dynamicQuestLocations.take(10).toList());
  }

  final Set<String> _unlockedLocations = {};
  Set<String> get unlockedLocations => _unlockedLocations;

  final Set<String> _visitedLocations = {};
  Set<String> get visitedLocations => _visitedLocations;

  final Set<String> _unlockedLetters = {};
  Set<String> get unlockedLetters => _unlockedLetters;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // ================= XP SYSTEM =================

  int _xp = 0;
  int _level = 1;
  int _coins = 0;

  int get xp => _xp;
  int get level => _level;
  int get coins => _coins;
  int get xpNeeded => _level * 100;

  void addXP(int amount) {
    _xp += amount;
    _totalXpEarned += amount;

    while (_xp >= xpNeeded) {
      _xp -= xpNeeded;
      _level++;
    }

    _queueNewBadgesIfAny();
    notifyListeners();
    unawaited(_persistStatsSnapshot());
    unawaited(saveLocalSnapshot());
  }

  // ================= ANIMAL & SEED SYSTEM =================

  final Set<String> _unlockedAnimals = {};
  final Set<String> _unlockedSeeds = {};
  final Set<String> _unlockedFruits = {};
  final Map<String, int> _collectedSpawnCounts = {};
  final Map<String, int> _collectedFruitCounts = {};

  Set<String> get unlockedAnimals => _unlockedAnimals;
  Set<String> get unlockedSeeds => _unlockedSeeds;
  Set<String> get unlockedFruits => _unlockedFruits;

  bool isAnimalUnlocked(String type) => _unlockedAnimals.contains(type);

  bool isSeedUnlocked(String type) => _unlockedSeeds.contains(type);

  bool isFruitUnlocked(String type) => _unlockedFruits.contains(type);

  int getCollectedSpawnCount(String type) => _collectedSpawnCounts[type] ?? 0;

  int getCollectedFruitCount(String fruitId) => _collectedFruitCounts[fruitId] ?? 0;

  int getPlantedSeedCount(String seedId) {
    var count = 0;
    for (final plot in _gardenPlots.values) {
      if (plot.seedId == seedId) {
        count++;
      }
    }
    return count;
  }

  int getAvailableSeedCount(String seedId) {
    final collected = getCollectedSpawnCount(seedId);
    final planted = getPlantedSeedCount(seedId);
    return math.max(0, collected - planted);
  }

  // ================= FRUIT MARKET =================

  LatLng? _fruitMarketPosition;
  LatLng? get fruitMarketPosition => _fruitMarketPosition;

  LatLng? _animalMarketPosition;
  LatLng? get animalMarketPosition => _animalMarketPosition;

  void _ensureFruitMarketNear(LatLng player) {
    final current = _fruitMarketPosition;
    if (current != null) {
      final d = Geolocator.distanceBetween(
        player.latitude,
        player.longitude,
        current.latitude,
        current.longitude,
      );
      if (d <= 1000) return;
    }

    // Place a new market 300..900m away in a random direction.
    final distanceMeters = 300 + _random.nextInt(601); // inclusive 900
    final theta = _random.nextDouble() * 2 * math.pi;
    final dx = distanceMeters * math.cos(theta);
    final dy = distanceMeters * math.sin(theta);

    final latDelta = dy / 111320.0;
    final lngDelta =
        dx / (111320.0 * math.cos(player.latitude * math.pi / 180.0));
    _fruitMarketPosition = LatLng(player.latitude + latDelta, player.longitude + lngDelta);
  }

  void _ensureAnimalMarketNear(LatLng player) {
    final current = _animalMarketPosition;
    if (current != null) {
      final d = Geolocator.distanceBetween(
        player.latitude,
        player.longitude,
        current.latitude,
        current.longitude,
      );
      if (d <= 1000) return;
    }

    final distanceMeters = 300 + _random.nextInt(601);
    final theta = _random.nextDouble() * 2 * math.pi;
    final dx = distanceMeters * math.cos(theta);
    final dy = distanceMeters * math.sin(theta);

    final latDelta = dy / 111320.0;
    final lngDelta =
        dx / (111320.0 * math.cos(player.latitude * math.pi / 180.0));
    _animalMarketPosition =
        LatLng(player.latitude + latDelta, player.longitude + lngDelta);
  }

  int getAnimalSellCoins(String animalId) {
    final rarity = kAnimalMetadataByName[animalId]?.rarity ?? AnimalRarity.common;
    return switch (rarity) {
      AnimalRarity.common => 10,
      AnimalRarity.rare => 50,
      AnimalRarity.special => 200,
    };
  }

  AnimalSellResult sellAnimal({
    required String animalId,
    int amount = 1,
  }) {
    final available = getCollectedSpawnCount(animalId);
    final toSell = math.max(0, math.min(amount, available));
    if (toSell <= 0) {
      return AnimalSellResult(
        animalId: animalId,
        sold: 0,
        coinsGained: 0,
      );
    }

    final coinsPer = getAnimalSellCoins(animalId);
    final coinsGained = coinsPer * toSell;

    final newCount = available - toSell;
    if (newCount <= 0) {
      _collectedSpawnCounts.remove(animalId);
    } else {
      _collectedSpawnCounts[animalId] = newCount;
    }

    _coins += coinsGained;
    _totalCoinsEarned += coinsGained;
    _totalFruitSalesValue += coinsGained;
    _queueNewBadgesIfAny();
    notifyListeners();
    unawaited(_persistToFirestore());

    return AnimalSellResult(
      animalId: animalId,
      sold: toSell,
      coinsGained: coinsGained,
    );
  }

  FruitSellResult sellFruit({
    required String fruitId,
    int amount = 1,
  }) {
    final available = getCollectedFruitCount(fruitId);
    final toSell = math.max(0, math.min(amount, available));
    if (toSell <= 0) {
      return FruitSellResult(
        fruitId: fruitId,
        sold: 0,
        coinsGained: 0,
        xpGained: 0,
      );
    }

    final coinsPer = getFruitSellCoins(fruitId);
    final xpPer = getFruitSellXp(fruitId);
    final coinsGained = coinsPer * toSell;
    final xpGained = xpPer * toSell;

    final newCount = available - toSell;
    if (newCount <= 0) {
      _collectedFruitCounts.remove(fruitId);
    } else {
      _collectedFruitCounts[fruitId] = newCount;
    }

    _coins += coinsGained;
    _totalCoinsEarned += coinsGained;
    _xp += xpGained;
    _totalXpEarned += xpGained;
    while (_xp >= xpNeeded) {
      _xp -= xpNeeded;
      _level++;
    }
    _queueNewBadgesIfAny();
    notifyListeners();
    unawaited(_persistToFirestore());

    return FruitSellResult(
      fruitId: fruitId,
      sold: toSell,
      coinsGained: coinsGained,
      xpGained: xpGained,
    );
  }

  bool canPlantSeed(String seedId, {int amount = 1}) {
    return getAvailableSeedCount(seedId) >= amount;
  }

  // ================= RESEARCH SYSTEM =================

  static const List<ResearchDefinition> researchDefinitions = [
    ResearchDefinition(
      id: ResearchUpgrade.spawnRadius,
      title: "Bigger Spawn Radius",
      description: "Expand the area around you where objects can appear.",
      icon: Icons.radar,
      color: Color(0xFF4FC3F7),
      maxLevel: 5,
      baseXpCost: 20,
      baseCoinCost: 15,
    ),
    ResearchDefinition(
      id: ResearchUpgrade.moreAnimals,
      title: "More Animal Spawns",
      description: "Increase how often spawns become animals.",
      icon: Icons.pets,
      color: Color(0xFF66BB6A),
      maxLevel: 5,
      baseXpCost: 30,
      baseCoinCost: 20,
    ),
    ResearchDefinition(
      id: ResearchUpgrade.moreSeeds,
      title: "More Seed Spawns",
      description: "Increase how often spawns become seeds.",
      icon: Icons.spa,
      color: Color(0xFFAED581),
      maxLevel: 5,
      baseXpCost: 30,
      baseCoinCost: 20,
    ),
    ResearchDefinition(
      id: ResearchUpgrade.rareSpawns,
      title: "Rare Spawn Rate",
      description: "Raise the chance for rare animals and rare seeds.",
      icon: Icons.diamond_outlined,
      color: Color(0xFF42A5F5),
      maxLevel: 4,
      baseXpCost: 40,
      baseCoinCost: 30,
    ),
    ResearchDefinition(
      id: ResearchUpgrade.specialSpawns,
      title: "Special Spawn Rate",
      description: "Raise the chance for special animals and special seeds.",
      icon: Icons.auto_awesome,
      color: Color(0xFFFFCA28),
      maxLevel: 4,
      baseXpCost: 55,
      baseCoinCost: 45,
    ),
    ResearchDefinition(
      id: ResearchUpgrade.seedGrowthSpeed,
      title: "Faster Seed Growth",
      description: "Reduce grow time in My Garden.",
      icon: Icons.timelapse,
      color: Color(0xFFFF8A65),
      maxLevel: 5,
      baseXpCost: 35,
      baseCoinCost: 25,
    ),
    ResearchDefinition(
      id: ResearchUpgrade.spawnLifetime,
      title: "Longer Spawn Lifetime",
      description: "Keep map spawns active for longer before they vanish.",
      icon: Icons.schedule,
      color: Color(0xFFB39DDB),
      maxLevel: 5,
      baseXpCost: 30,
      baseCoinCost: 22,
    ),
  ];

  static final Map<ResearchUpgrade, ResearchDefinition> _researchById = {
    for (final def in researchDefinitions) def.id: def,
  };

  final Map<ResearchUpgrade, int> _researchLevels = {
    for (final def in researchDefinitions) def.id: 0,
  };

  int getResearchLevel(ResearchUpgrade id) => _researchLevels[id] ?? 0;

  ResearchDefinition getResearchDefinition(ResearchUpgrade id) =>
      _researchById[id]!;

  int getResearchXpCost(ResearchUpgrade id) {
    final def = getResearchDefinition(id);
    final level = getResearchLevel(id);
    return def.baseXpCost * (level + 1);
  }

  int getResearchCoinCost(ResearchUpgrade id) {
    final def = getResearchDefinition(id);
    final level = getResearchLevel(id);
    return def.baseCoinCost * (level + 1);
  }

  bool canUpgradeResearch(ResearchUpgrade id) {
    final def = getResearchDefinition(id);
    final level = getResearchLevel(id);
    if (level >= def.maxLevel) return false;
    return _xp >= getResearchXpCost(id) && _coins >= getResearchCoinCost(id);
  }

  bool upgradeResearch(ResearchUpgrade id) {
    if (!canUpgradeResearch(id)) return false;
    _xp -= getResearchXpCost(id);
    _coins -= getResearchCoinCost(id);
    _researchLevels[id] = getResearchLevel(id) + 1;
    _applyResearchEffects();
    notifyListeners();
    unawaited(_persistToFirestore());
    return true;
  }

  Duration get currentSeedGrowDuration {
    final level = getResearchLevel(ResearchUpgrade.seedGrowthSpeed);
    final multiplier = (1.0 - (level * 0.12)).clamp(0.35, 1.0);
    return Duration(
      seconds: (defaultSeedGrowDuration.inSeconds * multiplier).round(),
    );
  }

  String getResearchEffectLabel(ResearchUpgrade id, {required bool nextLevel}) {
    final level = getResearchLevel(id);
    final shownLevel = nextLevel ? level + 1 : level;
    switch (id) {
      case ResearchUpgrade.spawnRadius:
        final radius = 60 + (shownLevel * 10);
        return "Spawn radius: ${radius}m";
      case ResearchUpgrade.moreAnimals:
        final chance = (0.50 + (shownLevel * 0.05)).clamp(0.05, 0.95);
        return "Animal chance up to ${(chance * 100).round()}%";
      case ResearchUpgrade.moreSeeds:
        final chance = (0.50 + (shownLevel * 0.05)).clamp(0.05, 0.95);
        return "Seed chance up to ${(chance * 100).round()}%";
      case ResearchUpgrade.rareSpawns:
        final boost = 1.0 + (shownLevel * 0.35);
        return "Rare weight x${boost.toStringAsFixed(2)}";
      case ResearchUpgrade.specialSpawns:
        final boost = 1.0 + (shownLevel * 0.45);
        return "Special weight x${boost.toStringAsFixed(2)}";
      case ResearchUpgrade.seedGrowthSpeed:
        final reduction = (shownLevel * 12).clamp(0, 65);
        return "Growth time -$reduction%";
      case ResearchUpgrade.spawnLifetime:
        final seconds = 180 + (shownLevel * 45);
        return "Lifetime: ${seconds}s";
    }
  }

  void _applyResearchEffects() {
    final radiusLevel = getResearchLevel(ResearchUpgrade.spawnRadius);
    final animalLevel = getResearchLevel(ResearchUpgrade.moreAnimals);
    final seedLevel = getResearchLevel(ResearchUpgrade.moreSeeds);
    final rareLevel = getResearchLevel(ResearchUpgrade.rareSpawns);
    final specialLevel = getResearchLevel(ResearchUpgrade.specialSpawns);
    final lifetimeLevel = getResearchLevel(ResearchUpgrade.spawnLifetime);

    final spawnRadius = 60 + (radiusLevel * 10);
    final lifetime = 180 + (lifetimeLevel * 45);
    final minSpawns = 2 + ((animalLevel + seedLevel) ~/ 3);
    final maxSpawns = 30 + animalLevel + seedLevel;
    final animalChance =
        (0.5 + (animalLevel * 0.05) - (seedLevel * 0.05)).clamp(0.05, 0.95);
    final rareBoost = 1.0 + (rareLevel * 0.35);
    final specialBoost = 1.0 + (specialLevel * 0.45);

    _spawnService.configure(
      minSpawns: minSpawns,
      maxSpawns: maxSpawns,
      spawnRadiusMeters: spawnRadius.toDouble(),
      respawnDistanceMeters: (spawnRadius * 1.6).clamp(80, 400).toDouble(),
      spawnLifetimeSeconds: lifetime,
      animalSpawnChance: animalChance,
      rareSpawnBoost: rareBoost,
      specialSpawnBoost: specialBoost,
    );
  }

  /// called periodically to throw out quests that are older than one hour
  void _cleanupExpiredQuests() {
    final now = DateTime.now();
    _dynamicQuestLocations
        .removeWhere((q) => q.expiresAt != null && q.expiresAt!.isBefore(now));
  }

  /// When the player moves a significant distance or an hour has passed we
  /// generate up to ten new random quests within a 5 km radius.  The helper
  /// uses the same random‑offset math as the spawn service.
  void _maybeRefreshQuests(LatLng player) {
    final now = DateTime.now();
    final shouldRefresh = _lastQuestRefresh == null ||
        now.difference(_lastQuestRefresh!) >= _questRefreshInterval;
    if (!shouldRefresh) return;

    _generateQuestLocations(player);
    _lastQuestRefresh = now;
    _lastQuestCenter = player;
  }

  void _generateQuestLocations(LatLng center) {
    _dynamicQuestLocations.clear();
    final rand = math.Random();

    // create a shuffled tier list: 5 bronze, 3 silver, 2 gold
    final tiers = <String>[
      ...List.filled(5, 'quest_bronze'),
      ...List.filled(3, 'quest_silver'),
      ...List.filled(2, 'quest_gold'),
    ];
    tiers.shuffle(rand);

    for (var i = 0; i < 10; i++) {
      final r = 4000 * math.sqrt(rand.nextDouble());
      final theta = rand.nextDouble() * 2 * math.pi;
      final dx = r * math.cos(theta);
      final dy = r * math.sin(theta);
      final newLat = center.latitude + (dy / 111320);
      final newLng = center.longitude +
          (dx / (111320 * math.cos(center.latitude * math.pi / 180)));

      // placeholder question – you can replace this with an AI call that
      // generates a multiple–choice question about the country returned by
      // reverse geocoding.
      final question = "What country is this location in?";
      final answer = "Unknown";

      _dynamicQuestLocations.add(QuestLocation(
        id: 'dyn_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: "Mystery Location",
        description: "Find out what's here.",
        latitude: newLat,
        longitude: newLng,
        unlockRadius: 80,
        question: question,
        answer: answer,
        letter: "",
        icon: tiers[i],
        expiresAt: DateTime.now().add(_questRefreshInterval),
      ));
    }
    unawaited(_persistQuestSnapshot());
  }

  /// attempts to figure out whether the neighbouring area should be treated
  /// as urban/rural and tweaks spawn service min/max accordingly.
  Future<void> _updateAreaDensityIfNeeded(LatLng player) async {
    final newDensity = await classifyArea(player);
    // simple mapping – you can elaborate on this later
    switch (newDensity) {
      case AreaDensity.rural:
        _spawnService.configure(minSpawns: 2, maxSpawns: 5);
        break;
      case AreaDensity.semiUrban:
        _spawnService.configure(minSpawns: 5, maxSpawns: 10);
        break;
      case AreaDensity.urban:
        _spawnService.configure(minSpawns: 10, maxSpawns: 20);
        break;
    }
  }

  // ================= QUEST AI HELPERS =================

  /// This is a placeholder that demonstrates how you could ask an AI model
  /// to generate a question at runtime.  Pass the returned location to the
  /// QuestScreen instead of the original one.  In production you'd call your
  /// own backend/HTTP service here.
  Future<QuestLocation> enrichQuestWithAI(QuestLocation loc) async {
    // simple reverse geocoding example – you could also send the coordinates
    // to your own server and let it hit OpenAI, Azure, etc.
    final country = await _reverseGeocodeCountry(loc.latitude, loc.longitude);

    // placeholder logic – swap in an actual AI/model backend as needed.
    final question = "What country are you standing in?";
    final answer = country;

    return QuestLocation(
      id: loc.id,
      title: loc.title,
      description: loc.description,
      latitude: loc.latitude,
      longitude: loc.longitude,
      unlockRadius: loc.unlockRadius,
      question: question,
      answer: answer,
      letter: loc.letter,
      icon: loc.icon,
      expiresAt: loc.expiresAt,
    );
  }

  Future<String> _reverseGeocodeCountry(double lat, double lng) async {
    // you could also use Mapbox's SDK or a geocoding package; here we just
    // return a stub to keep the example compilable without extra dependencies.
    try {
      // import 'package:geocoding/geocoding.dart';
      // final places = await placemarkFromCoordinates(lat, lng);
      // return places.first.country ?? 'Unknown';
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  // ================= GARDEN SYSTEM =================

  static const int gardenGridCount = 10;
  static const int gardenCellCount = gardenGridCount * gardenGridCount;
  static const Duration defaultSeedGrowDuration = Duration(minutes: 5);

  double get _seedGrowthSpeedMultiplier {
    final level = getResearchLevel(ResearchUpgrade.seedGrowthSpeed);
    return (1.0 - (level * 0.12)).clamp(0.35, 1.0);
  }

  Duration getSeedGrowDuration(String seedId) {
    final base = kSeedMetadataByName[seedId]?.baseGrowthTime ??
        defaultSeedGrowDuration;
    return Duration(
      seconds: (base.inSeconds * _seedGrowthSpeedMultiplier).round(),
    );
  }

  int getSeedHarvestXp(String seedId) {
    return kSeedMetadataByName[seedId]?.xpWhenHarvested ?? 5;
  }

  final Map<int, GardenPlot> _gardenPlots = {};
  final Set<int> _gardenPathCells = {};

  GardenPlot? getGardenPlot(int index) => _gardenPlots[index];
  Set<int> get gardenPathCells => _gardenPathCells;
  bool isGardenPathCell(int index) => _gardenPathCells.contains(index);

  bool toggleGardenPathCell(int index) {
    if (_gardenPathCells.contains(index)) {
      _gardenPathCells.remove(index);
    } else {
      if (_coins < 10) {
        return false;
      }
      _coins -= 10;
      _gardenPathCells.add(index);
      _gardenPlots.remove(index);
    }
    notifyListeners();
    unawaited(_persistToFirestore());
    return true;
  }

  bool canPlantAtCell(int index) {
    if (_gardenPathCells.isEmpty) return false;
    if (_gardenPathCells.contains(index)) return false;
    return _isAdjacentToPath(index);
  }

  bool _isAdjacentToPath(int index) {
    final row = index ~/ gardenGridCount;
    final col = index % gardenGridCount;
    final neighbors = <int>[
      if (row > 0) (row - 1) * gardenGridCount + col,
      if (row < gardenGridCount - 1) (row + 1) * gardenGridCount + col,
      if (col > 0) row * gardenGridCount + (col - 1),
      if (col < gardenGridCount - 1) row * gardenGridCount + (col + 1),
    ];
    for (final neighbor in neighbors) {
      if (_gardenPathCells.contains(neighbor)) return true;
    }
    return false;
  }

  bool plantSeedAt({
    required int index,
    required String seedId,
  }) {
    final currentPlot = _gardenPlots[index];

    // Re-applying the same seed to the same cell should not consume inventory.
    if (currentPlot?.seedId == seedId && !(currentPlot?.isHarvested ?? false)) {
      return true;
    }

    if (!canPlantSeed(seedId)) {
      return false;
    }
    if (!canPlantAtCell(index)) {
      return false;
    }

    _gardenPlots[index] = GardenPlot(
      seedId: seedId,
      plantedAt: DateTime.now(),
      growDuration: getSeedGrowDuration(seedId),
    );
    notifyListeners();
    unawaited(_persistToFirestore());
    return true;
  }

  void unplantSeedAt(int index) {
    _gardenPlots.remove(index);
    notifyListeners();
    unawaited(_persistToFirestore());
  }

  double getGardenProgress(int index, {DateTime? now}) {
    final plot = _gardenPlots[index];
    if (plot == null) return 0.0;
    final current = now ?? DateTime.now();
    final elapsed = current.difference(plot.plantedAt).inMilliseconds;
    final total = plot.growDuration.inMilliseconds;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  bool isGardenPlotCompleted(int index, {DateTime? now}) {
    return getGardenProgress(index, now: now) >= 1.0;
  }

  Duration? getGardenTimeRemaining(int index, {DateTime? now}) {
    final plot = _gardenPlots[index];
    if (plot == null) return null;
    final current = now ?? DateTime.now();
    final elapsed = current.difference(plot.plantedAt);
    final remaining = plot.growDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String? harvestSeedAt(int index, {DateTime? now}) {
    final plot = _gardenPlots[index];
    if (plot == null) return null;
    if (plot.isHarvested) return null;
    if (!isGardenPlotCompleted(index, now: now)) return null;

    _gardenPlots[index] = GardenPlot(
      seedId: plot.seedId,
      plantedAt: plot.plantedAt,
      growDuration: plot.growDuration,
      isHarvested: true,
    );

    // Harvesting a seed yields 1 matching fruit item.
    final wasUnlocked = _unlockedFruits.contains(plot.seedId);
    _unlockedFruits.add(plot.seedId);
    if (!wasUnlocked) {
      _unseenFruits.add(plot.seedId);
    }
    _collectedFruitCounts[plot.seedId] =
        (_collectedFruitCounts[plot.seedId] ?? 0) + 1;
    _coins += 2;
    _totalCoinsEarned += 2;
    final harvestXp = getSeedHarvestXp(plot.seedId);
    _xp += harvestXp;
    _totalXpEarned += harvestXp;
    while (_xp >= xpNeeded) {
      _xp -= xpNeeded;
      _level++;
    }
    _queueNewBadgesIfAny();
    notifyListeners();
    unawaited(_persistToFirestore());
    return plot.seedId;
  }

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
      final location = locations.firstWhere((loc) => loc.id == locationId);
      return location.letter.toUpperCase();
    } catch (_) {
      return null;
    }
  }

  // ================= QUEST LOGIC =================

  QuestLocation? get nearestLocation {
    if (_currentPosition == null || locations.isEmpty) {
      return null;
    }

    QuestLocation? nearest;
    double minDistance = double.infinity;

    for (var location in locations) {
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
    // no fixed locations any more – dynamic quests are generated around the
    // player's current GPS position. calling this method from HomeScreen is
    // kept for backward compatibility but it no longer populates any list.
    final now = DateTime.now();
    if (_lastQuestRefresh != null &&
        now.difference(_lastQuestRefresh!) <= _questRefreshInterval &&
        _dynamicQuestLocations.isNotEmpty) {
      return;
    }
    _dynamicQuestLocations.clear();
    if (_currentPosition != null) {
      final player = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      _generateQuestLocations(player);
      _lastQuestRefresh = DateTime.now();
      _lastQuestCenter = player;
      notifyListeners();
    }
  }

  // ================= GPS =================

  Future<void> startTracking() async {
    bool hasPermission = await _locationService.requestPermission();
    if (!hasPermission) return;

    _positionSubscription =
        _locationService.getPositionStream().listen((position) async {
      _recordDistance(position);
      _currentPosition = position;

      // GPS heading used if compass not available or stationary
      if (position.heading >= 0) {
        final now = DateTime.now();
        if (now.difference(_lastHeadingUpdate) >= _headingUpdateInterval) {
          _lastHeadingUpdate = now;
          _heading = position.heading;
        }
      }

      final playerLatLng = LatLng(position.latitude, position.longitude);
      _ensureFruitMarketNear(playerLatLng);
      _ensureAnimalMarketNear(playerLatLng);

      // quest management & area density do not block the main loop
      _maybeRefreshQuests(playerLatLng);
      unawaited(_updateAreaDensityIfNeeded(playerLatLng));

      _checkUnlocks();
      _spawnService.updateSpawns(playerLatLng);
      notifyListeners();
    });

    // start listening to device compass (orientation)
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        final now = DateTime.now();
        if (now.difference(_lastHeadingUpdate) >= _headingUpdateInterval) {
          _lastHeadingUpdate = now;
          // heading measured clockwise from north
          _heading = event.heading!;
          notifyListeners();
        }
      }
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _compassSubscription?.cancel();
  }

  void _recordDistance(Position position) {
    if (_firstPlayedAt == null) {
      _firstPlayedAt = DateTime.now();
    }
    if (_lastDistancePosition == null) {
      _lastDistancePosition = position;
      return;
    }
    final delta = Geolocator.distanceBetween(
      _lastDistancePosition!.latitude,
      _lastDistancePosition!.longitude,
      position.latitude,
      position.longitude,
    );
    _lastDistancePosition = position;
    if (delta < _minDistanceThresholdMeters) return;

    _totalDistanceMeters += delta;
    _pendingDistanceMeters += delta;
    final now = DateTime.now();
    final key =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _dailyDistanceMeters[key] = (_dailyDistanceMeters[key] ?? 0) + delta;

    if (_pendingDistanceMeters >= 25 ||
        now.difference(_lastDistancePersist) >= _distancePersistInterval) {
      _pendingDistanceMeters = 0;
      _lastDistancePersist = now;
      unawaited(_persistStatsSnapshot());
    }
  }

  // ================= UNLOCK =================

  void _checkUnlocks() {
    if (_currentPosition == null) return;

    for (var location in locations) {
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

  bool isUnlocked(String locationId) => _unlockedLocations.contains(locationId);

  bool markVisited(String id) {
    if (_visitedLocations.contains(id)) return false;

    _visitedLocations.add(id);
    _coins += 8;
    _totalCoinsEarned += 8;
    addXP(10);
    _queueNewBadgesIfAny();

    notifyListeners();
    _persistToFirestore();
    return true;
  }

  final Set<String> _shownBadgeTitles = {};
  final List<String> _pendingBadgeTitles = [];

  List<String> consumePendingBadgeTitles() {
    final badges = List<String>.from(_pendingBadgeTitles);
    _pendingBadgeTitles.clear();
    return badges;
  }

  void _queueNewBadgesIfAny() {
    final unlockedNow = _computeUnlockedBadgeTitles();
    for (final title in unlockedNow) {
      if (_shownBadgeTitles.contains(title)) continue;
      _shownBadgeTitles.add(title);
      _pendingBadgeTitles.add(title);
      _unseenBadges.add(title);
    }
  }

  Set<String> _computeUnlockedBadgeTitles() {
    final animals = _unlockedAnimals.length;
    final seeds = _unlockedSeeds.length;
    final visited = _visitedLocations.length;
    final level = _level;
    final discoveredSpecies = animals + seeds;

    final unlocked = <String>{};

    if (animals >= 1) unlocked.add("First Animal");
    if (animals >= 5) unlocked.add("5 Animals");
    if (animals >= 10) unlocked.add("10 Animals");
    if (animals >= 15) unlocked.add("15 Animals");
    if (animals >= 20) unlocked.add("20 Animals");

    if (seeds >= 1) unlocked.add("First Seed");
    if (seeds >= 5) unlocked.add("5 Seeds");
    if (seeds >= 10) unlocked.add("10 Seeds");
    if (seeds >= 15) unlocked.add("15 Seeds");
    if (seeds >= 20) unlocked.add("20 Seeds");

    if (visited >= 1) unlocked.add("Explorer I");
    if (visited >= 3) unlocked.add("Explorer II");
    if (visited >= 5) unlocked.add("Explorer III");
    if (visited >= 7) unlocked.add("Explorer IV");
    if (visited >= 9) unlocked.add("All Quests");

    if (level >= 2) unlocked.add("Level 2");
    if (level >= 3) unlocked.add("Level 3");
    if (level >= 5) unlocked.add("Level 5");
    if (level >= 8) unlocked.add("Level 8");
    if (level >= 10) unlocked.add("Level 10");

    if (discoveredSpecies >= 10) unlocked.add("10 Species");
    if (discoveredSpecies >= 20) unlocked.add("20 Species");
    if (discoveredSpecies >= 30) unlocked.add("30 Species");
    if (discoveredSpecies >= 40) unlocked.add("40 Species");
    if (animals >= 20 && seeds >= 20 && visited >= 9) {
      unlocked.add("Samui Master");
    }

    return unlocked;
  }
}
