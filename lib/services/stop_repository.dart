import 'package:hive/hive.dart';
import '../models/stop.dart';
import '../utils/geo_utils.dart';

class StopRepository {
  final Box<Stop> _box;

  StopRepository(this._box);

  List<Stop> getStopsInRadius({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
  }) {
    // 1. Calculate bounding box in degrees
    final (latDelta, lonDelta) =
        GeoUtils.metersToDegrees(radiusMeters, centerLat);

    // 2. Filter stops using bounding box
    final candidates = _box.values.where((stop) {
      return (stop.lat - centerLat).abs() <= latDelta &&
          (stop.lon - centerLon).abs() <= lonDelta;
    }).toList();

    // 3. Calculate exact distances for candidates
    final stopsInRadius = <Stop>[];
    for (final stop in candidates) {
      final distance = GeoUtils.haversine(
        centerLat,
        centerLon,
        stop.lat,
        stop.lon,
      );
      if (distance <= radiusMeters) {
        stopsInRadius.add(stop);
      }
    }

    return stopsInRadius;
  }
}
