import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/config_provider.dart';
import '../../core/network/dio_client.dart';
import 'tv_model.dart';

class TvRepository {
  final Dio _dio;
  TvRepository(this._dio);

  Future<List<TvSeries>> getSeries() async {
    final res  = await _dio.get('/api/v3/series');
    final list = res.data as List<dynamic>;
    return list
        .map((j) => TvSeries.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortTitle.compareTo(b.sortTitle));
  }

  Future<List<Episode>> getEpisodes(int seriesId, int seasonNumber) async {
    final res  = await _dio.get('/api/v3/episode',
        queryParameters: {
          'seriesId':     seriesId,
          'seasonNumber': seasonNumber,
        });
    final list = res.data as List<dynamic>;
    return list
        .map((j) => Episode.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.episodeNumber.compareTo(a.episodeNumber));
  }

  Future<List<SonarrRelease>> interactiveSearch(int episodeId) async {
    final res  = await _dio.get('/api/v3/release',
        queryParameters: {'episodeId': episodeId});
    final list = res.data as List<dynamic>;
    return list
        .map((j) => SonarrRelease.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.seeders.compareTo(a.seeders));
  }

  Future<void> grabRelease(String guid, int indexerId) async {
    await _dio.post('/api/v3/release', data: {
      'guid':      guid,
      'indexerId': indexerId,
    });
  }

  Future<void> searchSeason(int seriesId, int seasonNumber) async {
    await _dio.post('/api/v3/command', data: {
      'name':         'SeasonSearch',
      'seriesId':     seriesId,
      'seasonNumber': seasonNumber,
    });
  }

  Future<void> searchEpisode(int episodeId) async {
    await _dio.post('/api/v3/command', data: {
      'name':       'EpisodeSearch',
      'episodeIds': [episodeId],
    });
  }
}

final tvRepositoryProvider = Provider<TvRepository>((ref) {
  return TvRepository(ref.watch(sonarrDioProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class TvSeriesNotifier extends AsyncNotifier<List<TvSeries>> {
  @override
  Future<List<TvSeries>> build() async {
    final cfg = ref.read(appConfigProvider);
    if (cfg.sonarrBaseUrl.isEmpty || cfg.sonarrApiKey.isEmpty) return [];
    return _fetch();
  }

  Future<List<TvSeries>> _fetch() =>
      ref.read(tvRepositoryProvider).getSeries();

  Future<void> refresh() async {
    final cfg = ref.read(appConfigProvider);
    if (cfg.sonarrBaseUrl.isEmpty || cfg.sonarrApiKey.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final tvSeriesProvider =
    AsyncNotifierProvider<TvSeriesNotifier, List<TvSeries>>(
        TvSeriesNotifier.new);

// ── Filter / sort ─────────────────────────────────────────────────────────────

enum TvFilter { all, continuing, ended, missing, monitored }
enum TvSort   { title, year, episodes, network }

final tvFilterProvider = StateProvider<TvFilter>((ref) => TvFilter.all);
final tvSortProvider   = StateProvider<TvSort>((ref) => TvSort.title);
final tvSearchProvider = StateProvider<String>((ref) => '');

final filteredTvProvider = Provider<AsyncValue<List<TvSeries>>>((ref) {
  final all    = ref.watch(tvSeriesProvider);
  final filter = ref.watch(tvFilterProvider);
  final sort   = ref.watch(tvSortProvider);
  final query  = ref.watch(tvSearchProvider).toLowerCase();

  return all.whenData((series) {
    var list = series.where((s) {
      if (query.isNotEmpty && !s.title.toLowerCase().contains(query)) {
        return false;
      }
      return switch (filter) {
        TvFilter.all        => true,
        TvFilter.continuing => s.status == SeriesStatus.continuing,
        TvFilter.ended      => s.status == SeriesStatus.ended,
        TvFilter.missing    => s.missingEpisodes > 0 && s.monitored,
        TvFilter.monitored  => s.monitored,
      };
    }).toList();

    list.sort((a, b) => switch (sort) {
          TvSort.title    => a.sortTitle.compareTo(b.sortTitle),
          TvSort.year     => b.year.compareTo(a.year),
          TvSort.episodes => b.episodeCount.compareTo(a.episodeCount),
          TvSort.network  => a.network.compareTo(b.network),
        });

    return list;
  });
});

// ── Episode provider ──────────────────────────────────────────────────────────

final episodeProvider = FutureProvider.autoDispose
    .family<List<Episode>, ({int seriesId, int seasonNumber})>((ref, args) {
  return ref
      .read(tvRepositoryProvider)
      .getEpisodes(args.seriesId, args.seasonNumber);
});

// ── Interactive search ────────────────────────────────────────────────────────

final tvInteractiveSearchProvider =
    FutureProvider.autoDispose.family<List<SonarrRelease>, int>((ref, epId) {
  return ref.read(tvRepositoryProvider).interactiveSearch(epId);
});
