import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';

import '../models/avatars.dart';
import '../models/quest_location.dart';

class MapboxGameMap extends StatefulWidget {
  final LatLng playerPosition;
  final List<QuestLocation> locations;
  final Set<String> visited;
  final PlayerAvatar selectedAvatar;
  final String? nearestLocationId;

  const MapboxGameMap({
    super.key,
    required this.playerPosition,
    required this.locations,
    required this.visited,
    required this.selectedAvatar,
    required this.nearestLocationId,
  });

  @override
  State<MapboxGameMap> createState() => _MapboxGameMapState();
}

class _MapboxGameMapState extends State<MapboxGameMap>
    with SingleTickerProviderStateMixin {
  MapboxMap? mapboxMap;
  bool styleReady = false;

  bool autoFollow = false;

  bool initialCameraSet = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    MapboxOptions.setAccessToken(
      "",
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // ✅ meters (geografisch)
    _pulseAnimation = Tween<double>(begin: 50, end: 120).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation.addListener(() async {
      if (mapboxMap != null && styleReady) {
        final style = mapboxMap!.style;

        if (await style.styleLayerExists("player-pulse")) {
          await style.setStyleLayerProperty(
            "player-pulse",
            "circle-radius",
            _pulseAnimation.value,
          );
        }

        if (await style.styleLayerExists("quest-pulse")) {
          await style.setStyleLayerProperty(
            "quest-pulse",
            "circle-radius",
            _pulseAnimation.value,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapboxGameMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (styleReady && mapboxMap != null) {
      _updateMap();
    }
  }

  Future<void> _updateMap() async {
    if (!styleReady || mapboxMap == null) return;

    final player = widget.playerPosition;
    final style = mapboxMap!.style;

    // ================= CAMERA (alleen bij autoFollow) =================
   // Eerste keer altijd camera zetten
if (!initialCameraSet) {
  await mapboxMap!.setCamera(
    CameraOptions(
      center: Point(
        coordinates: Position(player.longitude, player.latitude),
      ),
      zoom: 19.0,
    ),
  );

  initialCameraSet = true;
}

// Daarna alleen bij auto-follow
if (autoFollow) {
  await mapboxMap!.setCamera(
    CameraOptions(
      center: Point(
        coordinates: Position(player.longitude, player.latitude),
      ),
      zoom: 19.0,
    ),
  );
}
    await mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: false),
    );



    // ================= PLAYER SOURCE =================
    final playerGeoJson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [player.longitude, player.latitude]
          }
        }
      ]
    };

    if (!await style.styleSourceExists("player-source")) {
      await style.addSource(
        GeoJsonSource(
          id: "player-source",
          data: jsonEncode(playerGeoJson),
        ),
      );
    } else {
      final source =
          await style.getSource("player-source") as GeoJsonSource;
      await source.updateGeoJSON(jsonEncode(playerGeoJson));
    }

    // ================= QUEST SOURCE =================
    final questGeoJson = {
      "type": "FeatureCollection",
      "features": widget.locations.map((loc) {
        return {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [loc.longitude, loc.latitude]
          }
        };
      }).toList(),
    };

    if (!await style.styleSourceExists("quest-source")) {
      await style.addSource(
        GeoJsonSource(
          id: "quest-source",
          data: jsonEncode(questGeoJson),
        ),
      );
    } else {
      final source =
          await style.getSource("quest-source") as GeoJsonSource;
      await source.updateGeoJSON(jsonEncode(questGeoJson));
    }

    // ================= PLAYER AVATAR IMAGE =================
    if (await style.getStyleImage("player-avatar") == null) {
      final data =
          await rootBundle.load(widget.selectedAvatar.assetPath);
      final bytes = data.buffer.asUint8List();
      final image = await decodeImageFromList(bytes);

      final mbxImage = MbxImage(
        width: image.width,
        height: image.height,
        data: bytes,
      );

      await style.addStyleImage(
        "player-avatar",
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
    }

    // ================= QUEST ICON IMAGE =================
    if (await style.getStyleImage("quest-icon") == null) {
      final data = await rootBundle.load("assets/quest_red.png");
      final bytes = data.buffer.asUint8List();
      final image = await decodeImageFromList(bytes);

      final mbxImage = MbxImage(
        width: image.width,
        height: image.height,
        data: bytes,
      );

      await style.addStyleImage(
        "quest-icon",
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
    }

    // ================= QUEST PULSE =================
    if (!await style.styleLayerExists("quest-pulse")) {
      await style.addLayer(
        CircleLayer(
          id: "quest-pulse",
          sourceId: "quest-source",
          circleRadius: 50,
          circleColor: 0x88FF0000,
          circleBlur: 0.5,
          circlePitchAlignment: CirclePitchAlignment.MAP,
        ),
      );
    }

    // ================= QUEST SYMBOL =================
    if (!await style.styleLayerExists("quest-layer")) {
      await style.addLayer(
        SymbolLayer(
          id: "quest-layer",
          sourceId: "quest-source",
          iconImage: "quest-icon",
          iconSize: 0.12,
          iconAnchor: IconAnchor.CENTER,
          iconAllowOverlap: true,
        ),
      );
    }

    // ================= PLAYER PULSE =================
    if (!await style.styleLayerExists("player-pulse")) {
      await style.addLayer(
        CircleLayer(
          id: "player-pulse",
          sourceId: "player-source",
          circleRadius: 50,
          circleColor: 0xAA3399FF, // sterkere blauwe glow
          circleBlur: 0.5,
          circlePitchAlignment: CirclePitchAlignment.MAP,
        ),
      );
    }

    // ================= PLAYER SYMBOL =================
    if (!await style.styleLayerExists("player-layer")) {
      await style.addLayer(
        SymbolLayer(
          id: "player-layer",
          sourceId: "player-source",
          iconImage: "player-avatar",
          iconSize: 0.1,
          iconAnchor: IconAnchor.CENTER,
          iconAllowOverlap: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          styleUri: MapboxStyles.MAPBOX_STREETS,
          onMapCreated: (map) async {
            mapboxMap = map;

            await mapboxMap!.scaleBar.updateSettings(
              ScaleBarSettings(enabled: false),
            );

            await mapboxMap!.logo.updateSettings(
              LogoSettings(enabled: false),
            );

            await mapboxMap!.attribution.updateSettings(
              AttributionSettings(enabled: false),
            );
          },
          onStyleLoadedListener: (_) async {
            styleReady = true;
            await _updateMap();
          },
        ),

        // ================= AUTO FOLLOW BUTTON =================
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton(
            backgroundColor:
                autoFollow ? Colors.blue : Colors.grey[800],
            onPressed: () {
              setState(() {
                autoFollow = !autoFollow;
              });

              if (autoFollow) {
                _updateMap();
              }
            },
            child: Icon(
              autoFollow ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}