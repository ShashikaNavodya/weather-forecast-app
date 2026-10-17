import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weather_forecast_app/features/weather/data/weather_api_service.dart';

void main() {
  test('searches locations and parses a forecast response', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'geocoding-api.open-meteo.com') {
        expect(request.url.queryParameters['name'], 'Bengaluru');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'Bengaluru',
                'admin1': 'Karnataka',
                'country': 'India',
                'latitude': 12.97,
                'longitude': 77.59,
              },
            ],
          }),
          200,
        );
      }

      expect(request.url.host, 'api.open-meteo.com');
      expect(request.url.queryParameters['timezone'], 'auto');
      return http.Response(
        jsonEncode({
          'current': {
            'temperature_2m': 27.4,
            'apparent_temperature': 29.1,
            'relative_humidity_2m': 68,
            'wind_speed_10m': 8.2,
            'weather_code': 2,
            'is_day': 1,
            'time': '2026-10-17T12:00',
          },
          'hourly': {
            'time': ['2026-10-17T12:00', '2026-10-17T13:00'],
            'temperature_2m': [27.4, 28.0],
            'precipitation_probability': [10, 20],
            'weather_code': [2, 3],
          },
          'daily': {
            'time': ['2026-10-17', '2026-10-18'],
            'temperature_2m_max': [29.0, 30.0],
            'temperature_2m_min': [21.0, 22.0],
            'weather_code': [2, 3],
          },
        }),
        200,
      );
    });
    final service = WeatherApiService(client: client);

    final locations = await service.searchLocations('Bengaluru');
    final report = await service.getWeather(locations.single);

    expect(report.location.displayName, 'Bengaluru, Karnataka, India');
    expect(report.current.temperature, 27.4);
    expect(report.current.humidity, 68);
    expect(report.hourly, hasLength(2));
    expect(report.hourly.last.precipitationProbability, 20);
    expect(report.daily, hasLength(2));
    expect(report.daily.first.high, 29.0);
  });
}
