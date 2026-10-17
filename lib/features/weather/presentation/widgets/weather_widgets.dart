import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/weather_data.dart';

String temperatureText(double celsius, bool useFahrenheit) {
  final value = useFahrenheit ? (celsius * 9 / 5) + 32 : celsius;
  return '${value.round()}°';
}

IconData weatherIcon(int code, {bool isDay = true}) {
  if (code == 0) return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  if (code <= 2) return Icons.wb_cloudy_rounded;
  if (code == 3 || code == 45 || code == 48) return Icons.cloud_rounded;
  if (code >= 71 && code <= 77 || code == 85 || code == 86) return Icons.ac_unit_rounded;
  if (code >= 95) return Icons.flash_on_rounded;
  if (code >= 51) return Icons.grain_rounded;
  return Icons.wb_cloudy_rounded;
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title, style: const TextStyle(color: AppTheme.ink, fontSize: 20, fontWeight: FontWeight.w700)),
    const Spacer(),
    ?trailing,
  ]);
}

class WeatherStatCard extends StatelessWidget {
  const WeatherStatCard({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF373940), Color(0xFF24262C)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF666972)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .16), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 23, color: AppTheme.blueLight),
      const Spacer(),
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
      const SizedBox(height: 5),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.ink, fontSize: 20, fontWeight: FontWeight.w700)),
    ]),
  );
}

class HourForecastCard extends StatelessWidget {
  const HourForecastCard({super.key, required this.forecast, required this.isCurrent, required this.useFahrenheit});
  final HourForecast forecast;
  final bool isCurrent;
  final bool useFahrenheit;
  @override
  Widget build(BuildContext context) {
    final hour = forecast.time.hour;
    final timeLabel = isCurrent ? 'Now' : '${hour % 12 == 0 ? 12 : hour % 12} ${hour < 12 ? 'AM' : 'PM'}';
    return Container(width: 78, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(
      color: isCurrent ? AppTheme.blue : AppTheme.surface,
      borderRadius: BorderRadius.circular(20), border: Border.all(color: isCurrent ? AppTheme.blueLight : AppTheme.border),
    ), child: Column(children: [
      Text(timeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isCurrent ? Colors.white : AppTheme.muted)),
      const SizedBox(height: 14), Icon(weatherIcon(forecast.weatherCode), size: 23, color: AppTheme.blueLight),
      const SizedBox(height: 12), Text(temperatureText(forecast.temperature, useFahrenheit), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isCurrent ? Colors.white : AppTheme.ink)),
      const SizedBox(height: 5), Text('${forecast.precipitationProbability}%', style: TextStyle(fontSize: 11, color: isCurrent ? Colors.white70 : AppTheme.muted)),
    ]));
  }
}

class DayForecastTile extends StatelessWidget {
  const DayForecastTile({super.key, required this.forecast, required this.index, required this.useFahrenheit});
  final DayForecast forecast;
  final int index;
  final bool useFahrenheit;
  @override
  Widget build(BuildContext context) {
    final dayName = index == 0 ? 'Today' : index == 1 ? 'Tomorrow' : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][forecast.date.weekday - 1];
    return Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(children: [
      SizedBox(width: 86, child: Text(dayName, style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600))),
      Icon(weatherIcon(forecast.weatherCode), size: 20, color: AppTheme.blueLight), const SizedBox(width: 12),
      Expanded(child: Text(weatherDescription(forecast.weatherCode), style: const TextStyle(color: AppTheme.muted, fontSize: 13))),
      Text(temperatureText(forecast.high, useFahrenheit), style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700)), const SizedBox(width: 13),
      Text(temperatureText(forecast.low, useFahrenheit), style: const TextStyle(color: AppTheme.muted)),
    ]));
  }
}
