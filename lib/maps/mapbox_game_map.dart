import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart';

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

class _MapboxGameMapState extends State<MapboxGameMap> {
  MapboxMap? mapboxMap;
  bool styleReady = false;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(
        "");
  }

  @override
  void didUpdateWidget(covariant MapboxGameMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!styleReady || mapboxMap == null) return;

    _updateMap();
  }

  Future<void> _updateMap() async {
    final player = widget.playerPosition;

    if (player.latitude == 0 || player.longitude == 0) {
      print("GPS not ready yet");
      return;
    }

    print("Updating map with GPS: ${player.latitude}, ${player.longitude}");

    // Center camera
    await mapboxMap!.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(player.longitude, player.latitude),
        ),
        zoom: 16,
      ),
    );

    // Build GeoJSON
    List<Map<String, dynamic>> features = [];

    // Player
    features.add({
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [player.longitude, player.latitude]
      },
      "properties": {"type": "player"}
    });

    // Quests
    for (var loc in widget.locations) {
      features.add({
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [loc.longitude, loc.latitude]
        },
        "properties": {"type": "quest"}
      });
    }

    final geoJson = {
      "type": "FeatureCollection",
      "features": features,
    };

    final style = mapboxMap!.style;

    // If source already exists → just update data
    if (await style.styleSourceExists("game-source")) {
      final source = await style.getSource("game-source") as GeoJsonSource;
      await source.updateGeoJSON(jsonEncode(geoJson));
      return;
    }

    // Otherwise create source + layer once
    await style.addSource(
      GeoJsonSource(
        id: "game-source",
        data: jsonEncode(geoJson),
      ),
    );

    await style.addLayer(
      CircleLayer(
        id: "game-layer",
        sourceId: "game-source",
        circleRadius: 8,
        circleColorExpression: [
          "match",
          ["get", "type"],
          "player",
          "#0000FF",
          "#FF0000"
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: (map) {
        mapboxMap = map;
      },
      onMapLoadedListener: (_) {
        print("MAP FULLY LOADED");
        styleReady = true;
        _updateMap();
      },
    );
  }
}