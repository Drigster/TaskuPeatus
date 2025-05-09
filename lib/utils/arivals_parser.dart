import 'package:http/http.dart' as http;
import 'package:tasku_peatus/utils/geo_utils.dart';
import '../models/stop.dart';

class ArrivalsParser {
  static final _csvRegex = RegExp(r'(?:^|,)(?:"([^"]*)"|([^",]*))');

  static List<String> _parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

  static Future<List<StopData>> getArrivals(List<Stop> stops, lat, lon) async {
    if (stops.isEmpty) return [];
    print(
        "https://transport.tallinn.ee/siri-stop-departures.php?stopid=${stops.map((e) => e.id).join(',')}&time=${DateTime.now().millisecondsSinceEpoch}");
    final response = await http.get(
      Uri.parse(
        "https://transport.tallinn.ee/siri-stop-departures.php?stopid=${stops.map((e) => e.id).join(',')}&time=${DateTime.now().millisecondsSinceEpoch}",
      ),
    );
    final data = response.body;

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
        return [];
      }
      if (lines[i].trim() == "") {
        if (i == 1) {
          return [];
        }
        continue;
      }
      List<String> line = lines[i].split(",");
      if (i == 0) {
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
        final stopId = line[1];
        final currentStop = stops.firstWhere((e) => e.id == stopId);
        stopData = StopData(
          id: stopId,
          name: currentStop.name,
          distance: GeoUtils.haversine(
                  lat ?? 0, lon ?? 0, currentStop.lat, currentStop.lon)
              .ceil(),
          isFavorite: currentStop.isFavorite,
          departures: [],
        );

        continue;
      }

      if (!startedParsingStops) {
        continue;
      }

      if (stopData!.departures
          .any((e) => e.routeNumber == line[routeNumIndex])) {
        var departures = stopData.departures
            .firstWhere((e) => e.routeNumber == line[routeNumIndex]);
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

    stopsRet.add(stopData!);
    print(stopsRet.map((e) => e.distance).toList());
    stopsRet.sort((a, b) => a.distance.compareTo(b.distance));
    print(stopsRet.map((e) => e.distance).toList());
    return stopsRet;
  }
}

class StopData {
  final String id;
  final String name;
  final int distance;
  final bool isFavorite;
  final List<Departure> departures;

  StopData({
    required this.id,
    required this.name,
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
