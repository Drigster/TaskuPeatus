import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tasku_peatus/components/arrival_widget.dart';
import 'package:tasku_peatus/models/stop.dart';
import 'package:tasku_peatus/utils/arivals_parser.dart';
import 'package:tasku_peatus/utils/utils.dart';

class StopWidget extends StatefulWidget {
  const StopWidget({
    super.key,
    required this.siriId,
    required this.name,
    required this.distance,
    required this.isFavorite,
    required this.departures,
    required this.transports,
  });

  final String siriId;
  final String name;
  final int distance;
  final bool isFavorite;
  final List<Departure> departures;
  final Map<String, Set<String>> transports;

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
            onPressed: () => _toggleFavorite(widget.siriId, false),
          )
        : IconButton(
            icon: Icon(Icons.star_border, color: theme.colorScheme.onPrimary),
            onPressed: () => _toggleFavorite(widget.siriId, true),
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
                      Row(spacing: 4, children: [
                        Text(
                          "${widget.name} - ${widget.distance}m",
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 20,
                          ),
                        ),
                        for (var transport in widget.transports.keys)
                          Icon(
                            Utils.getTransportIconAndColor(transport).$1,
                            color: theme.colorScheme.onPrimary,
                          ),
                      ])
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            height: _isExpanded ? null : 0,
            child: Column(
              spacing: 4,
              children: [
                for (Departure departure in widget.departures)
                  ArrivalWidget(
                    type: departure.type,
                    routeNumber: departure.routeNumber,
                    expectedSeconds: departure.expectedSeconds,
                    scheduleSeconds: departure.scheduleSeconds,
                    direction: departure.direction,
                    extraData: departure.extraData,
                  ),
                if (widget.departures.isEmpty)
                  Container(
                    height: 70,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Center(
                      child: Text(
                        'This stop has no arrivals',
                        style: TextStyle(
                            color: theme.colorScheme.onPrimary, fontSize: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFavorite(String siriId, bool isFavorite) {
    final stop = stopsBox.values.firstWhere((s) => s.siriId == siriId);

    stop.isFavorite = isFavorite;
    stop.save();

    setState(() {});
  }
}
