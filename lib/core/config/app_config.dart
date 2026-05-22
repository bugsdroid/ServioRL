/// Konfigurasi koneksi ke semua service.
/// Nilai diisi dari SettingsScreen dan disimpan via SharedPreferences.
class AppConfig {
  final String sonarrBaseUrl;
  final String sonarrApiKey;
  final String radarrBaseUrl;
  final String radarrApiKey;
  final String seerrBaseUrl;
  final String seerrApiKey;
  final String transmissionBaseUrl;
  final String transmissionUsername;
  final String transmissionPassword;
  final String bazarrBaseUrl;
  final String bazarrApiKey;

  const AppConfig({
    required this.sonarrBaseUrl,
    required this.sonarrApiKey,
    required this.radarrBaseUrl,
    required this.radarrApiKey,
    required this.seerrBaseUrl,
    required this.seerrApiKey,
    required this.transmissionBaseUrl,
    required this.transmissionUsername,
    required this.transmissionPassword,
    required this.bazarrBaseUrl,
    required this.bazarrApiKey,
  });

  AppConfig copyWith({
    String? sonarrBaseUrl,
    String? sonarrApiKey,
    String? radarrBaseUrl,
    String? radarrApiKey,
    String? seerrBaseUrl,
    String? seerrApiKey,
    String? transmissionBaseUrl,
    String? transmissionUsername,
    String? transmissionPassword,
    String? bazarrBaseUrl,
    String? bazarrApiKey,
  }) =>
      AppConfig(
        sonarrBaseUrl:        sonarrBaseUrl        ?? this.sonarrBaseUrl,
        sonarrApiKey:         sonarrApiKey         ?? this.sonarrApiKey,
        radarrBaseUrl:        radarrBaseUrl        ?? this.radarrBaseUrl,
        radarrApiKey:         radarrApiKey         ?? this.radarrApiKey,
        seerrBaseUrl:         seerrBaseUrl         ?? this.seerrBaseUrl,
        seerrApiKey:          seerrApiKey          ?? this.seerrApiKey,
        transmissionBaseUrl:  transmissionBaseUrl  ?? this.transmissionBaseUrl,
        transmissionUsername: transmissionUsername ?? this.transmissionUsername,
        transmissionPassword: transmissionPassword ?? this.transmissionPassword,
        bazarrBaseUrl:        bazarrBaseUrl        ?? this.bazarrBaseUrl,
        bazarrApiKey:         bazarrApiKey         ?? this.bazarrApiKey,
      );

  static AppConfig get empty => const AppConfig(
        sonarrBaseUrl: '',        sonarrApiKey: '',
        radarrBaseUrl: '',        radarrApiKey: '',
        seerrBaseUrl: '',         seerrApiKey: '',
        transmissionBaseUrl: '',  transmissionUsername: '',
        transmissionPassword: '', bazarrBaseUrl: '',
        bazarrApiKey: '',
      );
}
