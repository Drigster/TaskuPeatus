import 'dart:math';

import 'package:geolocator/geolocator.dart';

class GeoUtils {
  static const double earthRadius = 6371e3; // Meters

  static (double, double) metersToDegrees(double meters, double lat) {
    const metersPerDegree = 111319.9; // Average meters per degree
    final latDelta = meters / metersPerDegree;
    final lonDelta = meters / (metersPerDegree * cos(lat * pi / 180));
    return (latDelta, lonDelta);
  }

  static double haversine(double lat1, double lon1, double lat2, double lon2) {
    final l1 = lat1 * pi / 180;
    final l2 = lat2 * pi / 180;
    final d1 = (lat2 - lat1) * pi / 180;
    final d2 = (lon2 - lon1) * pi / 180;

    final a = sin(d1 / 2) * sin(d1 / 2) +
        cos(l1) * cos(l2) * sin(d2 / 2) * sin(d2 / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
