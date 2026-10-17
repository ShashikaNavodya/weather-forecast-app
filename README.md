# Auspify Weather

A lightweight Flutter weather dashboard with live conditions, city search, hourly outlook, and a 7-day forecast.

## Run locally

1. Install Flutter (Dart 3.12 or later).
2. From the project directory, run `flutter pub get`.
3. Run `flutter run`.

The app uses the free Open-Meteo geocoding and forecast APIs; no API key or backend service is required. It opens on Bengaluru, India, refreshes automatically every 30 minutes, and can also be refreshed manually or with pull-to-refresh.

## Project structure

- `lib/features/weather/data/` — API requests and response handling.
- `lib/features/weather/domain/` — weather and location models.
- `lib/features/weather/presentation/` — dashboard and reusable weather widgets.
- `lib/theme/` — shared app theme and colors.
- `test/` — focused tests for forecast presentation helpers.
