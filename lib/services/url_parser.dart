import '../models/queue_item.dart';

class UrlParser {
  // ── YouTube ────────────────────────────────────────────────────────
  static String? extractYouTubeId(String input) {
    input = input.trim();
    final patterns = [
      RegExp(r'(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(input);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static QueueItem? buildYouTube(String input) {
    final id = extractYouTubeId(input.trim());
    if (id == null) return null;
    final isShort = input.contains('/shorts/');
    // MUST use youtube-nocookie.com — regular youtube.com embed gives Error 152/153
    // in WebView because it detects the non-browser environment
    const params = 'autoplay=1&rel=0&modestbranding=1&playsinline=1&iv_load_policy=3';
    return QueueItem(
      id:              'yt_$id',
      type:            MediaType.youtube,
      url:             isShort
          ? 'https://www.youtube.com/shorts/$id'
          : 'https://www.youtube.com/watch?v=$id',
      embedUrl:        'https://www.youtube-nocookie.com/embed/$id?$params',
      title:           isShort ? 'YouTube Short' : 'YouTube Video',
      subtitle:        'YouTube',
      isPortraitVideo: isShort,
    );
  }

  // ── Vimeo ──────────────────────────────────────────────────────────
  static String? extractVimeoId(String input) {
    input = input.trim();
    final m = RegExp(r'vimeo\.com/(\d+)').firstMatch(input);
    if (m != null) return m.group(1);
    if (RegExp(r'^\d+$').hasMatch(input)) return input;
    return null;
  }

  static QueueItem? buildVimeo(String input) {
    final id = extractVimeoId(input);
    if (id == null) return null;
    return QueueItem(
      id:       'vi_$id',
      type:     MediaType.vimeo,
      url:      'https://vimeo.com/$id',
      embedUrl: 'https://player.vimeo.com/video/$id?autoplay=1&byline=0&portrait=0',
      title:    'Vimeo Video',
      subtitle: 'Vimeo',
    );
  }

  // ── Dailymotion ────────────────────────────────────────────────────
  static String? extractDailymotionId(String input) {
    input = input.trim();
    final m = RegExp(r'(?:dailymotion\.com/video/|dai\.ly/)([a-zA-Z0-9]+)').firstMatch(input);
    if (m != null) return m.group(1);
    if (RegExp(r'^[a-zA-Z0-9]{5,12}$').hasMatch(input)) return input;
    return null;
  }

  static QueueItem? buildDailymotion(String input) {
    final id = extractDailymotionId(input);
    if (id == null) return null;
    return QueueItem(
      id:       'dm_$id',
      type:     MediaType.dailymotion,
      url:      'https://www.dailymotion.com/video/$id',
      embedUrl: 'https://geo.dailymotion.com/player.html?video=$id&autoplay=1',
      title:    'Dailymotion Video',
      subtitle: 'Dailymotion',
    );
  }

  // ── Facebook ───────────────────────────────────────────────────────
  static QueueItem? buildFacebook(String input) {
    input = input.trim();
    if (!input.contains('facebook.com') && !input.contains('fb.watch')) return null;
    final isReel = input.toLowerCase().contains('reel');
    final encoded = Uri.encodeComponent(input);
    return QueueItem(
      id:              'fb_${input.hashCode}',
      type:            MediaType.facebook,
      url:             input,
      embedUrl:        'https://www.facebook.com/plugins/video.php?href=$encoded&show_text=false&autoplay=true&allowfullscreen=true',
      title:           isReel ? 'Facebook Reel' : 'Facebook Video',
      subtitle:        'Facebook',
      isPortraitVideo: isReel,
    );
  }

  // ── Instagram ──────────────────────────────────────────────────────
  static QueueItem? buildInstagram(String input) {
    input = input.trim();
    if (!input.contains('instagram.com')) return null;
    final src = input.replaceAll(RegExp(r'/?$'), '') + '/embed/';
    return QueueItem(
      id:              'ig_${input.hashCode}',
      type:            MediaType.instagram,
      url:             input,
      embedUrl:        src,
      title:           'Instagram Video',
      subtitle:        'Instagram',
      isPortraitVideo: true,
    );
  }

  // ── Direct URL ─────────────────────────────────────────────────────
  static QueueItem? buildDirect(String input) {
    input = input.trim();
    if (!input.startsWith('http://') && !input.startsWith('https://')) return null;
    final name = Uri.parse(input).pathSegments.lastWhere(
        (s) => s.isNotEmpty, orElse: () => 'Video');
    return QueueItem(
      id:       'url_${input.hashCode}',
      type:     MediaType.direct,
      url:      input,
      embedUrl: '',
      title:    name,
      subtitle: 'Direct URL',
    );
  }

  // ── Local file ─────────────────────────────────────────────────────
  static QueueItem buildLocal(String path, String name) => QueueItem(
    id:       'local_${path.hashCode}',
    type:     MediaType.local,
    url:      path,
    embedUrl: '',
    title:    name,
    subtitle: 'Local File',
  );

  // ── Auto-detect ────────────────────────────────────────────────────
  static QueueItem? autoDetect(String input) =>
      buildYouTube(input) ??
      buildVimeo(input) ??
      buildDailymotion(input) ??
      buildFacebook(input) ??
      buildInstagram(input) ??
      buildDirect(input);
}
