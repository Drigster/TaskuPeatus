import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Utils {
  static final _csvRegex = RegExp(r'(?:"([^"]*)"|([^";]*))(?:;|$)');
  static List<String> parseCsvLine(String line) {
    return _csvRegex
        .allMatches(line)
        .map((match) => match.group(1) ?? match.group(2) ?? '')
        .toList();
  }

  static DateTime getLastModifiedFromHeaders(Map<String, String> headers) {
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

  static Future<DateTime> getLastModifiedVersion(Uri url) async {
    try {
      var response = await http.head(url);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return getLastModifiedFromHeaders(response.headers);
      }

      response = await http.get(
        url,
        headers: {'Range': 'bytes=0-0'},
      );

      if (response.statusCode == 206 || response.statusCode == 200) {
        return getLastModifiedFromHeaders(response.headers);
      }

      throw Exception('No valid response received');
    } catch (e) {
      throw Exception('Error retrieving version: $e');
    }
  }

  static (IconData, Color) getTransportIconAndColor(String transportType) {
    IconData typeIcon;
    Color typeColor;
    switch (transportType) {
      case "metro":
        typeIcon = Icons.directions_subway;
        typeColor = Color(0xffff6A00);
      case "bus":
      case "nightbus":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xff00e1b4);
        break;
      case "trol":
        typeIcon = Icons.trolley;
        typeColor = Color(0xff0064d7);
        break;
      case "tram":
        typeIcon = Icons.tram;
        typeColor = Color(0xffff601e);
        break;
      case "regionalbus":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xff9c1630);
        break;
      // Copied from https://transport.tallinn.ee CSS
      case "suburbanbus":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xff004a7f);
        break;
      case "commercialbus":
      case "intercitybus":
      case "internationalbus":
      case "seasonalbus":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xff800080);
        break;
      case "expressbus":
      case "minibus":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xff008000);
        break;
      case "train":
        typeIcon = Icons.directions_train;
        typeColor = Color(0xff009900);
        break;
      case "plane":
        typeIcon = Icons.flight;
        typeColor = Color(0xff404040);
        break;
      case "festal":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xffffa500);
        break;
      case "eventbus":
        typeIcon = Icons.directions_bus;
        typeColor = Color(0xffff6a00);
        break;
      case "ferry":
      case "aquabus":
        typeIcon = Icons.directions_ferry;
        typeColor = Color(0xff0064d7);
        break;
      default:
        typeIcon = Icons.question_mark;
        typeColor = Color(0xff000000);
        break;
    }

    return (typeIcon, typeColor);
  }
}
