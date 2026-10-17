import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/weather_api_service.dart';
import '../domain/weather_data.dart';
import 'widgets/weather_widgets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, this.apiService});

  final WeatherApiService? apiService;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final WeatherApiService _api;
  final _searchController = TextEditingController();
  WeatherReport? _report;
  WeatherLocation _location = const WeatherLocation(
    name: 'Colombo',
    latitude: 6.9271,
    longitude: 79.8612,
    admin1: 'Western Province',
    country: 'Sri Lanka',
  );
  Timer? _refreshTimer;
  String? _error;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearching = false;
  bool _useFahrenheit = false;
  int _weatherRequestId = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? WeatherApiService();
    _loadWeather();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _loadWeather(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather({bool silent = false}) async {
    if (!mounted) return;
    final requestId = ++_weatherRequestId;
    setState(() {
      if (_report == null) _isLoading = true;
      _isRefreshing = _report != null;
      if (!silent) _error = null;
    });
    try {
      final report = await _api.getWeather(_location);
      if (!mounted || requestId != _weatherRequestId) return;
      setState(() {
        _report = report;
        _isLoading = false;
        _isRefreshing = false;
        _error = null;
      });
    } on WeatherApiException catch (error) {
      if (!mounted || requestId != _weatherRequestId) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = _report == null ? error.message : null;
      });
      if (_report != null) _showMessage(error.message);
    }
  }

  Future<void> _searchCity() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isSearching) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);
    try {
      final locations = await _api.searchLocations(query);
      if (!mounted) return;
      if (locations.isEmpty) {
        _showMessage('No cities found. Try another name.');
        return;
      }
      final selected = await showModalBottomSheet<WeatherLocation>(
        context: context,
        showDragHandle: true,
        backgroundColor: AppTheme.surface,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Choose a location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              ...locations.map(
                (location) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.surfaceRaised,
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.blueLight,
                    ),
                  ),
                  title: Text(location.name),
                  subtitle: Text(location.displayName),
                  onTap: () => Navigator.of(context).pop(location),
                ),
              ),
            ],
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          _location = selected;
          _report = null;
          _error = null;
        });
        await _loadWeather();
      }
    } on WeatherApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _isLoading && _report == null
                ? const _LoadingView()
                : _error != null && _report == null
                ? _ErrorView(message: _error!, onRetry: _loadWeather)
                : _buildDashboard(),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final report = _report!;
    final current = report.current;
    final unitLabel = _useFahrenheit ? 'F' : 'C';
    final windSpeed = _useFahrenheit
        ? '${(current.windSpeed * 0.621371).round()} mph'
        : '${current.windSpeed.round()} km/h';
    final hourly = report.hourly
        .where((forecast) => !forecast.time.isBefore(current.time))
        .take(12)
        .toList();
    return RefreshIndicator(
      color: AppTheme.blueLight,
      backgroundColor: AppTheme.surfaceRaised,
      onRefresh: () => _loadWeather(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _buildTopBar(),
          const SizedBox(height: 24),
          _buildSearch(),
          const SizedBox(height: 22),
          _buildCurrentCard(report, unitLabel),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Today’s highlights'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 620 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: constraints.maxWidth > 620 ? 1.5 : 1.12,
                children: [
                  WeatherStatCard(
                    icon: Icons.thermostat_rounded,
                    label: 'Feels like',
                    value: temperatureText(current.feelsLike, _useFahrenheit),
                  ),
                  WeatherStatCard(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '${current.humidity}%',
                  ),
                  WeatherStatCard(
                    icon: Icons.air_rounded,
                    label: 'Wind speed',
                    value: windSpeed,
                  ),
                  WeatherStatCard(
                    icon: Icons.cloud_outlined,
                    label: 'Conditions',
                    value: weatherDescription(current.weatherCode),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          SectionHeading(
            title: 'Hourly forecast',
            trailing: Text(
              'Next 12 hours',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              separatorBuilder: (context, index) => const SizedBox(width: 9),
              itemBuilder: (context, index) => HourForecastCard(
                forecast: hourly[index],
                isCurrent: index == 0,
                useFahrenheit: _useFahrenheit,
              ),
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeading(title: '7-day forecast'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                for (var index = 0; index < report.daily.length; index++) ...[
                  DayForecastTile(
                    forecast: report.daily[index],
                    index: index,
                    useFahrenheit: _useFahrenheit,
                  ),
                  if (index < report.daily.length - 1)
                    const Divider(height: 1, color: AppTheme.border),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'WEATHER DATA BY OPEN-METEO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final updated = _report!.updatedAt;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(
            Icons.cloud_sync_rounded,
            color: AppTheme.blueLight,
          ),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SkyPulse',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'WEATHER',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _unitButton('°C', selected: !_useFahrenheit, isFahrenheit: false),
              _unitButton('°F', selected: _useFahrenheit, isFahrenheit: true),
            ],
          ),
        ),
        const SizedBox(width: 5),
        IconButton(
          tooltip: 'Refresh weather',
          onPressed: _isRefreshing ? null : () => _loadWeather(),
          icon: _isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        if (DateTime.now().difference(updated).inMinutes > 0)
          Text(
            '${DateTime.now().difference(updated).inMinutes}m',
            style: const TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
      ],
    );
  }

  Widget _unitButton(
    String label, {
    required bool selected,
    required bool isFahrenheit,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (_useFahrenheit != isFahrenheit) {
          setState(() => _useFahrenheit = isFahrenheit);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surfaceRaised : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.ink : AppTheme.muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchCity(),
      decoration: InputDecoration(
        hintText: 'Search for a city…',
        hintStyle: const TextStyle(color: AppTheme.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted),
        suffixIcon: IconButton(
          tooltip: 'Search city',
          onPressed: _isSearching ? null : _searchCity,
          icon: _isSearching
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_rounded),
        ),
        filled: true,
        fillColor: const Color(0xFF292B30),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppTheme.blueLight, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCurrentCard(WeatherReport report, String unitLabel) {
    final current = report.current;
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatFullDate(current.time);
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 28, 24, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF294D70), Color(0xFF142D78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2856A8).withValues(alpha: 0.2),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.blueLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.location.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 27),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${temperatureText(current.temperature, _useFahrenheit)}$unitLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        height: 1,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      weatherDescription(current.weatherCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Current weather',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(
                weatherIcon(current.weatherCode, isDay: current.isDay),
                size: 92,
                color: AppTheme.blueLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Getting your local forecast...',
            style: TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppTheme.muted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Weather unavailable',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
