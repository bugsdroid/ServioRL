import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import 'search_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class SearchRepository {
  final dio;
  SearchRepository(this.dio);

  Future<List<SearchResult>> search(String query, {bool isMovie = true}) async {
    // Fix: encode query properly supaya spasi/simbol tidak break URL
    final encoded = Uri.encodeQueryComponent(query);
    final endpoint = isMovie
        ? '/api/v1/search?query=$encoded&mediaType=movie'
        : '/api/v1/search?query=$encoded&mediaType=tv';
    final res  = await dio.get(endpoint);
    final data = res.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((j) => SearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<SearchResult>> getTrending({bool isMovie = true}) async {
    final endpoint = isMovie
        ? '/api/v1/discover/movies'
        : '/api/v1/discover/tv';
    final res  = await dio.get(endpoint,
        queryParameters: {'page': 1, 'language': 'en'});
    final data    = res.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((j) => SearchResult.fromJson(j as Map<String, dynamic>))
        .take(6)
        .toList();
  }

  Future<void> requestMedia(int mediaId, String mediaType) async {
    await dio.post('/api/v1/request', data: {
      'mediaId':   mediaId,
      'mediaType': mediaType,
    });
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(seerrDioProvider));
});

// ── Providers ─────────────────────────────────────────────────────────────────

final searchIsMovieProvider = StateProvider<bool>((ref) => true);
final searchQueryProvider   = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query   = ref.watch(searchQueryProvider);
  final isMovie = ref.watch(searchIsMovieProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.read(searchRepositoryProvider);
  return repo.search(query.trim(), isMovie: isMovie);
});

final trendingMoviesProvider =
    FutureProvider<List<SearchResult>>((ref) async {
  return ref.read(searchRepositoryProvider).getTrending(isMovie: true);
});

final trendingTvProvider =
    FutureProvider<List<SearchResult>>((ref) async {
  return ref.read(searchRepositoryProvider).getTrending(isMovie: false);
});
