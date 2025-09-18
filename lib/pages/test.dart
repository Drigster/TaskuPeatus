import 'dart:async';

import 'package:flutter/material.dart';
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
    final data = await RouteParser.parseRoutes();
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
        child: Text("123"),
      ),
    );
  }
}
