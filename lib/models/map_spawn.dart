import 'package:latlong2/latlong.dart';

enum SpawnType { animal, seed }

class MapSpawn {
  final String id;
  final SpawnType type;
  final String asset;
  final LatLng position;
  final DateTime expiresAt;

  bool isVisible;

  MapSpawn({
    required this.id,
    required this.type,
    required this.asset,
    required this.position,
    required this.expiresAt,
    this.isVisible = true,
  });
}