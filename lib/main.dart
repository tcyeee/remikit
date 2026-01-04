import 'package:flutter/material.dart';
import 'pages/home_page.dart';

/// The entry point of the application.
void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  /// Builds the widget tree for the application.
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remikit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const MyHomePage(title: 'Remikit Home Page'),
    );
  }
}
