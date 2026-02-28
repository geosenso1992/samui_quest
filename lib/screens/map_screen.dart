import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../maps/game_map.dart';
import '../maps/osm_game_map.dart';

import '../models/avatars.dart';
import '../services/audio_service.dart';
import '../providers/game_provider.dart';
import 'quest_screen.dart';
import 'final_word_screen.dart';
import 'dart:ui' as ui;


import 'collection_screen.dart';

class MapScreen extends StatefulWidget {
  final PlayerAvatar selectedAvatar;

  const MapScreen({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {

  final MapController _mapController = MapController();

  
  
  double mapRotation = 0.0;


  bool _autoFollowEnabled = true;
  bool _mapReady = false;
  bool _hasCenteredInitially = false;
  bool _isNavigating = false;

  LatLng? _lastPosition;


  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _cameraController;
  Animation<LatLng>? _cameraAnimation;
  LatLng? _lastCameraPosition;

  // ✅ XP SYSTEM 


  // 🐒 NIEUW: Bounce controller voor aapje
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  static const double _dotRadius = 26;

  @override
  void initState() {
    super.initState();

    _cameraController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 600),
);

_cameraController.addListener(() {
  if (_cameraAnimation != null) {
    final value = _cameraAnimation!.value;
    _mapController.move(value, 19);
  }
});

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AudioService().stopBackground();
      await AudioService().playWalking();
    });

    // Pulse effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 20, end: 60).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 🐒 Subtiele bounce animatie
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _pulseController.dispose();
    _bounceController.dispose(); // 🐒 belangrijk

    AudioService().stopWalking();

    super.dispose();
  }


void _smoothFollow(LatLng newPosition) {
  if (_lastCameraPosition == null) {
    _lastCameraPosition = newPosition;
    _mapController.move(newPosition, 19);
    return;
  }

  final tween = LatLngTween(
    begin: _lastCameraPosition!,
    end: newPosition,
  );

  _cameraAnimation = tween.animate(
    CurvedAnimation(
      parent: _cameraController,
      curve: Curves.easeOutCubic,
    ),
  );

 if (_cameraController.isAnimating) {
  _cameraController.stop();
}

 _cameraController.forward(from: 0);

  _lastCameraPosition = newPosition;
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

  final geoPoint = GeoPoint(
  position.latitude,
  position.longitude,
);

final playerLatLng = LatLng(
  geoPoint.latitude,
  geoPoint.longitude,
);

  final nearest = game.nearestLocation;
  final nearestDistance = game.nearestDistance;

  _openQuestIfUnlocked(game, nearest);

  // ================= AUTO CENTER =================

  if (_mapReady && _autoFollowEnabled) {
    if (!_hasCenteredInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _smoothFollow(playerLatLng);
      });
      _hasCenteredInitially = true;
    }

    if (_lastPosition == null ||
    _lastPosition!.latitude != playerLatLng.latitude ||
    _lastPosition!.longitude != playerLatLng.longitude) {



  WidgetsBinding.instance.addPostFrameCallback((_) {
    _smoothFollow(playerLatLng);
  });

  _lastPosition = playerLatLng;
}
  }

return Scaffold(
  appBar: AppBar(
  title: const Text("Samui Quest"),
  actions: [

    // 📚 COLLECTION
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

    // 🏆 FINAL WORD
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
      OsmGameMap(
        mapController: _mapController,
        playerPosition: playerLatLng,
        locations: locations,
        visited: game.visitedLocations,
        pulseAnimation: _pulseAnimation,
        bounceAnimation: _bounceAnimation,
        selectedAvatar: widget.selectedAvatar,
        nearestLocationId: nearest?.id,
        onMapReady: () {
          setState(() => _mapReady = true);
        },
        onPositionChanged: (rotation, hasGesture) {
          if (mounted) {
           setState(() {
            mapRotation = rotation;

            if (hasGesture) {
              _autoFollowEnabled = false;
            }
          });
        }
      },
    ),

      // ================= XP BAR =================
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  "Level ${game.level}  •  ${game.xp} / ${game.xpNeeded} XP",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: game.xp / game.xpNeeded,
                    minHeight: 14,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

  // ================= MINI RADAR =================
Positioned(
  top: 20,
  right: 20,
  child: GestureDetector(
    onTap: () {
      if (_mapReady) {
        _mapController.rotate(0);
      }
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue,
              width: 3,
            ),
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

        // ================= QUEST DOTS =================
        ...locations.map((loc) {
          final completed =
              game.visitedLocations.contains(loc.id);
          final questPoint =
              LatLng(loc.latitude, loc.longitude);

          final bearing =
              _calculateBearing(playerLatLng, questPoint);

          // kaartrotatie meenemen
          final relativeAngle = bearing + mapRotation;

          final angleRad =
              relativeAngle * math.pi / 180;

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


        // ================= DYNAMISCHE NOORD INDICATOR =================
        Positioned(
          top: -5,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
  angle: mapRotation * math.pi / 180,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Icon(
        Icons.arrow_drop_up,
        size: 18,
        color: Color.fromARGB(255, 242, 227, 227),
      ),
      Text(
        "N",
        style: TextStyle(
          color: Color.fromARGB(255, 235, 216, 216),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          height: 0.1,
        ),
      ),
    ],
  ),
),
          ),
        ),
      ],
    ),
  ),
),

      // ================= DISTANCE BAR =================
      Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "Distance to nearest quest: ${nearestDistance.toStringAsFixed(0)} meters",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  ),

  // ================= GPS RE-CENTER BUTTON =================
  floatingActionButton: Padding(
    padding: const EdgeInsets.only(bottom: 80),
    child: FloatingActionButton(
      backgroundColor: (_autoFollowEnabled
        ? Colors.blue
        : Colors.grey)
    .withValues(alpha: 0.7),
      onPressed: () {
        setState(() {
          _autoFollowEnabled = true;
        });

        _smoothFollow(playerLatLng);
      },
      child: const Icon(Icons.my_location),
    ),
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