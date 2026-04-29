class TvChannel {
  final String id;
  final String name;
  final String logo;
  final String country;
  final String countryCode;
  final List<String> categories;
  final List<String> languages;
  final String streamUrl;
  final bool isNsfw;

  const TvChannel({
    required this.id,
    required this.name,
    required this.logo,
    required this.country,
    required this.countryCode,
    required this.categories,
    required this.languages,
    required this.streamUrl,
    this.isNsfw = false,
  });

  String get categoryLabel => categories.isEmpty ? '' : categories.first;
  String get languageLabel => languages.isEmpty ? '' : languages.first;

  factory TvChannel.fromJson(
      Map<String, dynamic> ch, String streamUrl) =>
      TvChannel(
        id:          ch['id'] ?? '',
        name:        ch['name'] ?? 'Unknown',
        logo:        ch['logo'] ?? '',
        country:     ch['country'] ?? '',
        countryCode: ch['country'] ?? '',
        categories:  List<String>.from(ch['categories'] ?? []),
        languages:   List<String>.from(ch['languages'] ?? []),
        streamUrl:   streamUrl,
        isNsfw:      ch['is_nsfw'] == true,
      );
}
