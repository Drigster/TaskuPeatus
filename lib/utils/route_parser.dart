import 'dart:convert';
import 'dart:math';

import 'package:hive/hive.dart';
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

    final stopsBox = Hive.box<Stop>('stopsBox');

    final response = await http.get(Uri.parse(_routesUrl));
    final data = utf8.decode(response.bodyBytes);
    final lines = data.split('\n'); // Skip header

    final header = lines[0].split(";");
    final routeNumIndex = header.indexOf("RouteNum");
    final transportIndex = header.indexOf("Transport");
    final validityPeriodsIndex = header.indexOf("ValidityPeriods");
    final specialDatesIndex = header.indexOf("SpecialDates");
    final routeStopsIndex = header.indexOf("RouteStops");

    List<String> previousParts = List.filled(header.length, "");

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];

      // Skip comments
      if (line.startsWith("#")) continue;

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
        final routeNum = parts[routeNumIndex].trim();
        if (routeNum.isEmpty) {
          continue;
        }

        final transportType = parts[transportIndex].trim();
        if (transportType.isEmpty) {
          continue;
        }

        final validityPeriods = parts[validityPeriodsIndex].trim().split(",");
        if (validityPeriods.isEmpty) {
          continue;
        }

        final specialDates = parts[specialDatesIndex].trim().split(",");
        if (specialDates.isEmpty) {
          continue;
        }

        final routeStops = parts[routeStopsIndex].trim().split(",");
        if (routeStops.isEmpty) {
          continue;
        }

        if (transportType == "") {
          continue;
        }

        print("Parsed route $routeNum");

        for (var j = 0; j < routeStops.length; j++) {
          final stopId = routeStops[j];
          var stop =
              stopsBox.values.firstWhere((stop) => stop.stopId == stopId);

          if (stop.transports[transportType] == null) {
            stop.transports[transportType] = <String>{};
          }

          stop.transports[transportType]!.add(routeNum);
        }

        i++;
      } catch (e) {
        print('Error parsing line: $line\nError: $e');
        parsedWithErrors = true;
      }
    }

    //return (newStops, parsedWithErrors);

    //stopsBox.close();

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

String getData() {
  final _csvRegex = RegExp(r'(?:"([^"]*)"|([^";]*))(?:;|$)');
  final _stopsUrl = "https://transport.tallinn.ee/data/stops.txt";

  List<String> _parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

  explodeTimes(
      "+331,+18,+17,+16,+16,+15,+15,+13,+14,+14,+14,+16,+18,+20,+20,+16,+17,+19,+20,+23,+24,+24,+24,+15,+19,+19,+22,+20,+20,+18,+18,+16,+16,+15,+14,+15,+15,+15,+16,+16,+18,+18,+20,+20,+23,+24,+25,+25,+25,+25,+25,+22,+26,+26,+26,+28,+28,-01067,+27,+26,+25,+24,+24,+20,+20,+22,+22,+23,+23,+20,+20,+22,+22,+22,+20,+20,+20,+22,+24,+24,+24,+22,+18,+18,+18,+20,+22,+20,+22,+22,+22,+22,+28,+28,+29,+28,+26,+28,+27,+27,+27,+27,+26,+26,-01069,+27,+26,+25,+24,+24,+20,+20,+22,+22,+23,+23,+20,+20,+22,+22,+22,+20,+20,+20,+22,+24,+24,+24,+22,+18,+18,+18,+20,+22,+20,+22,+22,+22,+22,+28,+28,+29,+28,+26,+28,+27,+27,+27,+27,+26,+26,,20332,57,20240,,0,,12345,57,6,47,7,,1,,1,,1,7,6,38,4,,2,7,6,12,4,13,6,18,4,24,6,19,4,28,6,19,4,,1,4,6,3,4,12,6,13,4,38,6,4,4,43,6,4,4,,2,4,4,3,6,12,4,13,6,17,4,1,6,7,4,2,6,42,4,5,6,42,4,,1,4,6,49,4,11,6,6,4,23,6,7,4,1,6,3,4,7,6,6,4,23,6,7,4,1,6,,1,,1,45,4,4,6,,1,4,6,41,6,4,4,4,4,4,6,44,4,3,6,44,4,,2,74,6,19,4,28,6,19,4,,1,3,6,1,4,15,6,26,4,8,6,4,4,6,6,1,4,6,6,4,4,36,6,1,4,6,6,4,4,,1,19,4,13,6,12,4,1,6,25,4,4,6,43,4,4,6,,2,3,4,1,6,28,4,12,6,1,4,4,6,1,4,9,6,4,4,1,6,6,6,4,4,26,4,1,6,3,4,2,6,4,4,1,6,6,6,4,4,26,4,1,6,,1,3,6,1,4,28,6,12,4,1,6,4,4,1,6,3,4,10,6,1,4,36,6,1,4,9,6,1,4,36,6,1,4,,2,6,6,46,4,1,6,10,4,6,6,29,4,3,6,2,4,1,6,6,4,6,6,29,4,3,6,2,4,,2,4,6,28,4,3,6,10,4,4,6,4,4,10,6,7,4,4,6,18,4,1,6,7,4,10,6,7,4,4,6,18,4,1,6,7,4,,2,6,6,25,4,1,6,17,4,8,4,2,6,14,6,1,4,26,6,1,4,3,4,2,6,14,6,1,4,26,6,1,4,,3,3,6,1,4,1,7,1,4,25,6,1,4,2,6,1,4,17,4,1,6,3,4,2,7,1,4,11,6,3,4,19,6,1,4,7,4,2,4,1,6,2,7,1,4,11,6,3,4,19,6,1,4,7,4,2,4,1,6,,2,35,6,8,4,27,4,3,6,19,4,1,6,24,4,3,6,19,4,1,6,,1,4,6,13,4,13,6,1,4,3,6,1,4,8,6,5,4,1,6,1,4,20,6,23,4,8,6,2,4,14,6,23,4,8,6,2,4,,2,3,4,3,6,11,4,2,6,13,6,2,4,10,4,1,6,4,4,1,6,8,4,1,6,11,4,2,6,1,4,1,6,18,4,1,6,7,4,4,6,1,4,1,6,11,4,2,6,1,4,1,6,18,4,1,6,7,4,,1,3,6,1,4,1,6,1,4,11,6,2,4,11,6,4,4,1,6,8,4,1,6,1,4,25,6,2,4,20,6,1,4,24,6,2,4,20,6,1,4,,1,2,6,15,4,2,6,11,4,1,6,1,4,2,6,9,4,26,6,1,4,2,6,2,4,26,6,1,4,15,6,1,4,2,6,2,4,26,6,1,4,,1,33,6,1,4,23,4,1,6,10,6,1,4,35,4,1,6,10,6,1,4,,1,6,6,13,4,11,6,1,4,3,6,1,4,8,6,5,4,1,6,1,4,7,6,2,4,3,6,1,4,1,6,4,4,2,6,2,4,2,6,17,4,2,6,4,4,7,6,2,4,3,6,1,4,1,6,4,4,2,6,2,4,2,6,17,4,2,6,4,4,,1,4,6,2,4,25,6,3,4,1,6,8,4,5,6,1,4,1,6,1,4,12,6,1,4,9,6,1,4,36,6,1,4,9,6,1,4,,1,,");
  return "OK";
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
