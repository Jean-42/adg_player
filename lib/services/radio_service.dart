import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';

class RadioService {
  static const _hosts = [
    'de1.api.radio-browser.info',
    'nl1.api.radio-browser.info',
    'at1.api.radio-browser.info',
  ];

  static String _host = _hosts[0];

  static Future<List<RadioStation>> fetchTop({int limit = 40}) async {
    for (final host in _hosts) {
      try {
        final uri = Uri.https(host, '/json/stations/topclick/$limit', {
          'hidebroken': 'true',
        });
        final res = await http.get(uri, headers: _headers()).timeout(
            const Duration(seconds: 10));
        if (res.statusCode == 200) {
          _host = host;
          return _parse(res.body);
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<List<RadioStation>> search(String query,
      {int limit = 40}) async {
    if (query.trim().isEmpty) return fetchTop(limit: limit);
    for (final host in [_host, ..._hosts]) {
      try {
        final uri = Uri.https(host, '/json/stations/search', {
          'name': query.trim(),
          'limit': '$limit',
          'hidebroken': 'true',
          'order': 'clickcount',
          'reverse': 'true',
        });
        final res = await http.get(uri, headers: _headers()).timeout(
            const Duration(seconds: 10));
        if (res.statusCode == 200) {
          _host = host;
          return _parse(res.body);
        }
      } catch (_) {}
    }
    return [];
  }

  static Map<String, String> _headers() => {
        'User-Agent': 'ADGMediaPlayer/1.0 (android)',
        'Accept': 'application/json',
      };

  static List<RadioStation> _parse(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return list
        .map((e) => RadioStation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
