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
import 'package:tasku_peatus/utils/route_parser.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with TickerProviderStateMixin {
  var _data;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    final data = explodeTimes(
        "+331,+18,+17,+16,+16,+15,+15,+13,+14,+14,+14,+16,+18,+20,+20,+16,+17,+19,+20,+23,+24,+24,+24,+15,+19,+19,+22,+20,+20,+18,+18,+16,+16,+15,+14,+15,+15,+15,+16,+16,+18,+18,+20,+20,+23,+24,+25,+25,+25,+25,+25,+22,+26,+26,+26,+28,+28,-01067,+27,+26,+25,+24,+24,+20,+20,+22,+22,+23,+23,+20,+20,+22,+22,+22,+20,+20,+20,+22,+24,+24,+24,+22,+18,+18,+18,+20,+22,+20,+22,+22,+22,+22,+28,+28,+29,+28,+26,+28,+27,+27,+27,+27,+26,+26,-01069,+27,+26,+25,+24,+24,+20,+20,+22,+22,+23,+23,+20,+20,+22,+22,+22,+20,+20,+20,+22,+24,+24,+24,+22,+18,+18,+18,+20,+22,+20,+22,+22,+22,+22,+28,+28,+29,+28,+26,+28,+27,+27,+27,+27,+26,+26,,20332,57,20240,,0,,12345,57,6,47,7,,1,,1,,1,7,6,38,4,,2,7,6,12,4,13,6,18,4,24,6,19,4,28,6,19,4,,1,4,6,3,4,12,6,13,4,38,6,4,4,43,6,4,4,,2,4,4,3,6,12,4,13,6,17,4,1,6,7,4,2,6,42,4,5,6,42,4,,1,4,6,49,4,11,6,6,4,23,6,7,4,1,6,3,4,7,6,6,4,23,6,7,4,1,6,,1,,1,45,4,4,6,,1,4,6,41,6,4,4,4,4,4,6,44,4,3,6,44,4,,2,74,6,19,4,28,6,19,4,,1,3,6,1,4,15,6,26,4,8,6,4,4,6,6,1,4,6,6,4,4,36,6,1,4,6,6,4,4,,1,19,4,13,6,12,4,1,6,25,4,4,6,43,4,4,6,,2,3,4,1,6,28,4,12,6,1,4,4,6,1,4,9,6,4,4,1,6,6,6,4,4,26,4,1,6,3,4,2,6,4,4,1,6,6,6,4,4,26,4,1,6,,1,3,6,1,4,28,6,12,4,1,6,4,4,1,6,3,4,10,6,1,4,36,6,1,4,9,6,1,4,36,6,1,4,,2,6,6,46,4,1,6,10,4,6,6,29,4,3,6,2,4,1,6,6,4,6,6,29,4,3,6,2,4,,2,4,6,28,4,3,6,10,4,4,6,4,4,10,6,7,4,4,6,18,4,1,6,7,4,10,6,7,4,4,6,18,4,1,6,7,4,,2,6,6,25,4,1,6,17,4,8,4,2,6,14,6,1,4,26,6,1,4,3,4,2,6,14,6,1,4,26,6,1,4,,3,3,6,1,4,1,7,1,4,25,6,1,4,2,6,1,4,17,4,1,6,3,4,2,7,1,4,11,6,3,4,19,6,1,4,7,4,2,4,1,6,2,7,1,4,11,6,3,4,19,6,1,4,7,4,2,4,1,6,,2,35,6,8,4,27,4,3,6,19,4,1,6,24,4,3,6,19,4,1,6,,1,4,6,13,4,13,6,1,4,3,6,1,4,8,6,5,4,1,6,1,4,20,6,23,4,8,6,2,4,14,6,23,4,8,6,2,4,,2,3,4,3,6,11,4,2,6,13,6,2,4,10,4,1,6,4,4,1,6,8,4,1,6,11,4,2,6,1,4,1,6,18,4,1,6,7,4,4,6,1,4,1,6,11,4,2,6,1,4,1,6,18,4,1,6,7,4,,1,3,6,1,4,1,6,1,4,11,6,2,4,11,6,4,4,1,6,8,4,1,6,1,4,25,6,2,4,20,6,1,4,24,6,2,4,20,6,1,4,,1,2,6,15,4,2,6,11,4,1,6,1,4,2,6,9,4,26,6,1,4,2,6,2,4,26,6,1,4,15,6,1,4,2,6,2,4,26,6,1,4,,1,33,6,1,4,23,4,1,6,10,6,1,4,35,4,1,6,10,6,1,4,,1,6,6,13,4,11,6,1,4,3,6,1,4,8,6,5,4,1,6,1,4,7,6,2,4,3,6,1,4,1,6,4,4,2,6,2,4,2,6,17,4,2,6,4,4,7,6,2,4,3,6,1,4,1,6,4,4,2,6,2,4,2,6,17,4,2,6,4,4,,1,4,6,2,4,25,6,3,4,1,6,8,4,5,6,1,4,1,6,1,4,12,6,1,4,9,6,1,4,36,6,1,4,9,6,1,4,,1,,");
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge!.copyWith(
      color: theme.colorScheme.onSecondary,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
      ),
      child: Center(
        child: ListView.separated(
          padding: const EdgeInsets.all(4),
          itemCount: (_data as TimetableData).times.length,
          itemBuilder: (context, index) => Text(
            (_data as TimetableData).times[index].toString(),
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 4),
        ),
      ),
    );
  }
}
