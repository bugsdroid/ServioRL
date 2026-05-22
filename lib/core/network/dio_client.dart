import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/config_provider.dart';

Dio buildDio(String baseUrl, String apiKey) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'X-Api-Key': apiKey},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.add(LogInterceptor(responseBody: false));
}

final sonarrDioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return buildDio(cfg.sonarrBaseUrl, cfg.sonarrApiKey);
});

final radarrDioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return buildDio(cfg.radarrBaseUrl, cfg.radarrApiKey);
});

// Seerr (bukan Overseerr)
final seerrDioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return buildDio(cfg.seerrBaseUrl, cfg.seerrApiKey);
});

final bazarrDioProvider = Provider<Dio>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return buildDio(cfg.bazarrBaseUrl, cfg.bazarrApiKey);
});
