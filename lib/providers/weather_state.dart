import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/weather_config.dart';
import '../services/api_key_store.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/weather_models.dart';
import '../services/weather_service.dart';

class WeatherState extends ChangeNotifier with WidgetsBindingObserver {
  WeatherState({
    WeatherService? service,
    LocationService? locationService,
  })  : _service = service ?? WeatherService(),
        _locationService = locationService ?? LocationService() {
    WidgetsBinding.instance.addObserver(this);
    _watchConnectivity();
    _startReachabilityTimer();
    _deviceLocation = _fallbackLocation().copyWith(
      subtitle: 'My Location',
      isDevice: true,
    );
    _savedLocations = List<WeatherLocation>.from(_cityCatalog);
    _rebuildLocations();
    _snapshots = _locations
        .map((loc) => WeatherSnapshot.fallbackFor(loc))
        .toList();
    _errors = List<String?>.filled(_locations.length, null);
    _bootstrap();
  }

  final WeatherService _service;
  final LocationService _locationService;
  final Connectivity _connectivity = Connectivity();

  static const _savedLocationsKey = 'savedLocations';
  static const _snapshotCacheKey = 'weatherSnapshotCache';
  static const Duration _cacheMaxAge = Duration(hours: 24);
  static const Duration _offlineRetryInterval = Duration(minutes: 1);
  static const Duration _reachabilityInterval = Duration(seconds: 10);
  static const Duration _reachabilityTimeout = Duration(seconds: 4);
  static final Uri _reachabilityUri =
      Uri.parse('https://clients3.google.com/generate_204');
  SharedPreferences? _prefs;
  WeatherLocation? _deviceLocation;
  List<WeatherLocation> _savedLocations = [];
  bool _hasLocalChanges = false;
  List<WeatherLocation> _locations = [];
  List<WeatherSnapshot?> _snapshots = [];
  Map<String, WeatherSnapshot> _cachedSnapshots = {};
  List<String?> _errors = [];
  int _activeIndex = 0;
  bool _loading = false;
  String? _error;
  bool _isOffline = false;
  Timer? _offlineRetryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _pendingRefresh = false;
  Timer? _reachabilityTimer;
  bool _checkingInternet = false;
  List<ConnectivityResult> _lastConnectivity = const [];
  bool _inForeground = true;

  WeatherSnapshot get snapshot => activeSnapshot;
  WeatherSnapshot get activeSnapshot => snapshotForIndex(_activeIndex);
  List<WeatherLocation> get locations => List.unmodifiable(_locations);
  int get activeIndex => _activeIndex;
  bool get loading => _loading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  String? errorForIndex(int index) {
    if (_errors.isEmpty) return null;
    final safeIndex = index.clamp(0, _errors.length - 1);
    return _errors[safeIndex];
  }

  WeatherSnapshot snapshotForIndex(int index) {
    if (_locations.isEmpty) return WeatherSnapshot.fallback();
    final safeIndex = index.clamp(0, _locations.length - 1);
    final snap = _snapshots.length > safeIndex ? _snapshots[safeIndex] : null;
    return snap ?? WeatherSnapshot.fallbackFor(_locations[safeIndex]);
  }

  Future<void> refresh() => _refresh();

  void setActiveIndex(int index) {
    if (_locations.isEmpty) return;
    final safeIndex = index.clamp(0, _locations.length - 1);
    if (_activeIndex == safeIndex) return;
    _activeIndex = safeIndex;
    _ensureSnapshot(_activeIndex);
    notifyListeners();
  }

  Future<int> addLocation(WeatherLocation location) async {
    final existing = _findSavedIndex(location);
    if (existing != -1) {
      final index = existing + 1;
      setActiveIndex(index);
      return index;
    }
    _savedLocations.add(location.copyWith(isDevice: false));
    _hasLocalChanges = true;
    try {
      await _persistSavedLocations();
    } catch (_) {
      // Keep the location added even if persistence fails.
    }
    _rebuildLocations();
    while (_snapshots.length < _locations.length) {
      _snapshots.add(null);
    }
    while (_errors.length < _locations.length) {
      _errors.add(null);
    }
    final index = _savedLocations.length;
    final cached = _cachedSnapshotFor(_locations[index]);
    if (cached != null && _snapshots.length > index) {
      _snapshots[index] = cached;
    }
    _activeIndex = index;
    notifyListeners();
    () async {
      final result = await _fetchSnapshotAt(index, _locations[index]);
      _updateOfflineState([result]);
      notifyListeners();
      NotificationService.instance.updateSnapshots(
        _snapshots,
        promptPermissions: false,
      );
    }();
    return index;
  }

  Future<void> removeLocation(int index) async {
    if (index <= 0) return;
    final savedIndex = index - 1;
    if (savedIndex < 0 || savedIndex >= _savedLocations.length) return;
    final removed = _savedLocations.removeAt(savedIndex);
    _hasLocalChanges = true;
    await _persistSavedLocations();
    await _removeCachedSnapshot(removed);
    _rebuildLocations();
    _snapshots = List<WeatherSnapshot?>.generate(
      _locations.length,
      (i) => _cachedSnapshotFor(_locations[i]),
    );
    _errors = List<String?>.filled(_locations.length, null);
    if (_locations.isEmpty) {
      _activeIndex = 0;
    } else if (_activeIndex >= _locations.length) {
      _activeIndex = _locations.length - 1;
    }
    notifyListeners();
    await _refresh();
  }

  Future<void> moveLocation(int oldIndex, int newIndex) async {
    if (oldIndex <= 0 || newIndex <= 0) return;
    final oldSaved = oldIndex - 1;
    final newSaved = newIndex - 1;
    if (oldSaved < 0 || oldSaved >= _savedLocations.length) return;
    if (newSaved < 0 || newSaved >= _savedLocations.length) return;
    if (oldSaved == newSaved) return;

    final item = _savedLocations.removeAt(oldSaved);
    _savedLocations.insert(newSaved, item);
    _hasLocalChanges = true;
    await _persistSavedLocations();
    _rebuildLocations();
    _moveInList(_snapshots, oldIndex, newIndex);
    _moveInList(_errors, oldIndex, newIndex);

    if (_activeIndex == oldIndex) {
      _activeIndex = newIndex;
    } else if (_activeIndex > oldIndex && _activeIndex <= newIndex) {
      _activeIndex -= 1;
    } else if (_activeIndex < oldIndex && _activeIndex >= newIndex) {
      _activeIndex += 1;
    }
    notifyListeners();
  }

  void updateActivePage(int pageIndex) {
    if (pageIndex <= 0) return;
    setActiveIndex(pageIndex - 1);
  }

  Future<void> selectLocationByName(String name) async {
    final idx = _locations.indexWhere((loc) => loc.name == name);
    if (idx == -1) return;
    setActiveIndex(idx);
  }

  Future<void> _refresh() async {
    await _ensureApiKeys();
    if (_loading) {
      _pendingRefresh = true;
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final wasOffline = _isOffline;
    _seedCacheFromSnapshots();
    final devicePosition = await _locationService.getCurrentPosition();
    _deviceLocation = _buildCurrentLocation(devicePosition);
    _rebuildLocations();
    _snapshots = List<WeatherSnapshot?>.generate(
      _locations.length,
      (i) => _cachedSnapshotFor(_locations[i]),
    );
    _errors = List<String?>.filled(_locations.length, null);
    if (_activeIndex >= _locations.length) _activeIndex = 0;

    final futures = <Future<_FetchResult>>[];
    for (int i = 0; i < _locations.length; i++) {
      futures.add(_fetchSnapshotAt(i, _locations[i]));
    }

    List<_FetchResult> results = const [];
    try {
      results = await Future.wait(futures);
    } catch (_) {
      // Errors are captured per-location.
    }

    _updateOfflineState(results, manageRetry: true);
    _loading = false;
    notifyListeners();
    NotificationService.instance.updateSnapshots(
      _snapshots,
      promptPermissions: false,
    );
    final shouldRefreshAgain = _pendingRefresh;
    _pendingRefresh = false;
    if (shouldRefreshAgain) {
      Future.microtask(_refresh);
    }
    if (!shouldRefreshAgain && wasOffline && !_isOffline) {
      final needsRefresh = results.any((result) => !result.success);
      if (needsRefresh) {
        Future.microtask(() {
          if (_loading) return;
          _refresh();
        });
      }
    }
  }

  Future<_FetchResult> _fetchSnapshotAt(
    int index,
    WeatherLocation location,
  ) async {
    try {
      final snap = await _service.fetchWeather(location);
      _snapshots[index] = snap;
      if (_errors.length > index) {
        _errors[index] = null;
      }
      _cachedSnapshots[location.cacheKey()] = snap;
      await _persistSnapshotCache();
      if (index == _activeIndex) {
        _error = null;
      }
      return const _FetchResult.success();
    } catch (e) {
      final cached = _cachedSnapshotFor(location);
      if (cached != null) {
        _snapshots[index] = cached;
        if (_errors.length > index) {
          _errors[index] = null;
        }
        if (index == _activeIndex) {
          _error = null;
        }
        return const _FetchResult.cache();
      }
      _snapshots[index] ??= WeatherSnapshot.fallbackFor(location);
      if (_errors.length > index) {
        _errors[index] = e.toString();
      }
      if (index == _activeIndex) {
        _error = e.toString();
      }
      return const _FetchResult.failure();
    }
  }

  Future<void> _ensureSnapshot(int index) async {
    if (_snapshots.length <= index) return;
    if (_snapshots[index] != null) return;
    await _ensureApiKeys();
    final cached = _cachedSnapshotFor(_locations[index]);
    if (cached != null) {
      _snapshots[index] = cached;
      notifyListeners();
      return;
    }
    final result = await _fetchSnapshotAt(index, _locations[index]);
    _updateOfflineState([result]);
    notifyListeners();
  }

  WeatherLocation _buildCurrentLocation(Position? position) {
    if (position == null) {
      return _fallbackLocation().copyWith(
        subtitle: 'My Location',
        isDevice: true,
      );
    }

    final lat = position.latitude;
    final lon = position.longitude;
    final resolvedName = _resolveNearestCityName(lat, lon);

    return WeatherLocation(
      name: resolvedName,
      subtitle: 'My Location',
      latitude: lat,
      longitude: lon,
      isDevice: true,
    );
  }

  WeatherLocation _fallbackLocation() => _cityCatalog.first;

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSnapshotCache();
    final saved = _loadSavedLocations();
    if (saved.isNotEmpty) {
      _savedLocations = _hasLocalChanges
          ? _dedupeLocations([..._savedLocations, ...saved])
          : saved;
    }
    _rebuildLocations();
    _snapshots = List<WeatherSnapshot?>.generate(
      _locations.length,
      (i) => _cachedSnapshotFor(_locations[i]),
    );
    _errors = List<String?>.filled(_locations.length, null);
    await _refresh();
  }

  Future<void> _ensureApiKeys() async {
    if (WeatherConfig.apiKey.isNotEmpty) return;
    try {
      await ApiKeyStore.instance.load();
    } catch (_) {
      // Key fetch is best-effort; fallback stays in place.
    }
  }

  void _rebuildLocations() {
    final device = _deviceLocation;
    _locations = device == null ? List.of(_savedLocations) : [device, ..._savedLocations];
  }

  List<WeatherLocation> _loadSavedLocations() {
    final raw = _prefs?.getString(_savedLocationsKey);
    if (raw == null || raw.isEmpty) return List.of(_cityCatalog);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return List.of(_cityCatalog);
      final parsed = <WeatherLocation>[];
      for (final item in decoded.whereType<Map<String, dynamic>>()) {
        try {
          final loc = WeatherLocation.fromJson(item);
          parsed.add(_sanitizeSubtitle(loc).copyWith(isDevice: false));
        } catch (_) {
          // Skip invalid entries.
        }
      }
      return parsed.isEmpty ? List.of(_cityCatalog) : _dedupeLocations(parsed);
    } catch (_) {
      return List.of(_cityCatalog);
    }
  }

  WeatherLocation _sanitizeSubtitle(WeatherLocation location) {
    final subtitle = location.subtitle.trim();
    if (subtitle.isEmpty) return location;
    final timeLike = RegExp(r'^\\d{1,2}:\\d{2}$').hasMatch(subtitle);
    if (!timeLike) return location;
    return location.copyWith(subtitle: '');
  }

  Future<void> _persistSavedLocations() async {
    _prefs ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _savedLocations.map((loc) => loc.toJson()).toList(),
    );
    await _prefs?.setString(_savedLocationsKey, payload);
  }

  Future<void> _loadSnapshotCache() async {
    final raw = _prefs?.getString(_snapshotCacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final now = DateTime.now();
      final cache = <String, WeatherSnapshot>{};
      decoded.forEach((key, value) {
        if (key is! String || value is! Map<String, dynamic>) return;
        try {
          final snap = WeatherSnapshot.fromJson(value);
          if (now.difference(snap.updatedAt) <= _cacheMaxAge) {
            cache[key] = snap;
          }
        } catch (_) {
          // Skip invalid entries.
        }
      });
      _cachedSnapshots = cache;
    } catch (_) {
      // Ignore cache failures.
    }
  }

  Future<void> _persistSnapshotCache() async {
    _prefs ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    final pruned = <String, WeatherSnapshot>{};
    _cachedSnapshots.forEach((key, snap) {
      if (now.difference(snap.updatedAt) <= _cacheMaxAge) {
        pruned[key] = snap;
      }
    });
    _cachedSnapshots = pruned;
    final payload = jsonEncode(
      _cachedSnapshots.map((key, snap) => MapEntry(key, snap.toJson())),
    );
    await _prefs?.setString(_snapshotCacheKey, payload);
  }

  WeatherSnapshot? _cachedSnapshotFor(WeatherLocation location) {
    final key = location.cacheKey();
    final snap = _cachedSnapshots[key];
    if (snap == null) return null;
    if (!_isSnapshotFresh(snap)) {
      _cachedSnapshots.remove(key);
      return null;
    }
    return snap;
  }

  bool _isSnapshotFresh(WeatherSnapshot snap) {
    return DateTime.now().difference(snap.updatedAt) <= _cacheMaxAge;
  }

  void _seedCacheFromSnapshots() {
    for (final snap in _snapshots) {
      if (snap == null || snap.isFallback) continue;
      if (!_isSnapshotFresh(snap)) continue;
      _cachedSnapshots[snap.location.cacheKey()] = snap;
    }
  }

  void _updateOfflineState(
    List<_FetchResult> results, {
    bool manageRetry = true,
  }) {
    if (results.isEmpty) return;
    if (_isOffline) {
      if (manageRetry) {
        _startOfflineRetry();
      }
    } else {
      _stopOfflineRetry();
    }
  }

  Future<void> _removeCachedSnapshot(WeatherLocation location) async {
    final key = location.cacheKey();
    if (_cachedSnapshots.remove(key) != null) {
      await _persistSnapshotCache();
    }
  }

  void _startOfflineRetry() {
    _offlineRetryTimer ??=
        Timer.periodic(_offlineRetryInterval, (_) {
      if (!_isOffline || _loading) return;
      _refresh();
    });
  }

  void _stopOfflineRetry() {
    _offlineRetryTimer?.cancel();
    _offlineRetryTimer = null;
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    try {
      _connectivitySub = _connectivity.onConnectivityChanged.listen(
        _handleConnectivity,
        onError: (_) {},
      );
      _connectivity
          .checkConnectivity()
          .then(_handleConnectivity)
          .catchError((_) {});
    } on MissingPluginException {
      // Plugin not registered (hot restart). Offline will rely on fetches.
    }
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    _lastConnectivity = results;
    final hasConnection =
        results.any((result) => result != ConnectivityResult.none);
    if (!hasConnection) {
      if (!_isOffline) {
        _isOffline = true;
        notifyListeners();
      }
      _startOfflineRetry();
      return;
    }
    if (_isOffline) {
      _isOffline = false;
      notifyListeners();
      _stopOfflineRetry();
      _refresh();
    } else {
      _stopOfflineRetry();
    }
  }

  void _startReachabilityTimer() {
    _reachabilityTimer ??=
        Timer.periodic(_reachabilityInterval, (_) {
      if (!_inForeground) return;
      final hasConnection = _lastConnectivity.isEmpty
          ? true
          : _lastConnectivity.any(
              (result) => result != ConnectivityResult.none,
            );
      if (!hasConnection) return;
      _checkInternetAndUpdate();
    });
  }

  Future<void> _checkInternetAndUpdate() async {
    if (_checkingInternet) return;
    _checkingInternet = true;
    final ok = await _hasInternet();
    _checkingInternet = false;
    final wasOffline = _isOffline;
    if (!ok) {
      return;
    }
    if (wasOffline) {
      _isOffline = false;
      notifyListeners();
    }
    _stopOfflineRetry();
    if (wasOffline) {
      _refresh();
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final client = HttpClient()..connectionTimeout = _reachabilityTimeout;
      final request = await client.getUrl(_reachabilityUri);
      request.followRedirects = false;
      final response =
          await request.close().timeout(_reachabilityTimeout);
      await response.drain();
      client.close(force: true);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (_inForeground) {
      _checkInternetAndUpdate();
      _refresh();
    }
  }

  @override
  void dispose() {
    _offlineRetryTimer?.cancel();
    _connectivitySub?.cancel();
    _reachabilityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<WeatherLocation> _dedupeLocations(List<WeatherLocation> items) {
    final seenPlaceIds = <String>{};
    final unique = <WeatherLocation>[];
    for (final loc in items) {
      final placeId = loc.placeId;
      if (placeId != null && seenPlaceIds.contains(placeId)) continue;
      if (placeId != null) seenPlaceIds.add(placeId);
      if (_containsLatLon(unique, loc)) continue;
      unique.add(loc);
    }
    return unique;
  }

  bool _containsLatLon(List<WeatherLocation> items, WeatherLocation location) {
    const threshold = 0.01;
    for (final loc in items) {
      if ((loc.latitude - location.latitude).abs() < threshold &&
          (loc.longitude - location.longitude).abs() < threshold) {
        return true;
      }
    }
    return false;
  }

  int _findSavedIndex(WeatherLocation location) {
    if (location.placeId != null) {
      final byId = _savedLocations
          .indexWhere((loc) => loc.placeId == location.placeId);
      if (byId != -1) return byId;
    }
    for (int i = 0; i < _savedLocations.length; i++) {
      final loc = _savedLocations[i];
      if ((loc.latitude - location.latitude).abs() < 0.01 &&
          (loc.longitude - location.longitude).abs() < 0.01) {
        return i;
      }
    }
    return -1;
  }

  void _moveInList<T>(List<T> list, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
  }

  String _resolveNearestCityName(double lat, double lon) {
    const maxDistanceKm = 60.0;
    WeatherLocation? closest;
    double closestDistance = double.infinity;

    for (final city in _cityCatalog) {
      final distance = _distanceKm(
        lat,
        lon,
        city.latitude,
        city.longitude,
      );
      if (distance < closestDistance) {
        closest = city;
        closestDistance = distance;
      }
    }

    if (closest != null && closestDistance <= maxDistanceKm) {
      return closest.name;
    }
    return 'Current Location';
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180.0;
}

class _FetchResult {
  final bool success;

  const _FetchResult.success()
      : success = true;
  const _FetchResult.cache()
      : success = false;
  const _FetchResult.failure()
      : success = false;
}

const List<WeatherLocation> _cityCatalog = [
  WeatherLocation(
    name: 'Istanbul',
    subtitle: 'Turkey',
    latitude: 41.0082,
    longitude: 28.9784,
  ),
  WeatherLocation(
    name: 'Ankara',
    subtitle: 'Turkey',
    latitude: 39.9334,
    longitude: 32.8597,
  ),
  WeatherLocation(
    name: 'Marmaris',
    subtitle: 'Turkey',
    latitude: 36.855,
    longitude: 28.274,
  ),
  WeatherLocation(
    name: 'Turkbuku',
    subtitle: 'Turkey',
    latitude: 37.136,
    longitude: 27.439,
  ),
  WeatherLocation(
    name: 'Midilli',
    subtitle: 'Greece',
    latitude: 39.104,
    longitude: 26.557,
  ),
];
