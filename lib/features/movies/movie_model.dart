enum MovieStatus {
  unknown,
  announced,
  inCinemas,
  released,
  deleted;

  static MovieStatus fromString(String s) => switch (s.toLowerCase()) {
        'announced'  => announced,
        'incinemas'  => inCinemas,
        'released'   => released,
        'deleted'    => deleted,
        _            => unknown,
      };

  String get label => switch (this) {
        announced  => 'Announced',
        inCinemas  => 'In Cinemas',
        released   => 'Released',
        deleted    => 'Deleted',
        unknown    => 'Unknown',
      };
}

class Movie {
  final int id;
  final String title;
  final String sortTitle;
  final int year;
  final String overview;
  final String posterUrl;
  final String fanartUrl;
  final bool hasFile;
  final bool monitored;
  final MovieStatus status;
  final String studio;
  final int runtime;
  final double ratings;
  final String quality;
  final int sizeOnDisk;
  final String imdbId;
  final int tmdbId;
  final List<String> genres;

  const Movie({
    required this.id,
    required this.title,
    required this.sortTitle,
    required this.year,
    required this.overview,
    required this.posterUrl,
    required this.fanartUrl,
    required this.hasFile,
    required this.monitored,
    required this.status,
    required this.studio,
    required this.runtime,
    required this.ratings,
    required this.quality,
    required this.sizeOnDisk,
    required this.imdbId,
    required this.tmdbId,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> j, String baseUrl) {
    // Fix: _img() sekarang benar-benar dipakai untuk handle URL relatif vs absolut
    String img(String path) {
      if (path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      // URL relatif dari Radarr — prefix dengan baseUrl
      return '$baseUrl$path';
    }

    final images = j['images'] as List<dynamic>? ?? [];
    String poster = '', fanart = '';
    for (final image in images) {
      final type = image['coverType'] as String? ?? '';
      // Coba remoteUrl dulu (CDN), fallback ke url (lokal Radarr)
      final url  = image['remoteUrl'] as String?
          ?? image['url'] as String?
          ?? '';
      if (type == 'poster' && poster.isEmpty) poster = img(url);
      if (type == 'fanart' && fanart.isEmpty) fanart = img(url);
    }

    final file    = j['movieFile'] as Map<String, dynamic>?;
    final quality = file?['quality']?['quality']?['name'] as String? ?? '';
    final size    = file?['size'] as int? ?? 0;

    final ratingsMap = j['ratings'] as Map<String, dynamic>?;
    final imdb  = ratingsMap?['imdb']?['value'] as num? ?? 0;
    final tmdbR = ratingsMap?['tmdb']?['value'] as num? ?? 0;
    final rating = imdb > 0 ? imdb.toDouble() : tmdbR.toDouble();

    final genres = (j['genres'] as List<dynamic>?)
            ?.map((g) => g.toString())
            .toList() ?? [];

    return Movie(
      id:         j['id']        as int?    ?? 0,
      title:      j['title']     as String? ?? 'Unknown',
      sortTitle:  j['sortTitle'] as String? ?? '',
      year:       j['year']      as int?    ?? 0,
      overview:   j['overview']  as String? ?? '',
      posterUrl:  poster,
      fanartUrl:  fanart,
      hasFile:    j['hasFile']   as bool?   ?? false,
      monitored:  j['monitored'] as bool?   ?? false,
      status:     MovieStatus.fromString(j['status'] as String? ?? ''),
      studio:     j['studio']    as String? ?? '',
      runtime:    j['runtime']   as int?    ?? 0,
      ratings:    rating,
      quality:    quality,
      sizeOnDisk: size,
      imdbId:     j['imdbId']    as String? ?? '',
      tmdbId:     j['tmdbId']    as int?    ?? 0,
      genres:     genres,
    );
  }

  String get runtimeStr {
    if (runtime <= 0) return '';
    final h = runtime ~/ 60;
    final m = runtime % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String get sizeStr {
    if (sizeOnDisk <= 0) return '';
    final gb = sizeOnDisk / 1024 / 1024 / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}

// ── Interactive search result ─────────────────────────────────────────────────

class RadarrRelease {
  final String guid;
  final String title;
  final int size;
  final int seeders;
  final int leechers;
  final String quality;
  final double qualityScore;
  final String indexer;
  final String indexerFlags;
  final int indexerId;       // Fix: simpan indexerId asli dari API
  final int age;
  final bool rejected;
  final List<String> rejections;

  const RadarrRelease({
    required this.guid,
    required this.title,
    required this.size,
    required this.seeders,
    required this.leechers,
    required this.quality,
    required this.qualityScore,
    required this.indexer,
    required this.indexerFlags,
    required this.indexerId,
    required this.age,
    required this.rejected,
    required this.rejections,
  });

  factory RadarrRelease.fromJson(Map<String, dynamic> j) {
    final rejections = (j['rejections'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ?? [];

    return RadarrRelease(
      guid:         j['guid']          as String? ?? '',
      title:        j['title']         as String? ?? 'Unknown',
      size:         j['size']          as int?    ?? 0,
      seeders:      j['seeders']       as int?    ?? 0,
      leechers:     j['leechers']      as int?    ?? 0,
      quality:      j['quality']?['quality']?['name'] as String? ?? '',
      qualityScore: (j['qualityWeight'] as num?)?.toDouble() ?? 0,
      indexer:      j['indexer']       as String? ?? '',
      indexerFlags: j['indexerFlags']  as String? ?? '',
      // Fix: ambil indexerId asli dari response, fallback 0
      indexerId:    j['indexerId']     as int?    ?? 0,
      age:          j['age']           as int?    ?? 0,
      rejected:     rejections.isNotEmpty,
      rejections:   rejections,
    );
  }

  String get sizeStr {
    if (size <= 0) return '';
    final gb = size / 1024 / 1024 / 1024;
    if (gb >= 1) return '${gb.toStringAsFixed(2)} GB';
    final mb = size / 1024 / 1024;
    return '${mb.toStringAsFixed(0)} MB';
  }
}
