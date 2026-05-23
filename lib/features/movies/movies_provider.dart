import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/config_provider.dart';
import '../../core/network/dio_client.dart';
import 'movie_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class MovieRepository {
  final Dio _dio;
  final String _baseUrl;
  MovieRepository(this._dio, this._baseUrl);

  Future<List<Movie>> getMovies() async {
    final res  = await _dio.get('/api/v3/movie');
    final list = res.data as List<dynamic>;
    return list
        .map((j) => Movie.fromJson(j as Map<String, dynamic>, _baseUrl))
        .toList()
      ..sort((a, b) => a.sortTitle.compareTo(b.sortTitle));
  }

  Future<List<RadarrRelease>> interactiveSearch(int movieId) async {
    final res  = await _dio.get('/api/v3/release',
        queryParameters: {'movieId': movieId});
    final list = res.data as List<dynamic>;
    return list
        .map((j) => RadarrRelease.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.seeders.compareTo(a.seeders));
  }

  Future<void> grabRelease(String guid, int indexerId) async {
    await _dio.post('/api/v3/release', data: {
      'guid':      guid,
      'indexerId': indexerId,
    });
  }

  Future<void> searchMovie(int movieId) async {
    await _dio.post('/api/v3/command', data: {
      'name':     'MoviesSearch',
      'movieIds': [movieId],
    });
  }

  Future<void> deleteMovie(int movieId,
      {bool deleteFiles = false}) async {
    await _dio.delete('/api/v3/movie/$movieId',
        queryParameters: {'deleteFiles': deleteFiles});
  }
}

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return MovieRepository(
    ref.watch(radarrDioProvider),
    cfg.radarrBaseUrl,
  );
});

// ── Movie list provider ───────────────────────────────────────────────────────

class MoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() => _fetch();

  Future<List<Movie>> _fetch() =>
      ref.read(movieRepositoryProvider).getMovies();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> searchMovie(int id) =>
      ref.read(movieRepositoryProvider).searchMovie(id);
}

final moviesProvider =
    AsyncNotifierProvider<MoviesNotifier, List<Movie>>(MoviesNotifier.new);

// ── Filter / sort ─────────────────────────────────────────────────────────────

enum MovieFilter { all, downloaded, missing, monitored }
enum MovieSort   { title, year, size, rating }

final movieFilterProvider = StateProvider<MovieFilter>((ref) => MovieFilter.all);
final movieSortProvider   = StateProvider<MovieSort>((ref) => MovieSort.title);
final movieSearchProvider = StateProvider<String>((ref) => '');

// Derived: filtered + sorted list
final filteredMoviesProvider = Provider<AsyncValue<List<Movie>>>((ref) {
  final all    = ref.watch(moviesProvider);
  final filter = ref.watch(movieFilterProvider);
  final sort   = ref.watch(movieSortProvider);
  final query  = ref.watch(movieSearchProvider).toLowerCase();

  return all.whenData((movies) {
    var list = movies.where((m) {
      // Text search
      if (query.isNotEmpty &&
          !m.title.toLowerCase().contains(query)) return false;
      // Status filter
      return switch (filter) {
        MovieFilter.all       => true,
        MovieFilter.downloaded=> m.hasFile,
        MovieFilter.missing   => !m.hasFile && m.monitored,
        MovieFilter.monitored => m.monitored,
      };
    }).toList();

    list.sort((a, b) => switch (sort) {
          MovieSort.title  => a.sortTitle.compareTo(b.sortTitle),
          MovieSort.year   => b.year.compareTo(a.year),
          MovieSort.size   => b.sizeOnDisk.compareTo(a.sizeOnDisk),
          MovieSort.rating => b.ratings.compareTo(a.ratings),
        });

    return list;
  });
});

// ── Interactive search provider ───────────────────────────────────────────────

final interactiveSearchProvider =
    FutureProvider.autoDispose.family<List<RadarrRelease>, int>((ref, movieId) {
  return ref.read(movieRepositoryProvider).interactiveSearch(movieId);
});
