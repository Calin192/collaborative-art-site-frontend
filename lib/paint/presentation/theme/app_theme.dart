import 'package:flutter/material.dart';


import 'app_colors.dart';

const Color kCanvasColor = Color(0xfff2f3f7);

ThemeData lightTheme = ThemeData(
  useMaterial3: false,
  primaryColor: lightPrimary,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: lightAccent,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: lightBG,
  appBarTheme: AppBarTheme(
    backgroundColor: lightPrimary.withValues(alpha: 0.7),
    elevation: 0.0,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: lightPrimary.withValues(alpha: 0.7),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: InputBorder.none,
    focusedBorder: InputBorder.none,
  ),
);