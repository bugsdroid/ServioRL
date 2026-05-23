import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import 'subtitle_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class SubtitleRepository {
  final Dio _dio;
  SubtitleRepository(this._dio);

  /// Ambil movies yang missing subtitle
  Future<List<SubtitleItem>> getMissingMovies() async {
    final res  = await _dio.get(
      '/api/movies',
      queryParameters: {'start': 0, 'length': 100},
    );
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((j) => SubtitleItem.fromMovieJson(j as Map<String, dynamic>))
        .where((item) => item.missing.isNotEmpty)
        .toList();
  }

  /// Ambil episodes yang missing subtitle
  Future<List<SubtitleItem>> getMissingEpisodes() async {
    final res  = await _dio.get(
      '/api/episodes',
      queryParameters: {'start': 0, 'length': 100},
    );
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((j) => SubtitleItem.fromEpisodeJson(j as Map<String, dynamic>))
        .where((item) => item.missing.isNotEmpty)
        .toList();
  }

  /// Manual search subtitle untuk movie
  Future<List<SubtitleResult>> searchMovieSubtitles({
    required String radarrId,
    required String language,
  }) async {
    final res = await _dio.get(
      '/api/providers/movies',
      queryParameters: {
        'radarrid': radarrId,
        'language': language,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((j) => SubtitleResult.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Manual search subtitle untuk episode
  Future<List<SubtitleResult>> searchEpisodeSubtitles({
    required String episodeId,
    required String language,
  }) async {
    final res = await _dio.get(
      '/api/providers/episodes',
      queryParameters: {
        'episodeid': episodeId,
        'language':  language,
      },
    );
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((j) => SubtitleResult.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Download subtitle yang dipilih untuk movie
  Future<void> downloadMovieSubtitle({
    required String radarrId,
    required String language,
    required String subtitleId,
    required String provider,
  }) async {
    await _dio.post('/api/providers/movies', data: {
      'radarrid':  radarrId,
      'language':  language,
      'id':        subtitleId,
      'provider':  provider,
    });
  }

  /// Download subtitle yang dipilih untuk episode
  Future<void> downloadEpisodeSubtitle({
    required String episodeId,
    required String language,
    required String subtitleId,
    required String provider,
  }) async {
    await _dio.post('/api/providers/episodes', data: {
      'episodeid': episodeId,
      'language':  language,
      'id':        subtitleId,
      'provider':  provider,
    });
  }

  /// Trigger auto search
  Future<void> autoSearchMovie(String radarrId) async {
    await _dio.post('/api/movies', data: {'radarrid': radarrId, 'hi': 'False', 'forced': 'False'});
  }

  Future<void> autoSearchEpisode(String episodeId) async {
    await _dio.post('/api/episodes', data: {'episodeid': episodeId, 'hi': 'False', 'forced': 'False'});
  }
}

final subtitleRepositoryProvider = Provider<SubtitleRepository>((ref) {
  return SubtitleRepository(ref.watch(bazarrDioProvider));
});

// ── Missing subtitles provider ────────────────────────────────────────────────

class MissingSubtitlesNotifier
    extends AsyncNotifier<List<SubtitleItem>> {
  @override
  Future<List<SubtitleItem>> build() => _fetch();

  Future<List<SubtitleItem>> _fetch() async {
    final repo    = ref.read(subtitleRepositoryProvider);
    final movies  = await repo.getMissingMovies();
    final episodes = await repo.getMissingEpisodes();
    return [...movies, ...episodes];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final missingSubtitlesProvider =
    AsyncNotifierProvider<MissingSubtitlesNotifier, List<SubtitleItem>>(
        MissingSubtitlesNotifier.new);

// ── Filter ────────────────────────────────────────────────────────────────────

enum SubtitleFilter { all, movies, episodes }

final subtitleFilterProvider =
    StateProvider<SubtitleFilter>((ref) => SubtitleFilter.all);

final filteredSubtitlesProvider =
    Provider<AsyncValue<List<SubtitleItem>>>((ref) {
  final all    = ref.watch(missingSubtitlesProvider);
  final filter = ref.watch(subtitleFilterProvider);

  return all.whenData((items) => switch (filter) {
        SubtitleFilter.all      => items,
        SubtitleFilter.movies   => items.where((i) => i.isMovie).toList(),
        SubtitleFilter.episodes => items.where((i) => !i.isMovie).toList(),
      });
});

// ── Subtitle search provider ──────────────────────────────────────────────────

// Args: (radarrId or episodeId, language, isMovie)
typedef SubtitleSearchArgs = ({
  String mediaId,
  String language,
  bool isMovie
});

final subtitleSearchProvider = FutureProvider.autoDispose
    .family<List<SubtitleResult>, SubtitleSearchArgs>((ref, args) async {
  final repo = ref.read(subtitleRepositoryProvider);
  if (args.isMovie) {
    return repo.searchMovieSubtitles(
      radarrId: args.mediaId,
      language: args.language,
    );
  } else {
    return repo.searchEpisodeSubtitles(
      episodeId: args.mediaId,
      language:  args.language,
    );
  }
});
