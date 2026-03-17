import 'package:latlong2/latlong.dart';

class MapSpawn {
  final String id;
  final LatLng position;
  final SpawnType type;   // SpawnType.animal of SpawnType.seed
  final String asset;     // ‘ladybug’, ‘pineapple’, …
  bool isVisible;
  bool isCollected;
  bool isFading = false;
  double opacity;
  final DateTime expiresAt;

  MapSpawn({
    required this.id,
    required this.position,
    required this.type,
    required this.asset,
    this.isVisible = true,
    this.isCollected = false,
    this.opacity = 1.0,
    required this.expiresAt,
  });
}

enum SpawnType { animal, seed }
