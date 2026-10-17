import 'package:flutter_test/flutter_test.dart';
import 'package:weather_forecast_app/features/weather/domain/weather_data.dart';
import 'package:weather_forecast_app/features/weather/presentation/widgets/weather_widgets.dart';

void main() {
  group('Weather presentation helpers', () {
    test('maps common weather codes to readable descriptions', () {
      expect(weatherDescription(0), 'Clear sky');
      expect(weatherDescription(61), 'Rain');
      expect(weatherDescription(95), 'Thunderstorm');
    });

    test('formats Celsius and Fahrenheit temperatures', () {
      final degree = String.fromCharCode(176);
      expect(temperatureText(20, false), '20$degree');
      expect(temperatureText(20, true), '68$degree');
    });
  });
}
