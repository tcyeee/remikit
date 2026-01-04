import 'package:flutter/material.dart';
import 'pages/home_page.dart';

/// The entry point of the application.
void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Builds the widget tree for the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 137, 138, 220)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Remi 配置面板'),
    );
  }
}
