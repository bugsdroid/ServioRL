// ── Series status ─────────────────────────────────────────────────────────────

enum SeriesStatus {
  continuing,
  ended,
  upcoming,
  unknown;

  static SeriesStatus fromString(String s) => switch (s.toLowerCase()) {
        'continuing' => continuing,
        'ended'      => ended,
        'upcoming'   => upcoming,
        _            => unknown,
      };

  String get label => switch (this) {
        continuing => 'Continuing',
        ended      => 'Ended',
        upcoming   => 'Upcoming',
        unknown    => 'Unknown',
      };
}

// ── Episode status ────────────────────────────────────────────────────────────

enum EpisodeStatus {
  downloaded,
  missing,
  unmonitored,
  unknown;
}

// ── Series ────────────────────────────────────────────────────────────────────

class TvSeries {
  final int id;
  final String title;
  final String sortTitle;
  final int year;
  final String overview;
  final String posterUrl;
  final String fanartUrl;
  final SeriesStatus status;
  final bool monitored;
  final String network;
  final int runtime;
  final double ratings;
  final List<String> genres;
  final int seasonCount;
  final int episodeCount;
  final int episodeFileCount;
  final String imdbId;
  final int tvdbId;

  const TvSeries({
    required this.id,
    required this.title,
    required this.sortTitle,
    required this.year,
    required this.overview,
    required this.posterUrl,
    required this.fanartUrl,
    required this.status,
    required this.monitored,
    required this.network,
    required this.runtime,
    required this.ratings,
    required this.genres,
    required this.seasonCount,
    required this.episodeCount,
    required this.episodeFileCount,
    required this.imdbId,
    required this.tvdbId,
  });

  factory TvSeries.fromJson(Map<String, dynamic> j) {
    final images = j['images'] as List<dynamic>? ?? [];
    String poster = '', fanart = '';
    for (final img in images) {
      final type = img['coverType'] as String? ?? '';
      final url  = img['remoteUrl'] as String?
          ?? img['url'] as String?
          ?? '';
      if (type == 'poster' && poster.isEmpty) poster = url;
      if (type == 'fanart' && fanart.isEmpty) fanart = url;
    }

    final stats = j['statistics'] as Map<String, dynamic>?;

    final ratingsMap = j['ratings'] as Map<String, dynamic>?;
    final rating = (ratingsMap?['value'] as num?)?.toDouble() ?? 0;

    return TvSeries(
      id:               j['id']       as int? ?? 0,
      title:            j['title']    as String? ?? 'Unknown',
      sortTitle:        j['sortTitle'] as String? ?? '',
      year:             j['year']     as int? ?? 0,
      overview:         j['overview'] as String? ?? '',
      posterUrl:        poster,
      fanartUrl:        fanart,
      status:           SeriesStatus.fromString(j['status'] as String? ?? ''),
      monitored:        j['monitored'] as bool? ?? false,
      network:          j['network']  as String? ?? '',
      runtime:          j['runtime']  as int? ?? 0,
      ratings:          rating,
      genres:           (j['genres'] as List<dynamic>?)
              ?.map((g) => g.toString())
              .toList() ?? [],
      seasonCount:      stats?['seasonCount']      as int? ?? 0,
      episodeCount:     stats?['episodeCount']     as int? ?? 0,
      episodeFileCount: stats?['episodeFileCount'] as int? ?? 0,
      imdbId:           j['imdbId']  as String? ?? '',
      tvdbId:           j['tvdbId']  as int? ?? 0,
    );
  }

  int get missingEpisodes => episodeCount - episodeFileCount;

  String get progressStr => '$episodeFileCount / $episodeCount episodes';

  double get progressPct =>
      episodeCount > 0 ? episodeFileCount / episodeCount : 0;

  String get runtimeStr {
    if (runtime <= 0) return '';
    return '${runtime}m / ep';
  }
}

// ── Season ────────────────────────────────────────────────────────────────────

class Season {
  final int seasonNumber;
  final bool monitored;
  final int episodeCount;
  final int episodeFileCount;

  const Season({
    required this.seasonNumber,
    required this.monitored,
    required this.episodeCount,
    required this.episodeFileCount,
  });

  factory Season.fromJson(Map<String, dynamic> j) {
    final stats = j['statistics'] as Map<String, dynamic>?;
    return Season(
      seasonNumber:     j['seasonNumber']      as int? ?? 0,
      monitored:        j['monitored']         as bool? ?? false,
      episodeCount:     stats?['episodeCount']     as int? ?? 0,
      episodeFileCount: stats?['episodeFileCount'] as int? ?? 0,
    );
  }

  int get missing => episodeCount - episodeFileCount;
}

// ── Episode ───────────────────────────────────────────────────────────────────

class Episode {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String overview;
  final bool monitored;
  final bool hasFile;
  final DateTime? airDate;
  final String quality;

  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.overview,
    required this.monitored,
    required this.hasFile,
    required this.airDate,
    required this.quality,
  });

  factory Episode.fromJson(Map<String, dynamic> j) {
    final file    = j['episodeFile'] as Map<String, dynamic>?;
    final quality = file?['quality']?['quality']?['name'] as String? ?? '';

    return Episode(
      id:            j['id']            as int? ?? 0,
      seasonNumber:  j['seasonNumber']  as int? ?? 0,
      episodeNumber: j['episodeNumber'] as int? ?? 0,
      title:         j['title']         as String? ?? 'TBA',
      overview:      j['overview']      as String? ?? '',
      monitored:     j['monitored']     as bool? ?? false,
      hasFile:       j['hasFile']       as bool? ?? false,
      airDate:       DateTime.tryParse(j['airDate'] as String? ?? ''),
      quality:       quality,
    );
  }

  String get code =>
      'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';
}

// ── Sonarr release ────────────────────────────────────────────────────────────

class SonarrRelease {
  final String guid;
  final String title;
  final int size;
  final int seeders;
  final int leechers;
  final String quality;
  final String indexer;
  final int age;
  final bool rejected;
  final List<String> rejections;

  const SonarrRelease({
    required this.guid,
    required this.title,
    required this.size,
    required this.seeders,
    required this.leechers,
    required this.quality,
    required this.indexer,
    required this.age,
    required this.rejected,
    required this.rejections,
  });

  factory SonarrRelease.fromJson(Map<String, dynamic> j) {
    final rej = (j['rejections'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ?? [];
    return SonarrRelease(
      guid:      j['guid']    as String? ?? '',
      title:     j['title']   as String? ?? 'Unknown',
      size:      j['size']    as int? ?? 0,
      seeders:   j['seeders'] as int? ?? 0,
      leechers:  j['leechers'] as int? ?? 0,
      quality:   j['quality']?['quality']?['name'] as String? ?? '',
      indexer:   j['indexer'] as String? ?? '',
      age:       j['age']     as int? ?? 0,
      rejected:  rej.isNotEmpty,
      rejections: rej,
    );
  }

  String get sizeStr {
    if (size <= 0) return '';
    final gb = size / 1024 / 1024 / 1024;
    if (gb >= 1) return '${gb.toStringAsFixed(2)} GB';
    return '${(size / 1024 / 1024).toStringAsFixed(0)} MB';
  }
}
