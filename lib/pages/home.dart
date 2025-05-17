import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:tasku_peatus/components/app_bar_widget.dart';
import 'package:tasku_peatus/components/stop_widget.dart';
import 'package:tasku_peatus/models/stop.dart';
import 'package:tasku_peatus/services/stop_repository.dart';
import 'package:tasku_peatus/utils/arivals_parser.dart';

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
  String? _state;
  List<StopData> _stops = [];
  Timer? _timer;

  @override
  void initState() {
    _state = 'Init state';
    super.initState();
    _state = 'Init stopsBox';
    stopsBox = Hive.box<Stop>('stopsBox');
    _state = '_fetchStops';
    _initState();
  }

  Future<void> _initState() async {
    await _getCurrentLocation();
    listenToLocationUpdates();
    setState(() => _isLoading = true);
    setState(() => _errorMessage = null);
    await _fetchStops();
  }

  Future<void> _updateStops() async {
    final stops = await ArrivalsParser.getArrivals(
      _stops.map((e) => e.stop).toList(),
      _currentPosition?.latitude,
      _currentPosition?.longitude,
    );
    setState(() => _stops = stops);
  }

  Future<void> _updateStopsTimer() async {
    _timer?.cancel();
    if (_stops.isEmpty) return;
    await _updateStops();
    int duration = 300;

    for (var stop in _stops) {
      for (var departure in stop.departures) {
        DateTime expectedTime = DateTime.now().copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
        expectedTime =
            expectedTime.add(Duration(seconds: departure.expectedSeconds));
        Duration untilExpectedTime = expectedTime.difference(DateTime.now());

        if (untilExpectedTime.inSeconds < 30) {
          duration = min(5, duration);
        } else if (untilExpectedTime.inSeconds < 60) {
          duration = min(15, duration);
        } else if (untilExpectedTime.inSeconds < 180) {
          duration = min(30, duration);
        } else if (untilExpectedTime.inSeconds < 300) {
          duration = min(60, duration);
        }
      }
    }

    print("Update duration: $duration");

    setState(() {
      _timer = Timer(Duration(seconds: duration), () {
        _updateStopsTimer();
      });
    });
  }

  Future<void> _fetchStops({
    double radius = 100,
    bool findClosest = false,
  }) async {
    _state = 'Fetching stops | Gps';
    setState(() => _state = 'Fetching stops | Arrivals');

    try {
      final lat = _currentPosition!.latitude;
      final lon = _currentPosition!.longitude;
      final stops = await StopRepository(stopsBox).getArrivalsInRadius(
        centerLat: lat,
        centerLon: lon,
        radiusMeters: radius,
      );
      if (stops.isNotEmpty) {
        setState(() => _state = 'Fetching stops | Returning early, stops');
        setState(() => _stops = stops);
        return;
      }
      if (findClosest) {
        setState(() => _state = 'Fetching stops | Arrivals closest');
        var stopsNew = await StopRepository(stopsBox).getArrivalsClosest(
          centerLat: lat,
          centerLon: lon,
          startingRadius: radius + 50,
        );
        if (stopsNew.isEmpty) {
          setState(
              () => _state = 'Fetching stops | Returning err, no arrivals');
          setState(() => _errorMessage = 'Stop found, but no arrivals');
        } else {
          setState(() => _state = 'Fetching stops | Returning newStops');
          setState(() => _stops = stopsNew);
        }
        return;
      }
      setState(() => _state = 'Fetching stops | Returning stops');
      setState(() => _stops = stops);
    } catch (e, stack) {
      print(e);
      print(stack);
      sleep(Duration(milliseconds: 300));
      setState(() => _errorMessage = 'Failed to load stops: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
      print(_stops);
      _updateStopsTimer();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_currentPosition != null) {
      return;
    }
    try {
      setState(() => _state = 'Getting gps');
      // Check if location services are enabled
      setState(() => _state = 'isLocationServiceEnabled');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _state = 'Location services are disabled');
        setState(() => _errorMessage = 'Location services are disabled');
        return;
      }

      // Check permission status
      setState(() => _state = 'checkPermission');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() => _state = 'Location permissions are denied');
          setState(() => _errorMessage = 'Location permissions are denied');
          return;
        }
      }

      // Get position
      setState(() => _state = 'getCurrentPosition');
      final position = await Geolocator.getLastKnownPosition();

      setState(() => _state = 'setState');
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _errorMessage = 'Error getting location: $e');
    }
  }

  void listenToLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium, // Adjust accuracy as needed
        distanceFilter: 10, // Minimum distance change to trigger an update
      ),
    ).listen((Position position) {
      setState(() => _currentPosition = position);
      print(
          "https://www.openstreetmap.org/search?query=${_currentPosition?.latitude}+${_currentPosition?.longitude}&zoom=18");
      _fetchStops();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
    );

    return Scaffold(
      bottomSheet: Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, end: 10),
        child: Text(_state.toString()),
      ),
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
          child: AppBarWidget(
            style: style,
            theme: theme,
            onTap: _fetchStops,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
        ),
        child: Center(
          child: _buildBodyContent(context, _stops),
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, List<StopData> stops) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return CircularProgressIndicator(
        color: theme.colorScheme.onSecondary,
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.onSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => {_fetchStops()},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text(
              'Retry',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      );
    }

    if (_stops.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No stops found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => {_fetchStops()},
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                  onPressed: () => {_fetchStops(findClosest: true)},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: Text(
                    'Find closest',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ))
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: ListView.separated(
        padding: const EdgeInsets.all(4),
        itemCount: _stops.length,
        itemBuilder: (context, index) => StopWidget(
          id: stops[index].stop.id,
          name: stops[index].stop.name,
          distance: stops[index].distance,
          isFavorite: stops[index].isFavorite,
          departures: stops[index].departures,
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 4),
      ),
    );
  }
}
