import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main.dart after SharedPreferences.getInstance()');
});

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppConfigNotifier(prefs);
});

class AppConfigNotifier extends StateNotifier<AppConfig> {
  final SharedPreferences _prefs;

  AppConfigNotifier(this._prefs) : super(_load(_prefs));

  static AppConfig _load(SharedPreferences p) => AppConfig(
        sonarrBaseUrl:        p.getString('sonarr_url')         ?? '',
        sonarrApiKey:         p.getString('sonarr_key')         ?? '',
        radarrBaseUrl:        p.getString('radarr_url')         ?? '',
        radarrApiKey:         p.getString('radarr_key')         ?? '',
        seerrBaseUrl:         p.getString('seerr_url')          ?? '',
        seerrApiKey:          p.getString('seerr_key')          ?? '',
        transmissionBaseUrl:  p.getString('transmission_url')   ?? '',
        transmissionUsername: p.getString('transmission_user')  ?? '',
        transmissionPassword: p.getString('transmission_pass')  ?? '',
        bazarrBaseUrl:        p.getString('bazarr_url')         ?? '',
        bazarrApiKey:         p.getString('bazarr_key')         ?? '',
      );

  Future<void> save(AppConfig config) async {
    state = config;
    await Future.wait([
      _prefs.setString('sonarr_url',        config.sonarrBaseUrl),
      _prefs.setString('sonarr_key',        config.sonarrApiKey),
      _prefs.setString('radarr_url',        config.radarrBaseUrl),
      _prefs.setString('radarr_key',        config.radarrApiKey),
      _prefs.setString('seerr_url',         config.seerrBaseUrl),
      _prefs.setString('seerr_key',         config.seerrApiKey),
      _prefs.setString('transmission_url',  config.transmissionBaseUrl),
      _prefs.setString('transmission_user', config.transmissionUsername),
      _prefs.setString('transmission_pass', config.transmissionPassword),
      _prefs.setString('bazarr_url',        config.bazarrBaseUrl),
      _prefs.setString('bazarr_key',        config.bazarrApiKey),
    ]);
  }
}
