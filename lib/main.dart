
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/paint/presentation/pages/drawing_page.dart';
import 'package:flutter_drawing_board/paint/presentation/theme/app_theme.dart';


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

