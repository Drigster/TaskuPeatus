import 'package:hive/hive.dart';
import 'package:tasku_peatus/utils/arivals_parser.dart';
import '../models/stop.dart';
import '../utils/geo_utils.dart';

class StopRepository {
  final Box<Stop> _box;

  StopRepository(this._box);

  List<Stop> _getStopsInRadius({
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

  Future<List<StopData>> getArrivalsInRadius({
    required double centerLat,
    required double centerLon,
    required double radiusMeters,
  }) {
    final stops = _getStopsInRadius(
      centerLat: centerLat,
      centerLon: centerLon,
      radiusMeters: radiusMeters,
    );
    return ArrivalsParser.getArrivals(stops, centerLat, centerLon);
  }

  Future<List<StopData>> getArrivalsClosest({
    required double centerLat,
    required double centerLon,
    double startingRadius = 100,
  }) async {
    var currentRadius = startingRadius;
    List<Stop> stops = [];
    while (currentRadius <= 2500) {
      stops = _getStopsInRadius(
        centerLat: centerLat,
        centerLon: centerLon,
        radiusMeters: currentRadius,
      );
      if (stops.isNotEmpty) {
        stops = stops.getRange(0, 1).toList();
        stops.addAll(
          _getStopsInRadius(
            centerLat: stops.first.lat,
            centerLon: stops.first.lon,
            radiusMeters: 500,
          ),
        );
        break;
      }
      currentRadius += 50;
    }
    return (await ArrivalsParser.getArrivals(stops, centerLat, centerLon));
  }
}
