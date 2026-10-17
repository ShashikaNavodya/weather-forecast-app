import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/weather_data.dart';

class WeatherApiException implements Exception {
  const WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<WeatherLocation>> searchLocations(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '8',
      'language': 'en',
      'format': 'json',
    });
    final json = await _getJson(uri);
    final results = json['results'] as List<dynamic>? ?? const [];
    return results.map((item) {
      final result = item as Map<String, dynamic>;
      return WeatherLocation(
        name: result['name'] as String,
        latitude: (result['latitude'] as num).toDouble(),
        longitude: (result['longitude'] as num).toDouble(),
        admin1: result['admin1'] as String?,
        country: result['country'] as String?,
      );
    }).toList();
  }

  Future<WeatherReport> getWeather(WeatherLocation location) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,precipitation_probability,weather_code',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    return WeatherReport.fromJson(location, await _getJson(uri));
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WeatherApiException(
          'Weather service returned an error (${response.statusCode}). Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherApiException(
          'The weather service returned invalid data.',
        );
      }
      if (decoded['error'] == true) {
        throw WeatherApiException(
          decoded['reason'] as String? ??
              'The weather service could not complete your request.',
        );
      }
      return decoded;
    } on WeatherApiException {
      rethrow;
    } on http.ClientException {
      throw const WeatherApiException(
        'Could not connect to the weather service. Check your internet connection.',
      );
    } on TimeoutException {
      throw const WeatherApiException(
        'The request timed out. Please check your connection and try again.',
      );
    } on FormatException {
      throw const WeatherApiException(
        'The weather service returned invalid data.',
      );
    }
  }
}
