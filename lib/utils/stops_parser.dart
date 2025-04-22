import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/stop.dart';

class StopsParser {
  static final _csvRegex = RegExp(r'(?:^|;)(?:"([^"]*)"|([^";]*))');
  static final _stopsUrl = "https://transport.tallinn.ee/data/stops.txt";

  static List<String> _parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

  static Future<bool> importStops() async {
    final box = Hive.box<Stop>('stopsBox');
    List<Stop> newStops = [];

    //final data = await rootBundle.loadString('assets/stops.txt');
    final response = await http.get(Uri.parse(_stopsUrl));
    final data = response.body;
    final lines = data.split('\n'); // Skip header

    final header = lines[0].split(";");
    final siriIndex = header.indexOf("SiriID");
    final latIndex = header.indexOf("Lat");
    final lonIndex = header.indexOf("Lng");
    final nameIndex = header.indexOf("Name");
    print("$siriIndex $nameIndex $lonIndex $latIndex");

    bool parsedWithErrors = false;
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];

      final parts = _parseCsvLine(line);

      try {
        if (parts.length <= siriIndex) {
          print("\"$line\" has no stopID");
          continue;
        }
        final stopId = parts[siriIndex].trim();
        if (parts.length <= nameIndex) {
          print("\"$line\" has no name");
          continue;
        }
        final name = parts[nameIndex].trim();
        if (parts.length <= latIndex) {
          print("\"$line\" has no lat");
          continue;
        }
        final lat = double.parse(parts[latIndex].trim());
        if (parts.length <= lonIndex) {
          print("\"$line\" has no lon");
          continue;
        }
        final lon = double.parse(parts[lonIndex].trim());

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

    if (parsedWithErrors) {
      print(
          "There was an error when parsing stops, old stops were not cleared");
    } else {
      box.clear();
    }

    await box.addAll(newStops);
    print("added ${newStops.length} stops");

    return !parsedWithErrors;
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
}
