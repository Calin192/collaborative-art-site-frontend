
import 'package:flutter/material.dart';
import 'login.dart';


void main() {
  runApp(const MyApp());
}
String default_url = "http://localhost:8080";
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthScreen(),
    );
  }
}

