import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/weather_config.dart';

class PlacesApiException implements Exception {
  final String message;
  PlacesApiException(this.message);

  @override
  String toString() => 'PlacesApiException: $message';
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String primaryText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.primaryText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class PlacesService {
  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    double? latitude,
    double? longitude,
  }) async {
    final query = input.trim();
    if (query.isEmpty) return [];
    if (WeatherConfig.placesApiKey.isEmpty) {
      throw PlacesApiException('Missing GOOGLE_PLACES_API_KEY.');
    }

    final params = <String, String>{
      'input': query,
      'key': WeatherConfig.placesApiKey,
    };
    if (latitude != null && longitude != null) {
      params['location'] = '$latitude,$longitude';
      params['radius'] = '50000';
    }

    final uri = Uri.parse('${WeatherConfig.placesBaseUrl}/autocomplete/json')
        .replace(queryParameters: params);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PlacesApiException(
        'Request failed: ${response.statusCode}.',
      );
    }

    final data = _decode(response.body);
    final status = data['status'];
    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') {
      final msg =
          data['error_message'] ?? 'Places autocomplete failed ($status).';
      throw PlacesApiException(msg);
    }

    final predictions = data['predictions'];
    if (predictions is! List) return [];
    return predictions
        .whereType<Map<String, dynamic>>()
        .map(_parseSuggestion)
        .whereType<PlaceSuggestion>()
        .toList();
  }

  Future<PlaceDetails> fetchDetails(String placeId) async {
    if (WeatherConfig.placesApiKey.isEmpty) {
      throw PlacesApiException('Missing GOOGLE_PLACES_API_KEY.');
    }
    final uri = Uri.parse('${WeatherConfig.placesBaseUrl}/details/json')
        .replace(queryParameters: {
      'place_id': placeId,
      'fields': 'name,geometry,formatted_address',
      'key': WeatherConfig.placesApiKey,
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw PlacesApiException(
        'Request failed: ${response.statusCode}.',
      );
    }

    final data = _decode(response.body);
    final status = data['status'];
    if (status != 'OK') {
      final msg = data['error_message'] ?? 'Place details failed ($status).';
      throw PlacesApiException(msg);
    }

    final result = data['result'];
    if (result is! Map<String, dynamic>) {
      throw PlacesApiException('Unexpected place details format.');
    }
    final geometry = result['geometry'];
    final location = geometry is Map ? geometry['location'] : null;
    final lat = _readDouble(location, 'lat');
    final lon = _readDouble(location, 'lng');
    if (lat == null || lon == null) {
      throw PlacesApiException('Missing place coordinates.');
    }

    return PlaceDetails(
      placeId: placeId,
      name: _readString(result, 'name') ??
          _readString(result, 'formatted_address') ??
          'Location',
      address: _readString(result, 'formatted_address'),
      latitude: lat,
      longitude: lon,
    );
  }

  PlaceSuggestion? _parseSuggestion(Map<String, dynamic> data) {
    final placeId = _readString(data, 'place_id');
    final description = _readString(data, 'description') ?? '';
    if (placeId == null || description.isEmpty) return null;

    final formatting = data['structured_formatting'];
    final main = formatting is Map<String, dynamic>
        ? _readString(formatting, 'main_text') ?? description
        : description;
    final secondary = formatting is Map<String, dynamic>
        ? _readString(formatting, 'secondary_text') ?? ''
        : '';

    return PlaceSuggestion(
      placeId: placeId,
      description: description,
      primaryText: main,
      secondaryText: secondary,
    );
  }

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw PlacesApiException('Unexpected response format.');
  }

  String? _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  double? _readDouble(dynamic data, String key) {
    if (data is! Map) return null;
    final value = data[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
