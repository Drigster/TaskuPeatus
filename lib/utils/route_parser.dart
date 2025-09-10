import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/stop.dart';

class RouteParser {
  static final _csvRegex = RegExp(r'(?:"([^"]*)"|([^";]*))(?:;|$)');
  static final _routesUrl = "https://transport.tallinn.ee/data/routes.txt";

  static List<String> _parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

  static Future<String> parseRoutes() async {
    List<Stop> newStops = [];
    bool parsedWithErrors = false;

    final response = await http.get(Uri.parse(_routesUrl));
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

    //return (newStops, parsedWithErrors);

    return "OK";
  }
}

class TimetableData {
  final List<String> weekdays;
  final List<int> times;
  final List<bool> lowGround;
  final List<int> validFrom;
  final List<int> validTo;

  TimetableData({
    required this.weekdays,
    required this.times,
    required this.lowGround,
    required this.validFrom,
    required this.validTo,
  });
}

TimetableData explodeTimes(String encodedData) {
  List<int> timetable = []; // one-dimensional array of all decoded times
  List<String> weekdays = [];
  List<int> validFrom = [];
  List<int> validTo = [];
  List<bool> lowGround = [];

  const String plus = "+";
  const String minus = "-";

  int w = 0; // column count in timetable
  int h = 0; // rows count in timetable

  List<String> times = encodedData.split(",");
  int i = 0;
  int prevT = 0;
  int iMax = times.length;

  // Decode start times of trips and calculate columns count
  for (int i = -1, w = 0, h = 0, prevT = 0; ++i < iMax;) {
    String t = times[i];

    if (t == '') {
      // no more start times
      break;
    }

    String tag = t.isNotEmpty ? t[0] : '';
    if (tag == plus || (tag == minus && t.length > 1 && t[1] == '0')) {
      // Ensure lowGround list is large enough
      while (lowGround.length <= i) {
        lowGround.add(false);
      }
      lowGround[i] = true;
    }

    prevT += int.parse(t);
    timetable.add(prevT);
    w++;
  }

  // Fill remaining lowGround values
  for (int j = i - 1; j >= 0; j--) {
    if (j >= lowGround.length) {
      lowGround.add(false);
    } else if (lowGround[j] != true) {
      lowGround[j] = false;
    }
  }

  // Decode valid_from dates
  for (int j = 0; ++i < iMax;) {
    String dayStr = times[i];
    if (dayStr == '') break;

    int day = int.parse(dayStr); // days count from 1970.01.01
    String kStr = times[++i]; // how many columns should use the same value
    int k;

    if (kStr == '') {
      // for all rest columns
      k = w - j; // count of rest columns
      iMax = 0; // for exiting the loop
    } else {
      k = int.parse(kStr); // convert text to integer
    }

    while (k-- > 0) {
      validFrom.add(day); // copy value into k columns
      j++;
    }
  }

  // Decode valid_to dates
  --i;
  iMax = times.length;

  for (int j = 0; ++i < iMax;) {
    String dayStr = times[i];
    if (dayStr == '') break;

    int day = int.parse(dayStr); // days count from 1970.01.01
    String kStr = times[++i]; // how many columns should use the same value
    int k;

    if (kStr == '') {
      // for all rest columns
      k = w - j; // count of rest columns
      iMax = 0; // for exiting the loop
    } else {
      k = int.parse(kStr); // convert text to integer
    }

    while (k-- > 0) {
      // copy value into k columns
      validTo.add(day);
      j++;
    }
  }

  // Decode weekdays
  --i;
  iMax = times.length;

  for (int j = 0; ++i < iMax;) {
    String weekday = times[i]; // read weekdays
    if (weekday == '') break;

    String kStr = times[++i]; // how many columns should use the same value
    int k;

    if (kStr == '') {
      // for all rest columns
      k = w - j; // count of rest columns
      iMax = 0; // for exiting the loop
    } else {
      k = int.parse(kStr); // convert text to integer
    }

    while (k-- > 0) {
      // copy value into k columns
      weekdays.add(weekday);
      j++;
    }
  }

  // Decode driving times to next stop in each trip
  --i;
  h = 1;
  iMax = times.length;

  for (int j = w, wLeft = w, dt = 5; ++i < iMax;) {
    String timeStr = times[i];
    if (timeStr == '') break;

    dt += int.parse(timeStr) - 5; // driving time from previous stop
    String kStr = times[++i]; // how many columns should use the same value
    int k;

    if (kStr != '') {
      // not for all rest columns
      k = int.parse(kStr);
      wLeft -= k; // count of rest columns
    } else {
      k = wLeft; // for all rest columns
      wLeft = 0; // no more columns left
    }

    while (k-- > 0) {
      // add driving time dt to previous stop time for k columns
      timetable.add(dt + timetable[j - w]);
      j++;
    }

    if (wLeft <= 0) {
      wLeft = w; // restart calculating times for all columns of next stop
      dt = 5; // for compensating subtraction of value 5 in first column
      h++;
    }
  }

  return TimetableData(
    weekdays: weekdays,
    times: timetable,
    lowGround: lowGround,
    validFrom: validFrom,
    validTo: validTo,
  );
}
