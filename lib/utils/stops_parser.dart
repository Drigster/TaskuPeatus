import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/stop.dart';
import 'package:tasku_peatus/utils/utils.dart';

class StopsParser {
  static final _stopsUrl = "https://transport.tallinn.ee/data/stops.txt";

  static Future<bool> importStops() async {
    final box = Hive.box<Stop>('stopsBox');

    //var (newRoutes, routesParsedWithErrors) = await parseRoutes();
    var (newStops, stopsParsedWithErrors) = await parseStops();

    if (stopsParsedWithErrors) {
      print(
          "There was an error when parsing stops, old stops were not cleared");
    } else {
      await box.clear();
    }

    await box.addAll(newStops);

    return !stopsParsedWithErrors;
  }

  static Future<DateTime> getLastModifiedVersion() =>
      Utils.getLastModifiedVersion(Uri.parse(_stopsUrl));

  static Future<(List<Stop>, bool)> parseStops() async {
    List<Stop> newStops = [];
    bool parsedWithErrors = false;

    final response = await http.get(Uri.parse(_stopsUrl));
    final data = utf8.decode(response.bodyBytes);
    final lines = data.split('\n'); // Skip header

    final header = lines[0].split(";");
    final idIndex = header.indexOf("ID");
    final siriIndex = header.indexOf("SiriID");
    final latIndex = header.indexOf("Lat");
    final lonIndex = header.indexOf("Lng");
    final nameIndex = header.indexOf("Name");

    List<String> previousParts = List.filled(header.length, "");

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];

      // Skip comments
      if (line.startsWith("#")) continue;

      final parts = Utils.parseCsvLine(line);
      if (parts.length < header.length) {
        parts.addAll(List.filled(header.length - parts.length, ''));
      }

      for (int j = 0; j < parts.length; j++) {
        if (parts[j].trim() == "") {
          parts[j] = previousParts[j];
        } else {
          previousParts[j] = parts[j];
        }
      }

      try {
        final siriId = parts[siriIndex].trim();
        if (siriId.isEmpty) {
          continue;
        }

        final stopId = parts[idIndex].trim();
        if (stopId.isEmpty) {
          continue;
        }

        final name = parts[nameIndex].trim();

        final lat = double.parse(parts[latIndex]) / 100000;

        final lon = double.parse(parts[lonIndex]) / 100000;

        final stop = Stop(
          siriId: siriId,
          name: name,
          lat: lat,
          lon: lon,
          stopId: stopId,
        );
        newStops.add(stop);
      } catch (e) {
        print('Error parsing line: $line\nError: $e');
        parsedWithErrors = true;
      }
    }

    return (newStops, parsedWithErrors);
  }
}
