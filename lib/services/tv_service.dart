import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tv_channel.dart';

class TvService {
  static const _base = 'https://iptv-org.github.io/api';
  static const _timeout = Duration(seconds: 20);

  // Cached data — loaded once per session
  static List<TvChannel>? _channels;
  static List<Map<String, dynamic>>? _countries;
  static List<Map<String, dynamic>>? _categories;
  static bool _loading = false;

  // ── Load all data ──────────────────────────────────────────────────
  static Future<void> _ensureLoaded() async {
    if (_channels != null) return;
    if (_loading) {
      // Wait for in-progress load
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    _loading = true;
    try {
      // Fetch channels and streams in parallel
      final results = await Future.wait([
        _get('$_base/channels.json'),
        _get('$_base/streams.json'),
      ]);

      final channelList = jsonDecode(results[0]) as List<dynamic>;
      final streamList  = jsonDecode(results[1]) as List<dynamic>;

      // Build a map: channel_id → best stream url
      final streamMap = <String, String>{};
      for (final s in streamList) {
        final cid = s['channel'] as String? ?? '';
        if (cid.isEmpty) continue;
        // Prefer http/https streams; skip ones already added
        if (!streamMap.containsKey(cid)) {
          final url = s['url'] as String? ?? '';
          if (url.startsWith('http')) streamMap[cid] = url;
        }
      }

      // Merge — only keep channels that have a stream
      final channels = <TvChannel>[];
      for (final ch in channelList) {
        final id  = ch['id'] as String? ?? '';
        final url = streamMap[id] ?? '';
        if (url.isEmpty) continue;
        if (ch['is_nsfw'] == true) continue; // skip NSFW
        channels.add(TvChannel.fromJson(ch as Map<String, dynamic>, url));
      }

      _channels = channels;
    } finally {
      _loading = false;
    }
  }

  static Future<String> _get(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return res.body;
  }

  // ── Public API ─────────────────────────────────────────────────────

  /// Load and return all channels. Throws on network error.
  static Future<List<TvChannel>> fetchAll() async {
    await _ensureLoaded();
    return _channels ?? [];
  }

  /// Get sorted unique country codes present in channel list.
  static Future<List<String>> fetchCountryCodes() async {
    await _ensureLoaded();
    final codes = (_channels ?? [])
        .map((c) => c.countryCode)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return codes;
  }

  /// Get sorted unique categories present in channel list.
  static Future<List<String>> fetchCategories() async {
    await _ensureLoaded();
    final cats = (_channels ?? [])
        .expand((c) => c.categories)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  /// Filter + search channels.
  static Future<List<TvChannel>> query({
    String search = '',
    String countryCode = '',
    String category = '',
    int limit = 80,
  }) async {
    await _ensureLoaded();
    var list = _channels ?? [];

    if (countryCode.isNotEmpty) {
      list = list.where((c) => c.countryCode == countryCode).toList();
    }
    if (category.isNotEmpty) {
      list = list.where((c) => c.categories.contains(category)).toList();
    }
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.countryCode.toLowerCase().contains(q) ||
          c.categories.any((cat) => cat.toLowerCase().contains(q))).toList();
    }

    return list.take(limit).toList();
  }

  /// Clear cache (for retry after error).
  static void clearCache() {
    _channels = null;
    _countries = null;
    _categories = null;
  }
}
