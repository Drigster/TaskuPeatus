import 'package:flutter/material.dart';
import 'package:tasku_peatus/pages/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(),
      ),
      theme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.light(),
      ),
      home: HomePage(),
    );
  }
}
