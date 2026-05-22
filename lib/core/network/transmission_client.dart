import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/config_provider.dart';

/// Transmission menggunakan RPC protocol dengan X-Transmission-Session-Id.
/// Session ID didapat otomatis dari response 409 pertama.
class TransmissionClient {
  final Dio _dio;
  String _sessionId = '';

  TransmissionClient(String baseUrl, String username, String password)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ) {
    if (username.isNotEmpty) {
      // Basic auth
      _dio.options.headers['Authorization'] =
          'Basic ${_b64('$username:$password')}';
    }
  }

  String _b64(String s) {
    final bytes = s.codeUnits;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    var result = '';
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += chars[b0 >> 2];
      result += chars[((b0 & 3) << 4) | (b1 >> 4)];
      result += i + 1 < bytes.length ? chars[((b1 & 15) << 2) | (b2 >> 6)] : '=';
      result += i + 2 < bytes.length ? chars[b2 & 63] : '=';
    }
    return result;
  }

  Future<Map<String, dynamic>> rpc(Map<String, dynamic> body) async {
    try {
      return await _post(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        _sessionId = e.response?.headers.value('x-transmission-session-id') ?? '';
        return await _post(body);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    final res = await _dio.post(
      '/transmission/rpc',
      data: body,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'X-Transmission-Session-Id': _sessionId,
      }),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTorrents() async {
    final res = await rpc({
      'method': 'torrent-get',
      'arguments': {
        'fields': [
          'id', 'name', 'status', 'percentDone', 'rateDownload',
          'rateUpload', 'peersConnected', 'totalSize', 'error',
          'errorString', 'eta', 'isFinished',
        ],
      },
    });
    return res['arguments']['torrents'] as List<dynamic>;
  }

  Future<void> startTorrent(int id) =>
      rpc({'method': 'torrent-start', 'arguments': {'ids': [id]}});

  Future<void> stopTorrent(int id) =>
      rpc({'method': 'torrent-stop', 'arguments': {'ids': [id]}});

  Future<void> removeTorrent(int id, {bool deleteData = false}) =>
      rpc({
        'method': 'torrent-remove',
        'arguments': {'ids': [id], 'delete-local-data': deleteData},
      });
}

final transmissionClientProvider = Provider<TransmissionClient>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return TransmissionClient(
    cfg.transmissionBaseUrl,
    cfg.transmissionUsername,
    cfg.transmissionPassword,
  );
});
