enum SubtitleMediaType { movie, episode }

class SubtitleItem {
  final String radarrId;
  final String sonarrEpisodeId;
  final String title;
  final String seriesTitle;
  final int seasonNumber;
  final int episodeNumber;
  final SubtitleMediaType mediaType;
  final String path;
  final String missing;  // language codes yang missing e.g. "en,id"

  const SubtitleItem({
    required this.radarrId,
    required this.sonarrEpisodeId,
    required this.title,
    required this.seriesTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.mediaType,
    required this.path,
    required this.missing,
  });

  factory SubtitleItem.fromMovieJson(Map<String, dynamic> j) {
    final missing = (j['missing_subtitles'] as List<dynamic>?)
            ?.map((s) => (s as Map<String, dynamic>)['name'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        '';

    return SubtitleItem(
      radarrId:       j['radarrId']?.toString() ?? '',
      sonarrEpisodeId: '',
      title:          j['title'] as String? ?? 'Unknown',
      seriesTitle:    '',
      seasonNumber:   0,
      episodeNumber:  0,
      mediaType:      SubtitleMediaType.movie,
      path:           j['path'] as String? ?? '',
      missing:        missing,
    );
  }

  factory SubtitleItem.fromEpisodeJson(Map<String, dynamic> j) {
    final missing = (j['missing_subtitles'] as List<dynamic>?)
            ?.map((s) => (s as Map<String, dynamic>)['name'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        '';

    return SubtitleItem(
      radarrId:       '',
      sonarrEpisodeId: j['sonarrEpisodeId']?.toString() ?? '',
      title:          j['title'] as String? ?? 'Unknown',
      seriesTitle:    j['seriesTitle'] as String? ?? '',
      seasonNumber:   j['season_number'] as int? ?? 0,
      episodeNumber:  j['episode_number'] as int? ?? 0,
      mediaType:      SubtitleMediaType.episode,
      path:           j['path'] as String? ?? '',
      missing:        missing,
    );
  }

  String get displayTitle {
    if (mediaType == SubtitleMediaType.movie) return title;
    final ep = 'S${seasonNumber.toString().padLeft(2, '0')}'
        'E${episodeNumber.toString().padLeft(2, '0')}';
    return '$seriesTitle · $ep · $title';
  }

  bool get isMovie => mediaType == SubtitleMediaType.movie;
}

// ── Subtitle search result ────────────────────────────────────────────────────

class SubtitleResult {
  final String id;
  final String language;
  final String languageName;
  final String provider;
  final double score;
  final String release;
  final String url;
  final bool hearingImpaired;
  final String format;

  const SubtitleResult({
    required this.id,
    required this.language,
    required this.languageName,
    required this.provider,
    required this.score,
    required this.release,
    required this.url,
    required this.hearingImpaired,
    required this.format,
  });

  factory SubtitleResult.fromJson(Map<String, dynamic> j) {
    return SubtitleResult(
      id:              j['id']?.toString() ?? '',
      language:        j['language'] as String? ?? '',
      languageName:    j['languageName'] as String? ?? j['language'] as String? ?? '',
      provider:        j['provider'] as String? ?? '',
      score:           (j['score'] as num?)?.toDouble() ?? 0,
      release:         j['release'] as String? ?? '',
      url:             j['url'] as String? ?? '',
      hearingImpaired: j['hearing_impaired'] as bool? ?? false,
      format:          j['format'] as String? ?? 'srt',
    );
  }

  String get scoreStr => '${(score * 100).toInt()}%';
}
