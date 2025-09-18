import 'package:hive/hive.dart';

part 'stop.g.dart'; // Generated file

@HiveType(typeId: 0)
class Stop extends HiveObject {
  @HiveField(0)
  final String siriId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double lat;

  @HiveField(3)
  double lon;

  @HiveField(4)
  bool isFavorite;

  @HiveField(5)
  Map<String, Set<String>> transports;

  @HiveField(6)
  final String stopId;

  Stop({
    required this.siriId,
    required this.stopId,
    required this.name,
    required this.lat,
    required this.lon,
    this.isFavorite = false,
    Map<String, String>? transports,
  }) : transports = Map<String, Set<String>>.from(transports ?? {});
}
