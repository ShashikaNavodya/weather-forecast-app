class WeatherLocation {
  const WeatherLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? admin1;
  final String? country;

  String get displayName {
    final parts = [
      name,
      admin1,
      country,
    ].whereType<String>().where((part) => part.isNotEmpty).toSet().toList();
    return parts.join(', ');
  }
}

class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.time,
  });

  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
  final DateTime time;

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      feelsLike: (json['apparent_temperature'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).round(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).round(),
      isDay: (json['is_day'] as num).round() == 1,
      time: DateTime.parse(json['time'] as String),
    );
  }
}

class HourForecast {
  const HourForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;
}

class DayForecast {
  const DayForecast({
    required this.date,
    required this.high,
    required this.low,
    required this.weatherCode,
  });

  final DateTime date;
  final double high;
  final double low;
  final int weatherCode;
}

class WeatherReport {
  const WeatherReport({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.updatedAt,
  });

  final WeatherLocation location;
  final CurrentWeather current;
  final List<HourForecast> hourly;
  final List<DayForecast> daily;
  final DateTime updatedAt;

  factory WeatherReport.fromJson(
    WeatherLocation location,
    Map<String, dynamic> json,
  ) {
    final currentJson = json['current'] as Map<String, dynamic>;
    final hourlyJson = json['hourly'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;
    final hourlyTimes = hourlyJson['time'] as List<dynamic>;
    final hourlyTemperatures = hourlyJson['temperature_2m'] as List<dynamic>;
    final precipitation =
        hourlyJson['precipitation_probability'] as List<dynamic>;
    final hourlyCodes = hourlyJson['weather_code'] as List<dynamic>;
    final dailyTimes = dailyJson['time'] as List<dynamic>;
    final dailyHighs = dailyJson['temperature_2m_max'] as List<dynamic>;
    final dailyLows = dailyJson['temperature_2m_min'] as List<dynamic>;
    final dailyCodes = dailyJson['weather_code'] as List<dynamic>;

    return WeatherReport(
      location: location,
      current: CurrentWeather.fromJson(currentJson),
      hourly: List.generate(hourlyTimes.length, (index) {
        return HourForecast(
          time: DateTime.parse(hourlyTimes[index] as String),
          temperature: (hourlyTemperatures[index] as num).toDouble(),
          precipitationProbability: (precipitation[index] as num).round(),
          weatherCode: (hourlyCodes[index] as num).round(),
        );
      }),
      daily: List.generate(dailyTimes.length, (index) {
        return DayForecast(
          date: DateTime.parse(dailyTimes[index] as String),
          high: (dailyHighs[index] as num).toDouble(),
          low: (dailyLows[index] as num).toDouble(),
          weatherCode: (dailyCodes[index] as num).round(),
        );
      }),
      updatedAt: DateTime.now(),
    );
  }
}

String weatherDescription(int code) {
  if (code == 0) return 'Clear sky';
  if (code == 1) return 'Mostly clear';
  if (code == 2) return 'Partly cloudy';
  if (code == 3) return 'Overcast';
  if (code == 45 || code == 48) return 'Foggy';
  if (code == 51 || code == 53 || code == 55) return 'Drizzle';
  if (code == 56 || code == 57) return 'Freezing drizzle';
  if (code == 61 || code == 63 || code == 65) return 'Rain';
  if (code == 66 || code == 67) return 'Freezing rain';
  if (code == 71 || code == 73 || code == 75 || code == 77) return 'Snow';
  if (code == 80 || code == 81 || code == 82) return 'Rain showers';
  if (code == 85 || code == 86) return 'Snow showers';
  if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
  return 'Weather unavailable';
}
