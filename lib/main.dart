import 'package:flutter/material.dart';
import 'package:tasku_peatus/pages/home.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tasku_peatus/utils/stops_parser.dart';
import 'models/stop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(StopAdapter());
  await Hive.openBox<Stop>('stopsBox');

  await StopsParser.importStops();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(
        colorScheme: ColorScheme.light(
          primary: Color(0xFFE3E3E3),
          onPrimary: Colors.black,
          secondary: Color(0xFF31A1DA),
          onSecondary: Colors.white,
        ),
      ),
      home: HomePage(),
    );
  }
}
