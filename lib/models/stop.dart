import 'package:hive/hive.dart';

part 'stop.g.dart'; // Generated file

@HiveType(typeId: 0)
class Stop extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double lat;

  @HiveField(3)
  double lon;

  @HiveField(4)
  bool isFavorite;

  Stop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.isFavorite = false,
  });
}
