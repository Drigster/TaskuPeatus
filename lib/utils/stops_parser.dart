import 'package:hive/hive.dart';
import '../models/stop.dart';
import 'package:flutter/services.dart';

class StopsParser {
  static final _csvRegex = RegExp(r'(?:^|,)(?:"([^"]*)"|([^",]*))');

  static List<String> _parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

  static Future<void> importStops() async {
    final box = Hive.box<Stop>('stopsBox');
    final existingStops = {for (var s in box.values) s.id: s};

    final data = await rootBundle.loadString('assets/stops.txt');
    final lines = data.split('\n').skip(1); // Skip header

    for (var line in lines) {
      final parts = _parseCsvLine(line);
      if (parts.length < 5) continue;

      try {
        final stopId = parts[0].trim();
        final name = parts[2].trim();
        final lat = double.parse(parts[3].trim());
        final lon = double.parse(parts[4].trim());

        if (existingStops.containsKey(stopId)) {
          final stop = existingStops[stopId]!;
          stop
            ..name = name
            ..lat = lat
            ..lon = lon;
          await stop.save();
        } else {
          final stop = Stop(
            id: stopId,
            name: name,
            lat: lat,
            lon: lon,
          );
          await box.add(stop);
        }
      } catch (e) {
        print('Error parsing line: $line\nError: $e');
      }
    }
  }

  // static Future<DateTime> getLastModifiedVersion(String url) async {
  //   try {
  //     var response = await http.head(Uri.parse(url));
  //     if (response.statusCode >= 200 && response.statusCode < 300) {
  //       return _parseHeader(response.headers);
  //     }

  //     response = await http.get(
  //       Uri.parse(url),
  //       headers: {'Range': 'bytes=0-0'},
  //     );

  //     if (response.statusCode == 206 || response.statusCode == 200) {
  //       return _parseHeader(response.headers);
  //     }

  //     throw Exception('No valid response received');
  //   } catch (e) {
  //     throw Exception('Error retrieving version: $e');
  //   }
  // }

  // static DateTime _parseHeader(Map<String, String> headers) {
  //   final lastModified = headers['last-modified'] ??
  //       headers['date'] ??
  //       DateTime.now().toUtc().toString();

  //   try {
  //     return DateFormat('EEE, dd MMM yyyy HH:mm:ss z', 'en_US')
  //         .parse(lastModified);
  //   } catch (e) {
  //     return DateTime.parse(lastModified);
  //   }
  // }
}
