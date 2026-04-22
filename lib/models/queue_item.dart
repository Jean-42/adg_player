enum MediaType {
  youtube,
  vimeo,
  dailymotion,
  facebook,
  instagram,
  direct,
  local,
  radio,
}

class QueueItem {
  final String id;
  final MediaType type;
  final String url;
  final String embedUrl;
  final String title;
  final String subtitle;
  final bool isPortraitVideo; // true for Reels, Shorts, Instagram

  const QueueItem({
    required this.id,
    required this.type,
    required this.url,
    required this.embedUrl,
    required this.title,
    required this.subtitle,
    this.isPortraitVideo = false,
  });

  bool get isEmbed =>
      type == MediaType.youtube ||
      type == MediaType.vimeo ||
      type == MediaType.dailymotion ||
      type == MediaType.facebook ||
      type == MediaType.instagram;

  bool get isNative => !isEmbed;

  String get platformLabel {
    switch (type) {
      case MediaType.youtube:     return 'YouTube';
      case MediaType.vimeo:       return 'Vimeo';
      case MediaType.dailymotion: return 'Dailymotion';
      case MediaType.facebook:    return 'Facebook';
      case MediaType.instagram:   return 'Instagram';
      case MediaType.direct:      return 'Direct URL';
      case MediaType.local:       return 'Local File';
      case MediaType.radio:       return 'Radio';
    }
  }

  @override
  bool operator ==(Object other) => other is QueueItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
