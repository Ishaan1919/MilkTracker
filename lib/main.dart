import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MilkTrackerApp());
}

class MilkTrackerApp extends StatelessWidget {
  const MilkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milk Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}