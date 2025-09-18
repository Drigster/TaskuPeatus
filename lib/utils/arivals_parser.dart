import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:tasku_peatus/utils/geo_utils.dart';
import '../models/stop.dart';

class ArrivalsParser {
  static Future<List<StopData>> getArrivals(List<Stop> stops, lat, lon) async {
    if (stops.isEmpty) return [];
    String data = "";
    int takeCursor = 0;
    while (stops.length >= takeCursor) {
      var reqStops = stops.sublist(
        takeCursor,
        min((takeCursor += 5), stops.length),
      );
      print(
        "https://transport.tallinn.ee/siri-stop-departures.php?stopid=${reqStops.map((e) => e.siriId).join(',')}&time=${DateTime.now().millisecondsSinceEpoch}",
      );
      final response = await http.get(
        Uri.parse(
          "https://transport.tallinn.ee/siri-stop-departures.php?stopid=${reqStops.map((e) => e.siriId).join(',')}&time=${DateTime.now().millisecondsSinceEpoch}",
        ),
      );
      data += utf8.decode(response.bodyBytes).trim();
    }

    int typeIndex = 0;
    int routeNumIndex = 1;
    int expectedTimeIndex = 2;
    int scheduleTimeIndex = 3;
    int directionIndex = 4;
    int extraDataIndex = 6;

    final lines = data.split('\n'); // Skip header

    bool startedParsingStops = false;
    List<StopData> stopsRet = [];
    StopData? stopData;

    for (int i = 0; i < lines.length; i++) {
      if (lines.length == 1) {
        break;
      }
      if (lines[i].trim() == "") {
        if (i == 1) {
          break;
        }
        continue;
      }
      List<String> line = lines[i].split(",");
      if (line.contains("ExpectedTimeInSeconds")) {
        for (int j = 0; j < line.length; j++) {
          if (line[j].startsWith("version")) {
            String version = line[j].replaceAll("version", "");
            if (!version.contains("20201024")) {
              print("API UPDATED! New version is $version");
            }
          }
        }
        continue;
      }
      if (line[0] == "stop") {
        if (!startedParsingStops) {
          startedParsingStops = true;
        }
        if (stopData != null) {
          stopsRet.add(stopData);
          stopData = null;
        }
        final siriId = line[1];
        final currentStop = stops.firstWhere((e) => e.siriId == siriId);
        stopData = StopData(
          stop: currentStop,
          distance: GeoUtils.haversine(
            lat ?? 0,
            lon ?? 0,
            currentStop.lat,
            currentStop.lon,
          ).ceil(),
          isFavorite: currentStop.isFavorite,
          departures: [],
        );

        continue;
      }

      if (!startedParsingStops) {
        continue;
      }

      if (stopData!.departures.any(
        (e) => e.routeNumber == line[routeNumIndex],
      )) {
        var departures = stopData.departures.firstWhere(
          (e) => e.routeNumber == line[routeNumIndex],
        );
        if (departures.scheduleSeconds.length < 5) {
          departures.scheduleSeconds.add(int.parse(line[scheduleTimeIndex]));
        }
      } else {
        Departure departure = Departure(
          type: line[typeIndex],
          routeNumber: line[routeNumIndex],
          expectedSeconds: int.parse(line[expectedTimeIndex]),
          scheduleSeconds: [int.parse(line[scheduleTimeIndex])],
          direction: line[directionIndex],
          extraData: line[extraDataIndex],
        );

        stopData.departures.add(departure);
      }
    }
    if (stopData != null) {
      stopsRet.add(stopData);
    }
    stopsRet.sort((a, b) => a.distance.compareTo(b.distance));
    final existingIds = stopsRet.map((item) => item.stop.siriId).toSet();
    for (final element in stops) {
      if (existingIds.add(element.siriId)) {
        stopsRet.add(
          StopData(
            stop: element,
            distance: GeoUtils.haversine(
              lat ?? 0,
              lon ?? 0,
              element.lat,
              element.lon,
            ).ceil(),
            isFavorite: element.isFavorite,
            departures: [],
          ),
        );
      }
    }
    return stopsRet;
  }
}

class StopData {
  final Stop stop;
  final int distance;
  final bool isFavorite;
  final List<Departure> departures;

  StopData({
    required this.stop,
    required this.distance,
    required this.isFavorite,
    required this.departures,
  });
}

class Departure {
  final String type;
  final String routeNumber;
  final int expectedSeconds;
  final List<int> scheduleSeconds;
  final String direction;
  final String extraData;

  Departure({
    required this.type,
    required this.routeNumber,
    required this.expectedSeconds,
    required this.scheduleSeconds,
    required this.direction,
    required this.extraData,
  });
}
