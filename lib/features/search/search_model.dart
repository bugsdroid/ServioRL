enum MediaType { movie, tv, unknown }

class SearchResult {
  final int id;
  final String title;
  final String posterPath;
  final String backdropPath;
  final int year;
  final MediaType mediaType;
  final double voteAverage;
  final String overview;
  final bool alreadyRequested;
  final bool mediaAvailable;

  const SearchResult({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.backdropPath,
    required this.year,
    required this.mediaType,
    required this.voteAverage,
    required this.overview,
    required this.alreadyRequested,
    required this.mediaAvailable,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) {
    final type = (j['mediaType'] as String? ?? '') == 'movie'
        ? MediaType.movie
        : (j['mediaType'] as String? ?? '') == 'tv'
            ? MediaType.tv
            : MediaType.unknown;

    final title = (j['title'] as String?)
        ?? (j['name'] as String?)
        ?? 'Unknown';

    final dateStr = (j['releaseDate'] as String?)
        ?? (j['firstAirDate'] as String?)
        ?? '';
    final year = dateStr.length >= 4
        ? int.tryParse(dateStr.substring(0, 4)) ?? 0
        : 0;

    final media = j['mediaInfo'] as Map<String, dynamic>?;
    final status = media?['status'] as int? ?? 0;

    return SearchResult(
      id:               j['id'] as int? ?? 0,
      title:            title,
      posterPath:       j['posterPath']   as String? ?? '',
      backdropPath:     j['backdropPath'] as String? ?? '',
      year:             year,
      mediaType:        type,
      voteAverage:      (j['voteAverage'] as num?)?.toDouble() ?? 0,
      overview:         j['overview']     as String? ?? '',
      alreadyRequested: status == 2 || status == 3,
      mediaAvailable:   status == 5,
    );
  }

  String get mediaTypeStr =>
      mediaType == MediaType.movie ? 'movie' : 'tv';

  String posterUrl([String size = 'w342']) =>
      posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/$size$posterPath'
          : '';

  String backdropUrl([String size = 'w780']) =>
      backdropPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/$size$backdropPath'
          : '';
}
