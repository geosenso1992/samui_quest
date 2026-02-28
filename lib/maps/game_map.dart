import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/quest_location.dart';

/// Universele coördinaatklasse (map-library onafhankelijk)
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

/// Abstracte map-interface
abstract class GameMap extends StatelessWidget {
  final LatLng playerPosition;
  final List<QuestLocation> locations;
  final Set<String> visited;
  final ValueChanged<double>? onRotationChanged;

  const GameMap({
    Key? key,
    required this.playerPosition,
    required this.locations,
    required this.visited,
    this.onRotationChanged,
  }) : super(key: key);
}