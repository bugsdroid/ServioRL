import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/config_provider.dart';
import '../../core/network/transmission_client.dart';
import 'torrent_model.dart';

class TorrentRepository {
  final TransmissionClient _client;
  TorrentRepository(this._client);

  Future<List<Torrent>> getTorrents() async {
    final raw = await _client.getTorrents();
    return raw
        .map((j) => Torrent.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> start(int id) => _client.startTorrent(id);
  Future<void> stop(int id)  => _client.stopTorrent(id);
  Future<void> remove(int id, {bool deleteData = false}) =>
      _client.removeTorrent(id, deleteData: deleteData);
}

final torrentRepositoryProvider = Provider<TorrentRepository>((ref) {
  return TorrentRepository(ref.watch(transmissionClientProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class TorrentNotifier extends AsyncNotifier<List<Torrent>> {
  @override
  Future<List<Torrent>> build() async {
    // Cek config dulu — kalau belum diisi jangan hit API
    final cfg = ref.read(appConfigProvider);
    if (cfg.transmissionBaseUrl.isEmpty) return [];
    return _fetch();
  }

  Future<List<Torrent>> _fetch() =>
      ref.read(torrentRepositoryProvider).getTorrents();

  Future<void> refresh() async {
    final cfg = ref.read(appConfigProvider);
    if (cfg.transmissionBaseUrl.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> start(int id) async {
    await ref.read(torrentRepositoryProvider).start(id);
    await refresh();
  }

  Future<void> stop(int id) async {
    await ref.read(torrentRepositoryProvider).stop(id);
    await refresh();
  }

  Future<void> remove(int id, {bool deleteData = false}) async {
    await ref.read(torrentRepositoryProvider).remove(id, deleteData: deleteData);
    await refresh();
  }
}

final torrentProvider =
    AsyncNotifierProvider<TorrentNotifier, List<Torrent>>(TorrentNotifier.new);
