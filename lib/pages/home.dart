import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:tasku_peatus/utils/arivals_parser.dart';
import '../models/stop.dart';
import '../services/stop_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Box<Stop> stopsBox;
  Position? _currentPosition;

  bool _isLoading = true;
  String? _errorMessage;
  List<StopData> _stops = [];

  @override
  void initState() {
    super.initState();
    stopsBox = Hive.box<Stop>('stopsBox');
    _fetchStops();
  }

  Future<void> _fetchStops({
    double radius = 100,
    bool findClosest = false,
  }) async {
    await _getCurrentLocation();

    try {
      setState(() => _isLoading = true);
      final lat = _currentPosition?.latitude ?? 59.433025;
      final lon = _currentPosition?.longitude ?? 24.745296;
      final stops = await StopRepository(stopsBox).getArrivalsInRadius(
        centerLat: lat,
        centerLon: lon,
        radiusMeters: radius,
      );
      if (stops.isEmpty) {
        if (findClosest) {
          var stopsNew = await StopRepository(stopsBox).getArrivalsClosest(
            centerLat: lat,
            centerLon: lon,
            startingRadius: radius,
          );
          print(stopsNew);
          if (stopsNew == null) {
            setState(() => _errorMessage = 'No stops available');
          } else if (stops.isEmpty) {
            setState(() => _errorMessage = 'Stop found, but no arrivals');
          } else {
            setState(() => _stops = stops);
          }
        } else {
          setState(() => _errorMessage = 'No stops available');
        }
      } else {
        setState(() => _stops = stops);
      }
    } catch (e, stack) {
      print(e);
      print(stack);
      sleep(Duration(milliseconds: 300));
      setState(() => _errorMessage = 'Failed to load stops: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Location services are disabled');
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() => _errorMessage = 'Location permissions are denied');
          return;
        }
      }

      // Get position
      final position = await Geolocator.getCurrentPosition();

      setState(() => _currentPosition = position);
      print("${_currentPosition?.latitude} ${_currentPosition?.longitude}");
    } catch (e) {
      setState(() => _errorMessage = 'Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
    );

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
          child: _buildBodyContent(context, _stops),
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
          onTap: () => _fetchStops(),
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

  Widget _buildBodyContent(BuildContext context, List<StopData> stops) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => {_fetchStops()},
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () => {_fetchStops(findClosest: true)},
                      child: Text(
                        'Find closest',
                        style: TextStyle(color: Colors.blue),
                      ))
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_stops.isEmpty) {
      return Center(
        child: Text(
          'No stops found',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSecondary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: ListView.separated(
        padding: const EdgeInsets.all(4),
        itemCount: _stops.length,
        itemBuilder: (context, index) => StopWidget(
          id: stops[index].id,
          name: stops[index].name,
          distance: stops[index].distance,
          isFavorite: stops[index].isFavorite,
          departures: stops[index].departures,
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 4),
      ),
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
    Duration untilExpectedTime = expectedTime.difference(DateTime.now());

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
