import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'game_map.dart';
import '../models/avatars.dart';
import '../providers/game_provider.dart';
import '../models/map_spawn.dart';

class OsmGameMap extends GameMap {
  final MapController mapController;
  final Animation<double> pulseAnimation;
  final Animation<double> bounceAnimation;
  final PlayerAvatar selectedAvatar;
  final String? nearestLocationId;
  final VoidCallback onMapReady;
  final void Function(double rotation, bool hasGesture)
      onPositionChanged;

  const OsmGameMap({
    super.key,
    required this.mapController,
    required super.playerPosition,
    required super.locations,
    required super.visited,
    required this.pulseAnimation,
    required this.bounceAnimation,
    required this.selectedAvatar,
    required this.nearestLocationId,
    required this.onMapReady,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final playerLatLng = playerPosition;

    final game = context.watch<GameProvider>();
    final spawns = game.activeSpawns;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialZoom: 19,
        onMapReady: onMapReady,
        onPositionChanged: (position, hasGesture) {
          final rotation = mapController.camera.rotation;
          onPositionChanged(rotation, hasGesture);
        },
      ),
      children: [

        // ================= TILE =================
        TileLayer(
          urlTemplate:
              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.example.samui_quest",
        ),

        // ================= PLAYER RADIUS =================
        AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, _) {
            return CircleLayer(
              circles: [
                CircleMarker(
                  point: playerLatLng,
                  radius: pulseAnimation.value,
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.15),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
              ],
            );
          },
        ),

        // ================= MARKERS =================
        MarkerLayer(
          markers: [

            // -------- PLAYER --------
            Marker(
              point: playerLatLng,
              width: 60,
              height: 60,
              child: AnimatedBuilder(
                animation: bounceAnimation,
                child: Image.asset(
                  selectedAvatar.assetPath,
                  width: 50,
                  height: 50,
                ),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, bounceAnimation.value),
                    child: child,
                  );
                },
              ),
            ),

            // -------- QUESTS --------
            ...locations.map((loc) {
              final completed = visited.contains(loc.id);
              final isNearest =
                  loc.id == nearestLocationId;

              return Marker(
                point:
                    LatLng(loc.latitude, loc.longitude),
                width: 50,
                height: 50,
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, _) {
                    final double glowSize =
                        isNearest && !completed
                            ? 36 +
                                (pulseAnimation.value *
                                    0.15)
                            : 36;

                    return Icon(
                      completed
                          ? Icons.check
                          : Icons.question_mark,
                      size: glowSize,
                      color: completed
                          ? Colors.green
                          : (isNearest
                              ? Colors.red
                              : Colors.orange),
                      shadows: [
                        if (isNearest && !completed)
                          Shadow(
                            blurRadius:
                                12 +
                                    pulseAnimation.value *
                                        0.2,
                            color: Colors.red
                                .withOpacity(0.8),
                          )
                        else
                          const Shadow(
                            blurRadius: 4,
                            color: Colors.white,
                          ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),

// -------- SPAWNS --------
// -------- SPAWNS --------
...spawns.map((spawn) {
  final String assetPath =
      spawn.type == SpawnType.animal
          ? "assets/animals/${spawn.asset}.png"
          : "assets/seeds/${spawn.asset}.png";

  final double size =
      spawn.type == SpawnType.animal ? 32 : 24;

  return Marker(
    point: spawn.position,
    width: 45,
    height: 45,
    alignment: Alignment.center,
    child: GestureDetector(
      onTap: () async {
        // Eerst laten faden
        context.read<GameProvider>()
            .setSpawnVisibility(spawn.id, false);

        await Future.delayed(
            const Duration(milliseconds: 300));

        context.read<GameProvider>()
            .collectSpawn(spawn);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: child,
            ),
          );
        },
        child: spawn.isVisible
            ? SizedBox(
                key: ValueKey(spawn.id),
                width: 45,
                height: 45,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shadow
                    Container(
                      width: 26,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            Colors.black.withOpacity(0.25),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),

                    // Bounce animatie
                    AnimatedBuilder(
                      animation: bounceAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              0,
                              -6 +
                                  bounceAnimation.value),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        assetPath,
                        width: size,
                        height: size,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(
                key: ValueKey("empty"),
              ),
      ),
    ),
  );
}).toList(),

          ],
        ),
      ],
    );
  }
}