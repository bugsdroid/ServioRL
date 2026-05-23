/// Status request dari Seerr
enum RequestStatus {
  pending,
  approved,
  available,
  declined,
  unknown;

  static RequestStatus fromInt(int v) => switch (v) {
        1 => pending,
        2 => approved,
        4 => available,
        3 => declined,
        _ => unknown,
      };

  String get label => switch (this) {
        pending   => 'Pending',
        approved  => 'Approved',
        available => 'Available',
        declined  => 'Declined',
        unknown   => 'Unknown',
      };
}

enum MediaType { movie, tv, unknown }

class MediaRequest {
  final int id;
  final RequestStatus status;
  final MediaType mediaType;
  final String title;
  final String posterPath;   // relative path, prefix dengan base URL tmdb
  final int year;
  final String requestedBy;
  final DateTime createdAt;

  const MediaRequest({
    required this.id,
    required this.status,
    required this.mediaType,
    required this.title,
    required this.posterPath,
    required this.year,
    required this.requestedBy,
    required this.createdAt,
  });

  factory MediaRequest.fromJson(Map<String, dynamic> j) {
    final media = j['media'] as Map<String, dynamic>? ?? {};
    final reqBy = j['requestedBy'] as Map<String, dynamic>? ?? {};
    final type  = (media['mediaType'] as String? ?? '') == 'movie'
        ? MediaType.movie
        : (media['mediaType'] as String? ?? '') == 'tv'
            ? MediaType.tv
            : MediaType.unknown;

    // Title bisa ada di media.title (movie) atau media.name (tv)
    final title = (media['title'] as String?)
        ?? (media['name'] as String?)
        ?? 'Unknown';

    // Year dari releaseDate atau firstAirDate
    final dateStr = (media['releaseDate'] as String?)
        ?? (media['firstAirDate'] as String?)
        ?? '';
    final year = dateStr.length >= 4
        ? int.tryParse(dateStr.substring(0, 4)) ?? 0
        : 0;

    return MediaRequest(
      id:          j['id'] as int,
      status:      RequestStatus.fromInt(j['status'] as int? ?? 0),
      mediaType:   type,
      title:       title,
      posterPath:  media['posterPath'] as String? ?? '',
      year:        year,
      requestedBy: (reqBy['displayName'] as String?)
          ?? (reqBy['username'] as String?)
          ?? 'Unknown',
      createdAt:   DateTime.tryParse(j['createdAt'] as String? ?? '')
          ?? DateTime.now(),
    );
  }

  String posterUrl([String size = 'w185']) =>
      posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/$size$posterPath'
          : '';
}
