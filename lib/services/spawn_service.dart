import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/map_spawn.dart';
import '../models/animal_metadata.dart';
import '../models/seed_metadata.dart';

class SpawnService {
  final Random _random = Random();

  static const List<String> _animalAssets = [
    'ant',
    'bat',
    'buffalo',
    'butterfly',
    'dragonfly',
    'frog',
    'gecko',
    'giant_hornet',
    'grasshopper',
    'jumping_spider',
    'king_cobra',
    'kingfisher',
    'ladybug',
    'macaque',
    'mosquito',
    'pangolin',
    'praying_mantis',
    'rat',
    'scorpion',
    'squirrel',
  ];

  static const List<String> _seedAssets = [
    'barley',
    'basil',
    'chili',
    'coriander',
    'corn',
    'durian',
    'eggplant',
    'jackfruit',
    'lotus',
    'mango',
    'mustard',
    'peanut',
    'pineapple',
    'rambutan',
    'rice',
    'sesame',
    'soybean',
    'strawberry',
    'tamarind',
    'watermelon',
  ];

  int _minSpawns = 2;
  int _maxSpawns = 30;
  double _spawnRadiusMeters = 60;
  double _respawnDistanceMeters = 100;
  int _spawnLifetimeSeconds = 180;
  double _animalSpawnChance = 0.5;
  double _rareSpawnBoost = 1.0;
  double _specialSpawnBoost = 1.0;

  static const double minDistanceBetweenSpawns = 10; // meters

  final List<MapSpawn> _allSpawns = [];

  // 👉 Geef ALLE spawns terug (UI beslist wat zichtbaar is)
  List<MapSpawn> get activeSpawns => _allSpawns;

  LatLng? _lastSpawnCenter;
  DateTime? _nextSpawnTime;

  void configure({
    int? minSpawns,
    int? maxSpawns,
    double? spawnRadiusMeters,
    double? respawnDistanceMeters,
    int? spawnLifetimeSeconds,
    double? animalSpawnChance,
    double? rareSpawnBoost,
    double? specialSpawnBoost,
  }) {
    if (minSpawns != null) _minSpawns = minSpawns.clamp(1, 50);
    if (maxSpawns != null) _maxSpawns = maxSpawns.clamp(_minSpawns, 100);
    if (spawnRadiusMeters != null) {
      _spawnRadiusMeters = spawnRadiusMeters.clamp(20, 300);
    }
    if (respawnDistanceMeters != null) {
      _respawnDistanceMeters = respawnDistanceMeters.clamp(30, 600);
    }
    if (spawnLifetimeSeconds != null) {
      _spawnLifetimeSeconds = spawnLifetimeSeconds.clamp(30, 3600);
    }
    if (animalSpawnChance != null) {
      _animalSpawnChance = animalSpawnChance.clamp(0.05, 0.95);
    }
    if (rareSpawnBoost != null) {
      _rareSpawnBoost = rareSpawnBoost.clamp(0.5, 10.0);
    }
    if (specialSpawnBoost != null) {
      _specialSpawnBoost = specialSpawnBoost.clamp(0.5, 12.0);
    }
  }

  // ================= MAIN UPDATE =================

  void updateSpawns(LatLng playerPosition) {
    _removeExpired();
    _updateVisibility(playerPosition);

    // 1️⃣ Check of speler nieuwe zone binnenloopt
    if (_lastSpawnCenter != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        _lastSpawnCenter!,
        playerPosition,
      );

      if (distance > _respawnDistanceMeters) {
        _generateNewZone(playerPosition);
        return;
      }
    }

    // 2️⃣ Als er nog zichtbare spawns zijn → niets doen
    if (_allSpawns.any((s) => s.isVisible)) return;

    // 3️⃣ Check timer
    if (_nextSpawnTime != null &&
        DateTime.now().isBefore(_nextSpawnTime!)) {
      return;
    }

    // 4️⃣ Nieuwe spawns maken
    _generateNewZone(playerPosition);
  }

  // ================= GENERATE NEW ZONE =================

  void _generateNewZone(LatLng center) {
  _allSpawns.clear();
  _lastSpawnCenter = center;

  final int spawnCount =
      _minSpawns + _random.nextInt(_maxSpawns - _minSpawns + 1);

  int attempts = 0;

  while (_allSpawns.length < spawnCount && attempts < 50) {
    final newSpawn = _generateSpawn(center);

    bool tooClose = false;

    for (final existing in _allSpawns) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        existing.position,
        newSpawn.position,
      );

      if (distance < minDistanceBetweenSpawns) {
        tooClose = true;
        break;
      }
    }

    if (!tooClose) {
      _allSpawns.add(newSpawn);
    }

    attempts++;
  }

  final int minutes = 1 + _random.nextInt(5);
  _nextSpawnTime =
      DateTime.now().add(Duration(minutes: minutes));
}

  // ================= REMOVE SPAWN (BIJ KLIKKEN) =================

  void removeSpawn(String id) {
    _allSpawns.removeWhere((s) => s.id == id);
  }

  // ================= REMOVE EXPIRED (ALLEEN TIJD) =================

  void _removeExpired() {
    _allSpawns.removeWhere(
      (s) => s.expiresAt.isBefore(DateTime.now()),
    );
  }

  // ================= VISIBILITY CHECK (ALLEEN AFSTAND) =================

  void _updateVisibility(LatLng playerPosition) {
    for (var spawn in _allSpawns) {
      if (spawn.isFading || spawn.isCollected) continue;

      final distance = Geolocator.distanceBetween(
        playerPosition.latitude,
        playerPosition.longitude,
        spawn.position.latitude,
        spawn.position.longitude,
      );

      // Alleen zichtbaarheid aanpassen
      final isVisibleNow = distance <= _spawnRadiusMeters;
      spawn.isVisible = isVisibleNow;
      spawn.opacity = isVisibleNow ? 1.0 : 0.0;
    }
  }

  // ================= GENERATE SINGLE SPAWN =================

  MapSpawn _generateSpawn(LatLng center) {
    final bool isAnimal = _random.nextDouble() < _animalSpawnChance;
    final String asset = isAnimal
        ? _pickWeightedAnimal()
        : _pickWeightedSeed();

    final double r =
        _spawnRadiusMeters * sqrt(_random.nextDouble());
    final double theta =
        _random.nextDouble() * 2 * pi;

    final double dx = r * cos(theta);
    final double dy = r * sin(theta);

    final double newLat =
        center.latitude + (dy / 111320);

    final double newLng =
        center.longitude +
            (dx /
                (111320 *
                    cos(center.latitude * pi / 180)));

    return MapSpawn(
      id: DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(9999).toString(),
      type: isAnimal ? SpawnType.animal : SpawnType.seed,
      asset: asset,
      position: LatLng(newLat, newLng),
      expiresAt: DateTime.now().add(
        Duration(seconds: _spawnLifetimeSeconds),
      ),
      isVisible: true,
    );
  }

  String _pickWeightedAnimal() {
    var totalWeight = 0;
    for (final animal in _animalAssets) {
      totalWeight += _applyRarityWeightBoost(
        id: animal,
        baseWeight: getAnimalSpawnWeight(animal),
        isAnimal: true,
      );
    }

    if (totalWeight <= 0) {
      return _animalAssets[_random.nextInt(_animalAssets.length)];
    }

    var roll = _random.nextInt(totalWeight);
    for (final animal in _animalAssets) {
      roll -= _applyRarityWeightBoost(
        id: animal,
        baseWeight: getAnimalSpawnWeight(animal),
        isAnimal: true,
      );
      if (roll < 0) {
        return animal;
      }
    }

    return _animalAssets.last;
  }

  String _pickWeightedSeed() {
    var totalWeight = 0;
    for (final seed in _seedAssets) {
      totalWeight += _applyRarityWeightBoost(
        id: seed,
        baseWeight: getSeedSpawnWeight(seed),
        isAnimal: false,
      );
    }

    var roll = _random.nextInt(totalWeight);
    for (final seed in _seedAssets) {
      roll -= _applyRarityWeightBoost(
        id: seed,
        baseWeight: getSeedSpawnWeight(seed),
        isAnimal: false,
      );
      if (roll < 0) {
        return seed;
      }
    }

    return _seedAssets.last;
  }

  int _applyRarityWeightBoost({
    required String id,
    required int baseWeight,
    required bool isAnimal,
  }) {
    final multiplier = _rarityMultiplierFor(id: id, isAnimal: isAnimal);
    final boosted = (baseWeight * multiplier).round();
    return boosted < 1 ? 1 : boosted;
  }

  double _rarityMultiplierFor({
    required String id,
    required bool isAnimal,
  }) {
    if (isAnimal) {
      final rarity = kAnimalMetadataByName[id]?.rarity;
      if (rarity == AnimalRarity.rare) return _rareSpawnBoost;
      if (rarity == AnimalRarity.special) return _specialSpawnBoost;
      return 1.0;
    }

    final rarity = kSeedMetadataByName[id]?.rarity;
    if (rarity == SeedRarity.rare) return _rareSpawnBoost;
    if (rarity == SeedRarity.special) return _specialSpawnBoost;
    return 1.0;
  }
}
