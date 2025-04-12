import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final int scheduleSeconds;
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
    );

    String data =
        "Transport,RouteNum,ExpectedTimeInSeconds,ScheduleTimeInSeconds,66955,version20201024\nstop,1079\nbus,36,67007,66971,Viru,52,Z\nbus,5,67569,67559,Metsakooli tee,614,Z\nbus,18A,67613,67439,Viru keskus,658,Z\nbus,36,68115,68105,Viru,1160,Z\nbus,18,68379,68369,Viru keskus,1424,Z\nbus,5,68639,68639,Metsakooli tee,1684,Z\nbus,36,69125,69125,Viru,2170,Z\nbus,20A,69237,69227,Viru keskus,2282,Z\nbus,18A,69299,69299,Viru keskus,2344,Z\nbus,5,69779,69779,Metsakooli tee,2824,Z\nbus,36,70265,70265,Viru,3310,Z\nbus,20,70475,70475,Reisisadama D-terminal,3520,Z\nstop,1080\ntram,3,66978,66978,Kadriorg,23,\ntram,4,67224,67224,Suur-Paala,269,Z\ntram,4,67884,67884,Suur-Paala,929,\ntram,3,68178,68178,Kadriorg,1223,Z\ntram,4,68604,68604,Suur-Paala,1649,Z\ntram,4,69324,69324,Suur-Paala,2369,Z\ntram,3,69498,69498,Kadriorg,2543,\ntram,4,70044,70044,Suur-Paala,3089,\nstop,1081\nbus,36,67090,67080,Väike-Õismäe,135,Z\nbus,5,67318,67308,Männiku,363,Z\nbus,18,67494,67468,Laagri,539,Z\nbus,57,68050,68040,Raudalu,1095,Z\nbus,18A,68128,68128,Urda,1173,Z\nbus,36,68160,68160,Väike-Õismäe,1205,Z\nbus,5,68254,68244,Männiku,1299,Z\nbus,18,68968,68968,Laagri,2013,Z\nbus,20A,69058,69058,Laagri alevik,2103,Z\nbus,5,69204,69204,Männiku,2249,Z\nbus,36,69300,69300,Väike-Õismäe,2345,Z\nbus,18A,69868,69868,Urda,2913,Z\nbus,5,70146,70146,Männiku,3191,Z\nbus,36,70320,70320,Väike-Õismäe,3365,Z";

    int typeIndex = 0;
    int routeNumIndex = 1;
    int expectedTimeIndex = 2;
    int scheduleTimeIndex = 3;
    int directionIndex = 4;
    int extraDataIndex = 6;

    List<String> lines = data.trim().split("\n");
    bool startedParsingStops = false;
    List<StopData> stops = [];
    StopData? stopData;

    for (int i = 0; i < lines.length; i++) {
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
          stops.add(stopData);
          stopData = null;
        }
        stopData = new StopData(
          name: 'Unknown',
          id: line[1],
          distance: 0,
          isFavorite: false,
          departures: [],
        );

        continue;
      }

      if (!startedParsingStops) {
        continue;
      }

      Departure departure = new Departure(
        type: line[typeIndex],
        routeNumber: line[routeNumIndex],
        expectedSeconds: int.parse(line[expectedTimeIndex]),
        scheduleSeconds: int.parse(line[scheduleTimeIndex]),
        direction: line[directionIndex],
        extraData: line[extraDataIndex],
      );

      stopData!.departures.add(departure);
    }

    stops.add(stopData!);

    return Scaffold(
      appBar: appBar(context, style, theme),
      body: ListView(
        children: [
          for (StopData stop in stops)
            Stop(
              id: stop.id,
              name: stop.name,
              distance: stop.distance,
              isFavorite: stop.isFavorite,
              departures: stop.departures,
            ),
        ],
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

class Stop extends StatefulWidget {
  const Stop({
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
  State<Stop> createState() => _StopState();
}

class _StopState extends State<Stop> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var icon = widget.isFavorite
        ? Icon(Icons.star, color: Colors.amber)
        : Icon(Icons.star_border, color: theme.colorScheme.onPrimary);

    return ExpansionTile(
      collapsedBackgroundColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.primary,
      tilePadding: EdgeInsetsDirectional.only(start: 10, end: 10),
      visualDensity: VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity),
      title: Text(
        "${widget.name} - ${widget.distance}m",
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
        ),
      ),
      initiallyExpanded: true,
      leading: AnimatedRotation(
        turns: _isExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      trailing: icon,
      onExpansionChanged: (expanded) {
        setState(() => _isExpanded = expanded);
      },
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
    );
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
  final int scheduleSeconds;
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

    DateTime scheduleTime = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    scheduleTime = scheduleTime.add(Duration(seconds: widget.scheduleSeconds));

    return Container(
      height: 70,
      padding: EdgeInsets.all(5),
      color: theme.colorScheme.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Container(
              padding: EdgeInsets.all(4),
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
                        boxShadow: [BoxShadow()]),
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
                "${dateFormater.format(scheduleTime)} - ${dateFormater.format(expectedTime)}",
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          Spacer(),
          Container(
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  untilExpectedTime.inMinutes.toString(),
                  style: TextStyle(
                    fontSize: 36,
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
