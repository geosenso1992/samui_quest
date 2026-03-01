import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../maps/mapbox_game_map.dart';

import '../models/avatars.dart';
import '../services/audio_service.dart';
import '../providers/game_provider.dart';
import 'quest_screen.dart';
import 'final_word_screen.dart';
import 'collection_screen.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  final PlayerAvatar selectedAvatar;

  const MapScreen({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  bool _isNavigating = false;
  static const double _dotRadius = 26;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AudioService().stopBackground();
      await AudioService().playWalking();
    });
  }

  @override
  void dispose() {
    AudioService().stopWalking();
    super.dispose();
  }

  // ================= SAFE NAVIGATION =================

  void _openQuestIfUnlocked(GameProvider game, location) {
    if (_isNavigating) return;

    if (location != null &&
        game.isUnlocked(location.id) &&
        game.markVisited(location.id)) {
      _isNavigating = true;

      Future.microtask(() async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestScreen(location: location),
          ),
        );
        _isNavigating = false;
      });
    }
  }

  // ================= BEARING CALCULATION =================

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLon = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  Offset _radarDotPosition(double angleRad, double radius) {
    final x = radius * math.sin(angleRad);
    final y = -radius * math.cos(angleRad);
    return Offset(x, y);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final heading = game.heading;
    final position = game.currentPosition;
    final locations = game.locations;

    if (position == null || locations.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final playerLatLng = LatLng(
      position.latitude,
      position.longitude,
    );

    final nearest = game.nearestLocation;
    final nearestDistance = game.nearestDistance;

    _openQuestIfUnlocked(game, nearest);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Samui Quest"),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: "Collection",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CollectionScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: "Final Word",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FinalWordScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [

          // ================= MAP =================

          MapboxGameMap(
            playerPosition: playerLatLng,
            locations: locations,
            visited: game.visitedLocations,
            selectedAvatar: widget.selectedAvatar,
            nearestLocationId: nearest?.id,
          ),

          // ================= XP BAR =================

Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: SafeArea(
    child: Center(
      child: FractionallySizedBox(
        widthFactor: 0.4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Level ${game.level}  •  ${game.xp} / ${game.xpNeeded} XP",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        color: Colors.white24,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final progress =
                              game.xp / game.xpNeeded;

                          return Container(
                            height: 14,
                            width: constraints.maxWidth * progress,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF00FFAA),
                                  Color(0xFF00CCFF),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
),
          // ================= MINI RADAR =================

          Positioned(
            top: 20,
            left: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 3),
                  ),
                ),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),

                ...locations.map((loc) {
                  final completed =
                      game.visitedLocations.contains(loc.id);
                  final questPoint =
                      LatLng(loc.latitude, loc.longitude);

                  final bearing =
                      _calculateBearing(playerLatLng, questPoint);

                  final angleRad = bearing * math.pi / 180;
                  final offset =
                      _radarDotPosition(angleRad, _dotRadius);

                  return Transform.translate(
                    offset: offset,
                    child: Icon(
                      completed
                          ? Icons.check
                          : Icons.question_mark,
                      size: 14,
                      color: completed
                          ? Colors.green
                          : (loc.id == nearest?.id
                              ? Colors.red
                              : Colors.orange),
                    ),
                  );
                }).toList(),

                Transform.rotate(
                  angle: heading * math.pi / 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(60, 60),
                        painter: _ConePainter(),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= DISTANCE BAR =================

          Positioned(
            bottom: 20,
            left: 80,
            right: 80,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Nearest quest: ${nearestDistance.toStringAsFixed(0)} meters",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blue.withOpacity(0.6),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width / 2),
      );

    final path = ui.Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: size.width / 2),
      -math.pi / 4,
      math.pi / 2,
      false,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}