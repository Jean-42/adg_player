class RadioStation {
  final String stationuuid;
  final String name;
  final String url;
  final String urlResolved;
  final String country;
  final String tags;
  final int bitrate;
  final String favicon;

  const RadioStation({
    required this.stationuuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    required this.country,
    required this.tags,
    required this.bitrate,
    required this.favicon,
  });

  factory RadioStation.fromJson(Map<String, dynamic> j) => RadioStation(
        stationuuid: j['stationuuid'] ?? '',
        name:        j['name'] ?? 'Unknown',
        url:         j['url'] ?? '',
        urlResolved: j['url_resolved'] ?? j['url'] ?? '',
        country:     j['country'] ?? '',
        tags:        j['tags'] ?? '',
        bitrate:     (j['bitrate'] ?? 0) is int
            ? j['bitrate']
            : int.tryParse(j['bitrate'].toString()) ?? 0,
        favicon:     j['favicon'] ?? '',
      );

  String get streamUrl => urlResolved.isNotEmpty ? urlResolved : url;

  String get firstTag {
    if (tags.isEmpty) return '';
    return tags.split(',').first.trim();
  }
}
