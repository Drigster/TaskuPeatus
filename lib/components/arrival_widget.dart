import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tasku_peatus/utils/utils.dart';

class ArrivalWidget extends StatefulWidget {
  const ArrivalWidget({
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
  State<ArrivalWidget> createState() => _ArrivalWidgetState();
}

class _ArrivalWidgetState extends State<ArrivalWidget> {
  Timer? offsetTimer;
  Timer? periodicTimer;
  late DateTime expectedTime;
  late Duration untilExpectedTime;

  @override
  void initState() {
    super.initState();
    expectedTime = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    expectedTime = expectedTime.add(Duration(seconds: widget.expectedSeconds));
    untilExpectedTime = expectedTime.difference(DateTime.now());

    // Align to the next second
    final now = DateTime.now();
    final millisecondsUntilNextSecond = 1000 - now.millisecond;
    offsetTimer =
        Timer(Duration(milliseconds: millisecondsUntilNextSecond), () {
      // Start the periodic timer after alignment
      periodicTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        if (mounted) {
          setState(() {
            // Update the remaining time
            untilExpectedTime = expectedTime.difference(DateTime.now());

            // Stop the timer if the countdown is complete
            if (untilExpectedTime.isNegative ||
                untilExpectedTime.inSeconds == 0) {
              periodicTimer?.cancel();
            }
          });
        } else {
          // If widget is not mounted anymore, cancel the timer
          periodicTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    offsetTimer?.cancel();
    periodicTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (typeIcon, typeColor) = Utils.getTransportIconAndColor(widget.type);

    DateFormat dateFormater = DateFormat('HH:mm');
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
                  untilExpectedTime.inSeconds <= 5
                      ? "now"
                      : untilExpectedTime.inSeconds < 60
                          ? untilExpectedTime.inSeconds.toString()
                          : untilExpectedTime.inMinutes.toString(),
                  style: TextStyle(
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                Text(
                  untilExpectedTime.inSeconds < 60 ? "seconds" : "minutes",
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
