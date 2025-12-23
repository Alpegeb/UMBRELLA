import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'weather_models.dart';
import 'weather_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _alertsChannelId = 'umbrella_alerts';
  static const _alertsChannelName = 'Umbrella Alerts';
  static const _alertsChannelDescription =
      'Weather alerts and reminders for your locations.';
  static const _savedLocationsKey = 'savedLocations';
  static const _snapshotCacheKey = 'weatherSnapshotCache';
  static const Duration _cacheMaxAge = Duration(hours: 24);
  static const Duration _guardDelay = Duration(seconds: 10);
  static const Duration _minScheduleDelay = Duration(seconds: 20);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  List<WeatherSnapshot> _lastSnapshots = const [];

  Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    try {
      await _plugin.initialize(initSettings);
      await _configureTimeZone();
      await _createChannels();
      _initialized = true;
    } on MissingPluginException {
      // Plugin not registered (e.g., after a hot restart). Try again later.
    } catch (_) {
      // Keep notifications optional to avoid crashing the app.
    }
  }

  Future<void> requestPermissions() async {
    await initialize();
    if (!_initialized) return;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> updateSnapshots(
    List<WeatherSnapshot?> snapshots, {
    bool promptPermissions = true,
  }) async {
    _lastSnapshots = snapshots.whereType<WeatherSnapshot>().toList();
    await _syncSchedules(promptPermissions: promptPermissions);
  }

  Future<void> rescheduleFromCache({bool promptPermissions = true}) async {
    await _syncSchedules(promptPermissions: promptPermissions);
  }

  Future<void> refreshFromBackground() async {
    await initialize();
    if (!_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedSnapshots = _loadSnapshotCache(prefs);
    final locations = <WeatherLocation>[
      ..._loadSavedLocations(prefs),
      ...cachedSnapshots.values.map((snap) => snap.location),
    ];
    final deduped = _dedupeLocations(locations);
    if (deduped.isEmpty) return;

    final service = WeatherService();
    final updatedSnapshots = <WeatherSnapshot>[];
    for (final location in deduped) {
      try {
        final snap = await service.fetchWeather(location);
        updatedSnapshots.add(snap);
        cachedSnapshots[location.cacheKey()] = snap;
      } catch (_) {
        // Skip failed refreshes.
      }
    }
    await _persistSnapshotCache(prefs, cachedSnapshots);
    _lastSnapshots = updatedSnapshots.isEmpty
        ? cachedSnapshots.values.toList()
        : updatedSnapshots;
    await _syncSchedules(promptPermissions: false);
  }

  Future<void> _syncSchedules({bool promptPermissions = true}) async {
    await initialize();
    if (!_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final notifyRain = prefs.getBool('notifyRain') ?? true;
    final notifySunrise = prefs.getBool('notifySunrise') ?? true;
    final notifySunset = prefs.getBool('notifySunset') ?? true;
    final notifyUv = prefs.getBool('notifyUv') ?? true;
    final notifyAirQuality = prefs.getBool('notifyAirQuality') ?? true;
    final notifyVisibility = prefs.getBool('notifyVisibility') ?? true;
    final notifyLocationKey = prefs.getString('notifyLocationKey');

    await _plugin.cancelAllPendingNotifications();
    final scopedSnapshots = notifyLocationKey == null || notifyLocationKey.isEmpty
        ? _lastSnapshots
        : _lastSnapshots
            .where((snap) => snap.location.cacheKey() == notifyLocationKey)
            .toList();
    final effectiveSnapshots =
        scopedSnapshots.isEmpty ? _lastSnapshots : scopedSnapshots;
    if (effectiveSnapshots.isEmpty ||
        (!notifyRain &&
            !notifySunrise &&
            !notifySunset &&
            !notifyUv &&
            !notifyAirQuality &&
            !notifyVisibility)) {
      return;
    }

    if (promptPermissions) {
      await requestPermissions();
    }
    final now = DateTime.now();
    final events = <_AlertEvent>[];

    for (final snapshot in effectiveSnapshots) {
      if (snapshot.isFallback) continue;
      if (notifyRain) {
        final rainEvent = _nextRainEvent(snapshot, now);
        if (rainEvent != null) {
          events.add(rainEvent);
        }
      }
      if (notifySunrise) {
        final sunriseEvent = _nextSunriseEvent(snapshot, now);
        if (sunriseEvent != null) {
          events.add(sunriseEvent);
        }
      }
      if (notifySunset) {
        final sunsetEvent = _nextSunsetEvent(snapshot, now);
        if (sunsetEvent != null) {
          events.add(sunsetEvent);
        }
      }
      if (notifyUv) {
        final uvEvent = _nextUvEvent(snapshot, now);
        if (uvEvent != null) {
          events.add(uvEvent);
        }
      }
      if (notifyVisibility) {
        final visibilityEvent = _nextVisibilityEvent(snapshot, now);
        if (visibilityEvent != null) {
          events.add(visibilityEvent);
        }
      }
      if (notifyAirQuality) {
        final aqiEvent = _airQualityEvent(snapshot, now);
        if (aqiEvent != null) {
          events.add(aqiEvent);
        }
      }
    }

    if (events.isEmpty) return;
    events.sort((a, b) => a.fireTime.compareTo(b.fireTime));
    int nextId = 2000;
    final nowTz = tz.TZDateTime.now(tz.local);
    final guardTime = nowTz.add(_guardDelay);
    for (final event in events) {
      if (event.fireTime.isBefore(now)) continue;
      final scheduled = tz.TZDateTime.from(event.fireTime, tz.local);
      if (!scheduled.isAfter(guardTime)) continue;
      await _plugin.zonedSchedule(
        nextId++,
        event.title,
        event.message,
        scheduled,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _configureTimeZone() async {
    tz_data.initializeTimeZones();
    final zoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zoneInfo.identifier));
  }

  Future<void> _createChannels() async {
    const channel = AndroidNotificationChannel(
      _alertsChannelId,
      _alertsChannelName,
      description: _alertsChannelDescription,
      importance: Importance.high,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _alertsChannelId,
      _alertsChannelName,
      channelDescription: _alertsChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  _AlertEvent? _nextRainEvent(WeatherSnapshot snapshot, DateTime now) {
    const threshold = 0.4;
    final upcoming = snapshot.hourly
        .where((h) => !h.time.isBefore(now))
        .where((h) => h.precipProbability >= threshold)
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.time.compareTo(b.time));

    final next = upcoming.first;
    final location = _locationLabel(snapshot);
    return _leadEvent(
      targetTime: next.time,
      now: now,
      maxLead: const Duration(hours: 6),
      title: 'Umbrella reminder',
      messageBuilder: (label) =>
          'Rain may be possible in $location in $label — take an umbrella.',
    );
  }

  String _formatLead(Duration lead) {
    if (lead.inMinutes < 60) {
      final minutes = math.max(1, lead.inMinutes);
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
    final hours = math.max(1, lead.inHours);
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  _AlertEvent? _nextUvEvent(WeatherSnapshot snapshot, DateTime now) {
    const threshold = 6;
    final upcoming = snapshot.hourly
        .where((h) => !h.time.isBefore(now))
        .where((h) => (h.uvIndex ?? 0) >= threshold)
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.time.compareTo(b.time));
    final next = upcoming.first;
    final location = _locationLabel(snapshot);
    return _leadEvent(
      targetTime: next.time,
      now: now,
      maxLead: const Duration(hours: 2),
      title: 'UV alert',
      messageBuilder: (label) =>
          'High UV may be possible in $location in $label. Wear sunscreen.',
    );
  }

  _AlertEvent? _nextVisibilityEvent(WeatherSnapshot snapshot, DateTime now) {
    const thresholdKm = 5.0;
    final upcoming = snapshot.hourly
        .where((h) => !h.time.isBefore(now))
        .where((h) => h.visibilityKm != null && h.visibilityKm! <= thresholdKm)
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.time.compareTo(b.time));
    final next = upcoming.first;
    final location = _locationLabel(snapshot);
    return _leadEvent(
      targetTime: next.time,
      now: now,
      maxLead: const Duration(hours: 2),
      title: 'Visibility alert',
      messageBuilder: (label) =>
          'Low visibility possible in $location in $label. Drive carefully.',
    );
  }

  _AlertEvent? _nextSunriseEvent(WeatherSnapshot snapshot, DateTime now) {
    final times = snapshot.daily
        .map((d) => d.sunriseTime)
        .whereType<DateTime>()
        .where((t) => !t.isBefore(now))
        .toList()
      ..sort();
    if (times.isEmpty) return null;
    final location = _locationLabel(snapshot);
    return _AlertEvent(
      fireTime: times.first,
      title: 'Sunrise',
      message: 'Sunrise now in $location.',
    );
  }

  _AlertEvent? _nextSunsetEvent(WeatherSnapshot snapshot, DateTime now) {
    final times = snapshot.daily
        .map((d) => d.sunsetTime)
        .whereType<DateTime>()
        .where((t) => !t.isBefore(now))
        .toList()
      ..sort();
    if (times.isEmpty) return null;
    final location = _locationLabel(snapshot);
    return _AlertEvent(
      fireTime: times.first,
      title: 'Sunset',
      message: 'Sunset now in $location.',
    );
  }

  _AlertEvent? _airQualityEvent(WeatherSnapshot snapshot, DateTime now) {
    final aqi = snapshot.airQuality?.aqi;
    if (aqi == null || aqi < 100) return null;
    final category = snapshot.airQuality?.category ?? 'Poor air quality';
    final location = _locationLabel(snapshot);
    return _AlertEvent(
      fireTime: now.add(const Duration(minutes: 5)),
      title: 'Air quality alert',
      message: '$category in $location. Limit outdoor activity.',
    );
  }

  _AlertEvent? _leadEvent({
    required DateTime targetTime,
    required DateTime now,
    required Duration maxLead,
    required String title,
    required String Function(String label) messageBuilder,
  }) {
    final until = targetTime.difference(now);
    if (until.inMinutes <= 0) return null;
    final lead = until <= maxLead ? until : maxLead;
    var fireTime = targetTime.subtract(lead);
    final soonest = now.add(_minScheduleDelay);
    if (fireTime.isBefore(soonest)) {
      fireTime = soonest;
    }
    if (fireTime.isBefore(now)) return null;
    final label = _formatLead(lead);
    return _AlertEvent(
      fireTime: fireTime,
      title: title,
      message: messageBuilder(label),
    );
  }

  String _locationLabel(WeatherSnapshot snapshot) {
    return snapshot.location.name.isEmpty ? 'your area' : snapshot.location.name;
  }

  List<WeatherLocation> _loadSavedLocations(SharedPreferences prefs) {
    final raw = prefs.getString(_savedLocationsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) {
            try {
              return WeatherLocation.fromJson(item).copyWith(isDevice: false);
            } catch (_) {
              return null;
            }
          })
          .whereType<WeatherLocation>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, WeatherSnapshot> _loadSnapshotCache(SharedPreferences prefs) {
    final raw = prefs.getString(_snapshotCacheKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
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
      return cache;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistSnapshotCache(
    SharedPreferences prefs,
    Map<String, WeatherSnapshot> cache,
  ) async {
    final now = DateTime.now();
    final pruned = <String, WeatherSnapshot>{};
    cache.forEach((key, snap) {
      if (now.difference(snap.updatedAt) <= _cacheMaxAge) {
        pruned[key] = snap;
      }
    });
    final payload = jsonEncode(
      pruned.map((key, snap) => MapEntry(key, snap.toJson())),
    );
    await prefs.setString(_snapshotCacheKey, payload);
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
}

class _AlertEvent {
  const _AlertEvent({
    required this.fireTime,
    required this.title,
    required this.message,
  });

  final DateTime fireTime;
  final String title;
  final String message;
}
