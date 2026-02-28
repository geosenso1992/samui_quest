import 'package:geolocator/geolocator.dart';

class DistanceHelper {

  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
  }

  static bool isWithinRadius(
    double userLat,
    double userLng,
    double targetLat,
    double targetLng,
    double radius,
  ) {
    final distance = calculateDistance(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );

    return distance <= radius;
  }
}