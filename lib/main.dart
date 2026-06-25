import 'package:flutter/material.dart';
import 'views/game_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rummikub Clássico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
      ),
      home: const GameScreen(),
    );
  }
}
