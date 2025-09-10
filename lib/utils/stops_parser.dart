import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/stop.dart';

class StopsParser {
  static final _csvRegex = RegExp(r'(?:"([^"]*)"|([^";]*))(?:;|$)');
  static final _stopsUrl = "https://transport.tallinn.ee/data/stops.txt";

  static List<String> _parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

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

  static Future<DateTime> getLastModifiedVersion() async {
    try {
      var response = await http.head(Uri.parse(_stopsUrl));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseHeader(response.headers);
      }

      response = await http.get(
        Uri.parse(_stopsUrl),
        headers: {'Range': 'bytes=0-0'},
      );

      if (response.statusCode == 206 || response.statusCode == 200) {
        return _parseHeader(response.headers);
      }

      throw Exception('No valid response received');
    } catch (e) {
      throw Exception('Error retrieving version: $e');
    }
  }

  static DateTime _parseHeader(Map<String, String> headers) {
    final lastModified = headers['last-modified'] ??
        headers['date'] ??
        DateTime.now().toUtc().toString();

    try {
      return DateFormat('EEE, dd MMM yyyy HH:mm:ss z', 'en_US')
          .parse(lastModified);
    } catch (e) {
      return DateTime.parse(lastModified);
    }
  }

  static Future<(List<Stop>, bool)> parseStops() async {
    List<Stop> newStops = [];
    bool parsedWithErrors = false;

    final response = await http.get(Uri.parse(_stopsUrl));
    final data = utf8.decode(response.bodyBytes);
    final lines = data.split('\n'); // Skip header

    final header = lines[0].split(";");
    final siriIndex = header.indexOf("SiriID");
    final latIndex = header.indexOf("Lat");
    final lonIndex = header.indexOf("Lng");
    final nameIndex = header.indexOf("Name");

    List<String> previousParts = List.filled(header.length, "");

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];

      final parts = _parseCsvLine(line);
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
        if (parts.length <= siriIndex) {
          print("\"$line\" has no stopID");
          continue;
        }
        final stopId = parts[siriIndex].trim();
        if (stopId.isEmpty) {
          continue;
        }
        if (parts.length <= nameIndex) {
          print("\"$line\" has no name");
          continue;
        }
        final name = parts[nameIndex].trim();
        if (parts.length <= latIndex) {
          print("\"$line\" has no lat");
          continue;
        }
        final lat = double.parse(parts[latIndex]) / 100000;
        if (parts.length <= lonIndex) {
          print("\"$line\" has no lon");
          continue;
        }
        final lon = double.parse(parts[lonIndex]) / 100000;

        final stop = Stop(
          id: stopId,
          name: name,
          lat: lat,
          lon: lon,
        );
        newStops.add(stop);
      } catch (e) {
        print('Error parsing line: $line\nError: $e');
        parsedWithErrors = true;
      }
    }

    return (newStops, parsedWithErrors);
  }

  // static Future<(List<Route>, bool)> parseRoutes() async {
  //   List<Stop> newStops = [];
  //   bool parsedWithErrors = false;

  //   final response = await http.get(Uri.parse(_stopsUrl));
  //   final data = response.body;
  //   final lines = data.split('\n'); // Skip header

  //   final header = lines[0].split(";");
  //   final siriIndex = header.indexOf("SiriID");
  //   final latIndex = header.indexOf("Lat");
  //   final lonIndex = header.indexOf("Lng");
  //   final nameIndex = header.indexOf("Name");

  //   List<String> previousParts = List.filled(header.length, "");

  //   for (var i = 1; i < lines.length; i++) {
  //     final line = lines[i];

  //     final parts = _parseCsvLine(line);
  //     if (parts.length < header.length) {
  //       parts.addAll(List.filled(header.length - parts.length, ''));
  //     }

  //     for (int j = 0; j < parts.length; j++) {
  //       if (parts[j].trim() == "") {
  //         parts[j] = previousParts[j];
  //       } else {
  //         previousParts[j] = parts[j];
  //       }
  //     }

  //     try {
  //       if (parts.length <= siriIndex) {
  //         print("\"$line\" has no stopID");
  //         continue;
  //       }
  //       final stopId = parts[siriIndex].trim();
  //       if (parts.length <= nameIndex) {
  //         print("\"$line\" has no name");
  //         continue;
  //       }
  //       final name = parts[nameIndex].trim();
  //       if (parts.length <= latIndex) {
  //         print("\"$line\" has no lat");
  //         continue;
  //       }
  //       final lat =
  //           double.parse(insertAfterSecond(parts[latIndex].trim(), '.'));
  //       if (parts.length <= lonIndex) {
  //         print("\"$line\" has no lon");
  //         continue;
  //       }
  //       final lon =
  //           double.parse(insertAfterSecond(parts[lonIndex].trim(), '.'));

  //       final stop = Stop(
  //         id: stopId,
  //         name: name,
  //         lat: lat,
  //         lon: lon,
  //       );
  //       newStops.add(stop);
  //     } catch (e) {
  //       print('Error parsing line: $line\nError: $e');
  //       parsedWithErrors = true;
  //     }
  //   }

  //   return (newStops, parsedWithErrors);
  // }
}
