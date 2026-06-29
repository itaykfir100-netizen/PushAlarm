import 'package:flutter/material.dart';

const kGreen = Color(0xFF34C759);
const kBackground = Color(0xFF0D0D0D);
const kCard = Color(0xFF1C1C1E);
const kSurface = Color(0xFF2C2C2E);

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBackground,
  colorScheme: const ColorScheme.dark(
    primary: kGreen,
    surface: kCard,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBackground,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: const CardThemeData(
    color: kCard,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.grey,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? kGreen : kSurface,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kCard,
    selectedItemColor: kGreen,
    unselectedItemColor: Colors.grey,
  ),
);
