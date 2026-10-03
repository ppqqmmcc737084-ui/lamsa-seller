import 'package:flutter/material.dart';

class ThemeService {
  ThemeService._internal();
  static final ThemeService instance = ThemeService._internal();
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  void toggle(bool isDark) => themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}