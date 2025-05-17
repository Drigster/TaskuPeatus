import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasku_peatus/pages/home.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tasku_peatus/utils/stops_parser.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'models/stop.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();

  await Hive.initFlutter();
  Hive.registerAdapter(StopAdapter());
  await Hive.openBox<Stop>('stopsBox');

  final prefs = await SharedPreferences.getInstance();
  final lastModified = (await StopsParser.getLastModifiedVersion()).toString();
  if (lastModified != prefs.getString("stopsLastModifiedDate") || true) {
    try {
      if ((await StopsParser.importStops())) {
        prefs.setString("stopsLastModifiedDate", lastModified);
      }
    } catch (e) {
      print(e);
    }
  } else {
    print("No need to update stops");
  }

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
