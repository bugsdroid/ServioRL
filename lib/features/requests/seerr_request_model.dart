/// Status request dari Seerr API
enum RequestStatus {
  pending,    // 1
  approved,   // 2
  declined,   // 3
  available,  // 4 - sudah tersedia di library
  unknown;

  static RequestStatus fromInt(int v) => switch (v) {
        1 => pending,
        2 => approved,
        3 => declined,
        4 => available,
        _ => unknown,
      };

  String get label => switch (this) {
        pending   => 'Pending',
        approved  => 'Approved',
        declined  => 'Declined',
        available => 'Available',
        unknown   => 'Unknown',
      };
}

enum MediaType { movie, tv, unknown }

class SeerrRequest {
  final int id;
  final MediaType mediaType;
  final RequestStatus status;
  final String requestedByName;
  final String requestedByAvatar;
  final DateTime createdAt;

  // Media info (dari nested media object)
  final String title;
  final String posterPath;   // path saja, base URL ditambah di UI
  final String overview;
  final int? year;

  const SeerrRequest({
    required this.id,
    required this.mediaType,
    required this.status,
    required this.requestedByName,
    required this.requestedByAvatar,
    required this.createdAt,
    required this.title,
    required this.posterPath,
    required this.overview,
    this.year,
  });

  factory SeerrRequest.fromJson(Map<String, dynamic> j) {
    final media = j['media'] as Map<String, dynamic>? ?? {};
    final user  = j['requestedBy'] as Map<String, dynamic>? ?? {};

    // Seerr returns type as string 'movie' or 'tv'
    final typeStr = (j['type'] as String? ?? '').toLowerCase();
    final mediaType = switch (typeStr) {
      'movie' => MediaType.movie,
      'tv'    => MediaType.tv,
      _       => MediaType.unknown,
    };

    // Title: movie -> title, tv -> name
    final title = (media['title'] as String?)
        ?? (media['name'] as String?)
        ?? (media['originalTitle'] as String?)
        ?? (media['originalName'] as String?)
        ?? 'Unknown';

    // Year from releaseDate or firstAirDate
    int? year;
    final dateStr = (media['releaseDate'] as String?)
        ?? (media['firstAirDate'] as String?);
    if (dateStr != null && dateStr.length >= 4) {
      year = int.tryParse(dateStr.substring(0, 4));
    }

    return SeerrRequest(
      id:                  j['id'] as int,
      mediaType:           mediaType,
      status:              RequestStatus.fromInt(j['status'] as int? ?? 1),
      requestedByName:     (user['displayName'] as String?)
                           ?? (user['username'] as String?)
                           ?? 'Unknown',
      requestedByAvatar:   user['avatar'] as String? ?? '',
      createdAt:           DateTime.tryParse(j['createdAt'] as String? ?? '')
                           ?? DateTime.now(),
      title:               title,
      posterPath:          media['posterPath'] as String? ?? '',
      overview:            media['overview'] as String? ?? '',
      year:                year,
    );
  }
}

class SeerrStats {
  final int pending;
  final int approved;
  final int available;

  const SeerrStats({
    required this.pending,
    required this.approved,
    required this.available,
  });
}
