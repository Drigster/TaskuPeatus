import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:tasku_peatus/utils/geo_utils.dart';
import '../models/stop.dart';
import '../services/stop_repository.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Box<Stop> stopsBox;
  Position? location;

  @override
  Future<void> initState() async {
    super.initState();
    stopsBox = Hive.box<Stop>('stopsBox');
    location = await GeoUtils.determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    final stopRepo = StopRepository(Hive.box<Stop>('stopsBox'));
    final nearbyStops = stopRepo.getStopsInRadius(
      centerLat: location?.latitude ?? 0,
      centerLon: location?.longitude ?? 0,
      radiusMeters: 100,
    );

    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
    );

    List<String> ids = nearbyStops.map((stop) => stop.id!).toList();

    // String data =
    //     "Transport,RouteNum,ExpectedTimeInSeconds,ScheduleTimeInSeconds,66955,version20201024\nstop,1079\nbus,36,67007,66971,Viru,52,Z\nbus,5,67569,67559,Metsakooli tee,614,Z\nbus,18A,67613,67439,Viru keskus,658,Z\nbus,36,68115,68105,Viru,1160,Z\nbus,18,68379,68369,Viru keskus,1424,Z\nbus,5,68639,68639,Metsakooli tee,1684,Z\nbus,36,69125,69125,Viru,2170,Z\nbus,20A,69237,69227,Viru keskus,2282,Z\nbus,18A,69299,69299,Viru keskus,2344,Z\nbus,5,69779,69779,Metsakooli tee,2824,Z\nbus,36,70265,70265,Viru,3310,Z\nbus,20,70475,70475,Reisisadama D-terminal,3520,Z\nstop,1080\ntram,3,66978,66978,Kadriorg,23,\ntram,4,67224,67224,Suur-Paala,269,Z\ntram,4,67884,67884,Suur-Paala,929,\ntram,3,68178,68178,Kadriorg,1223,Z\ntram,4,68604,68604,Suur-Paala,1649,Z\ntram,4,69324,69324,Suur-Paala,2369,Z\ntram,3,69498,69498,Kadriorg,2543,\ntram,4,70044,70044,Suur-Paala,3089,\nstop,1081\nbus,36,67090,67080,Väike-Õismäe,135,Z\nbus,5,67318,67308,Männiku,363,Z\nbus,18,67494,67468,Laagri,539,Z\nbus,57,68050,68040,Raudalu,1095,Z\nbus,18A,68128,68128,Urda,1173,Z\nbus,36,68160,68160,Väike-Õismäe,1205,Z\nbus,5,68254,68244,Männiku,1299,Z\nbus,18,68968,68968,Laagri,2013,Z\nbus,20A,69058,69058,Laagri alevik,2103,Z\nbus,5,69204,69204,Männiku,2249,Z\nbus,36,69300,69300,Väike-Õismäe,2345,Z\nbus,18A,69868,69868,Urda,2913,Z\nbus,5,70146,70146,Männiku,3191,Z\nbus,36,70320,70320,Väike-Õismäe,3365,Z";

    // int typeIndex = 0;
    // int routeNumIndex = 1;
    // int expectedTimeIndex = 2;
    // int scheduleTimeIndex = 3;
    // int directionIndex = 4;
    // int extraDataIndex = 6;

    // List<String> lines = data.trim().split("\n");
    // bool startedParsingStops = false;
    List<StopData> stops = [];
    // StopData? stopData;

    // for (int i = 0; i < lines.length; i++) {
    //   List<String> line = lines[i].split(",");
    //   if (i == 0) {
    //     for (int j = 0; j < line.length; j++) {
    //       if (line[j].startsWith("version")) {
    //         String version = line[j].replaceAll("version", "");
    //         if (!version.contains("20201024")) {
    //           print("API UPDATED! New version is $version");
    //         }
    //       }
    //     }
    //     continue;
    //   }

    //   if (line[0] == "stop") {
    //     if (!startedParsingStops) {
    //       startedParsingStops = true;
    //     }
    //     if (stopData != null) {
    //       stops.add(stopData);
    //       stopData = null;
    //     }
    //     final stopId = line[1];
    //     final storedStop = stopsBox.values.firstWhere(
    //       (s) => s.id == stopId,
    //       orElse: () => Stop(
    //         id: stopId,
    //         name: 'Unknown',
    //         lat: 0,
    //         lon: 0,
    //       ),
    //     );
    //     print(
    //         "$currentLat - ${storedStop.lat}, $currentLon - ${storedStop.lon}");
    //     stopData = StopData(
    //       id: stopId,
    //       name: storedStop.name,
    //       distance: GeoUtils.haversine(
    //               currentLat, currentLon, storedStop.lat, storedStop.lon)
    //           .ceil(),
    //       isFavorite: storedStop.isFavorite,
    //       departures: [],
    //     );

    //     continue;
    //   }

    //   if (!startedParsingStops) {
    //     continue;
    //   }

    //   if (stopData!.departures
    //       .any((e) => e.routeNumber == line[routeNumIndex])) {
    //     stopData.departures
    //         .firstWhere((e) => e.routeNumber == line[routeNumIndex])
    //         .scheduleSeconds
    //         .add(int.parse(line[scheduleTimeIndex]));
    //   } else {
    //     Departure departure = Departure(
    //       type: line[typeIndex],
    //       routeNumber: line[routeNumIndex],
    //       expectedSeconds: int.parse(line[expectedTimeIndex]),
    //       scheduleSeconds: [int.parse(line[scheduleTimeIndex])],
    //       direction: line[directionIndex],
    //       extraData: line[extraDataIndex],
    //     );

    //     stopData.departures.add(departure);
    //   }
    // }

    // stops.add(stopData!);

    for (Stop stop in nearbyStops) {
      stops.add(StopData(
        id: stop.id!,
        name: stop.name,
        distance: GeoUtils.haversine(location?.latitude ?? 0,
                location?.longitude ?? 0, stop.lat, stop.lon)
            .ceil(),
        isFavorite: stop.isFavorite,
        departures: [],
      ));
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 4),
                blurRadius: 4,
                color: Color.fromRGBO(0, 0, 0, .25),
              )
            ],
          ),
          child: appBar(context, style, theme),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: ListView.separated(
            padding: EdgeInsets.all(4),
            itemCount: stops.length,
            itemBuilder: (context, index) => StopWidget(
              id: stops[index].id,
              name: stops[index].name,
              distance: stops[index].distance,
              isFavorite: stops[index].isFavorite,
              departures: stops[index].departures,
            ),
            separatorBuilder: (context, index) => const SizedBox(
              height: 4,
            ),
          ),
        ),
      ),
    );
  }

  AppBar appBar(BuildContext context, TextStyle style, ThemeData theme) {
    var color = theme.colorScheme.onSecondary;
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      title: Text("Timetable", style: style),
      centerTitle: true,
      leading: GestureDetector(
        child: Icon(Icons.menu, color: theme.colorScheme.onSecondary),
      ),
      actions: [
        GestureDetector(
          child: AspectRatio(
            aspectRatio: 1 / 1,
            child: Center(
              child: NewWidgetIcon(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class NewWidgetIcon extends StatefulWidget {
  const NewWidgetIcon({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  State<NewWidgetIcon> createState() => _NewWidgetIconState();
}

class _NewWidgetIconState extends State<NewWidgetIcon> {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.refresh,
      color: widget.color,
    );
  }
}

class StopWidget extends StatefulWidget {
  const StopWidget({
    super.key,
    required this.id,
    required this.name,
    required this.distance,
    required this.isFavorite,
    required this.departures,
  });

  final String id;
  final String name;
  final int distance;
  final bool isFavorite;
  final List<Departure> departures;

  @override
  State<StopWidget> createState() => _StopWidgetState();
}

class _StopWidgetState extends State<StopWidget> {
  bool _isExpanded = true;
  late Box<Stop> stopsBox;

  @override
  void initState() {
    super.initState();
    stopsBox = Hive.box<Stop>('stopsBox');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var icon = widget.isFavorite
        ? IconButton(
            icon: Icon(Icons.star, color: Colors.amber),
            onPressed: () => _toggleFavorite(widget.id, false),
          )
        : IconButton(
            icon: Icon(Icons.star_border, color: theme.colorScheme.onPrimary),
            onPressed: () => _toggleFavorite(widget.id, true),
          );

    return Column(
      spacing: _isExpanded ? 4 : 0,
      children: [
        Container(
          height: 35,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              spacing: 2,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        "${widget.name} - ${widget.distance}m",
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                icon,
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 4000),
          curve: Curves.easeInOut,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: _isExpanded ? null : 0,
            child: Column(
              spacing: 4,
              children: [
                for (Departure departure in widget.departures)
                  Transport(
                    type: departure.type,
                    routeNumber: departure.routeNumber,
                    expectedSeconds: departure.expectedSeconds,
                    scheduleSeconds: departure.scheduleSeconds,
                    direction: departure.direction,
                    extraData: departure.extraData,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFavorite(String stopId, bool isFavorite) {
    final stop = stopsBox.values.firstWhere((s) => s.id == stopId);

    stop.isFavorite = isFavorite;
    stop.save();

    setState(() {});
  }
}

class Transport extends StatefulWidget {
  const Transport({
    super.key,
    required this.type,
    required this.routeNumber,
    required this.expectedSeconds,
    required this.scheduleSeconds,
    required this.direction,
    required this.extraData,
  });

  final String type;
  final String routeNumber;
  final int expectedSeconds;
  final List<int> scheduleSeconds;
  final String direction;
  final String extraData;

  @override
  State<Transport> createState() => _TransportState();
}

class _TransportState extends State<Transport> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData typeIcon;
    Color typeColor;
    switch (widget.type) {
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

    DateFormat dateFormater = DateFormat('HH:mm');
    DateTime expectedTime = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    expectedTime = expectedTime.add(Duration(seconds: widget.expectedSeconds));
    Duration untilExpectedTime = expectedTime.difference(DateTime.now()
        .copyWith(
            hour: 18, minute: 36, second: 28, millisecond: 0, microsecond: 0));

    List<String> scheduleTimeStrins = List.empty(growable: true);
    DateTime today = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

    for (int i = 0; i < widget.scheduleSeconds.length; i++) {
      scheduleTimeStrins.add(
        dateFormater.format(
          today.add(
            Duration(
              seconds: widget.scheduleSeconds[i],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 70,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              padding: EdgeInsetsDirectional.only(
                start: 8,
                top: 8,
                bottom: 8,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(
                  typeIcon,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                spacing: 4,
                children: [
                  Container(
                    width: 35,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.routeNumber,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  Text(
                    widget.direction,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                scheduleTimeStrins.join(', '),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          Spacer(),
          Container(
            alignment: Alignment.center,
            padding: EdgeInsetsDirectional.only(end: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  untilExpectedTime.inMinutes.toString(),
                  style: TextStyle(
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  "минут",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
