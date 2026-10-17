import 'package:flutter/material.dart';

import 'features/weather/presentation/weather_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyPulse Weather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const WeatherScreen(),
    );
  }
}
