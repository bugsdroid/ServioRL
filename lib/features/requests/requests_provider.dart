import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import 'request_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class RequestRepository {
  final Dio _dio;
  RequestRepository(this._dio);

  /// Ambil semua request, semua halaman (max 10 halaman / 500 item)
  Future<List<MediaRequest>> getRequests() async {
    final all = <MediaRequest>[];
    int page = 1;

    while (true) {
      final res = await _dio.get(
        '/api/v1/request',
        queryParameters: {
          'take': 50,
          'skip': (page - 1) * 50,
          'sort': 'added',
          'filter': 'all',
        },
      );
      final data    = res.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      final total   = data['pageInfo']?['results'] as int? ?? 0;

      all.addAll(results.map(
          (j) => MediaRequest.fromJson(j as Map<String, dynamic>)));

      if (all.length >= total || results.isEmpty || page >= 10) break;
      page++;
    }

    return all;
  }

  /// Hapus request
  Future<void> deleteRequest(int id) =>
      _dio.delete('/api/v1/request/$id');

  /// Approve request (admin)
  Future<void> approveRequest(int id) =>
      _dio.post('/api/v1/request/$id/approve');

  /// Decline request (admin)
  Future<void> declineRequest(int id) =>
      _dio.post('/api/v1/request/$id/decline');
}

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository(ref.watch(seerrDioProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class RequestsNotifier extends AsyncNotifier<List<MediaRequest>> {
  @override
  Future<List<MediaRequest>> build() => _fetch();

  Future<List<MediaRequest>> _fetch() =>
      ref.read(requestRepositoryProvider).getRequests();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> delete(int id) async {
    await ref.read(requestRepositoryProvider).deleteRequest(id);
    await refresh();
  }

  Future<void> approve(int id) async {
    await ref.read(requestRepositoryProvider).approveRequest(id);
    await refresh();
  }

  Future<void> decline(int id) async {
    await ref.read(requestRepositoryProvider).declineRequest(id);
    await refresh();
  }
}

final requestsProvider =
    AsyncNotifierProvider<RequestsNotifier, List<MediaRequest>>(
        RequestsNotifier.new);
