import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/map_spawn.dart';

class SpawnService {
  final Random _random = Random();

  static const int minSpawns = 2;
  static const int maxSpawns = 5;

  static const double spawnRadiusMeters = 60;
  static const double respawnDistanceMeters = 100;
  static const int spawnLifetimeSeconds = 180;

  final List<MapSpawn> _allSpawns = [];

  // 👉 Geef ALLE spawns terug (UI beslist wat zichtbaar is)
  List<MapSpawn> get activeSpawns => _allSpawns;

  LatLng? _lastSpawnCenter;
  DateTime? _nextSpawnTime;

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

      if (distance > respawnDistanceMeters) {
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
        minSpawns + _random.nextInt(maxSpawns - minSpawns + 1);

    for (int i = 0; i < spawnCount; i++) {
      _allSpawns.add(_generateSpawn(center));
    }

    // Random respawn delay (1–5 minuten)
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
      final distance = Geolocator.distanceBetween(
        playerPosition.latitude,
        playerPosition.longitude,
        spawn.position.latitude,
        spawn.position.longitude,
      );

      // Alleen zichtbaarheid aanpassen
      spawn.isVisible = distance <= spawnRadiusMeters;
    }
  }

  // ================= GENERATE SINGLE SPAWN =================

  MapSpawn _generateSpawn(LatLng center) {
    final bool isAnimal = _random.nextBool();
    final String asset = isAnimal ? "ladybug" : "pineapple";

    final double r =
        spawnRadiusMeters * sqrt(_random.nextDouble());
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
        const Duration(seconds: spawnLifetimeSeconds),
      ),
      isVisible: true,
    );
  }
}