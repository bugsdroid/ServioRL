import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/config/config_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

// ── Connection status enum ────────────────────────────────────────────────────

enum ConnStatus { idle, testing, ok, fail }

// ── Per-service connection tester ─────────────────────────────────────────────

class _ServiceTester {
  static Future<String> test({
    required String service,
    required String baseUrl,
    required String apiKey,
    String? username,
    String? password,
  }) async {
    if (baseUrl.trim().isEmpty) return 'URL kosong';

    final url = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      switch (service) {
        case 'sonarr':
        case 'radarr':
          if (apiKey.trim().isEmpty) return 'API Key kosong';
          final res = await dio.get(
            '$url/api/v3/system/status',
            options: Options(headers: {'X-Api-Key': apiKey.trim()}),
          );
          if (res.statusCode == 200) {
            final version = res.data['version'] ?? '?';
            return 'OK — v$version';
          }
          return 'Response ${res.statusCode}';

        case 'seerr':
          if (apiKey.trim().isEmpty) return 'API Key kosong';
          final res = await dio.get(
            '$url/api/v1/status',
            options: Options(headers: {'X-Api-Key': apiKey.trim()}),
          );
          if (res.statusCode == 200) {
            final version = res.data['version'] ?? '?';
            return 'OK — v$version';
          }
          return 'Response ${res.statusCode}';

        case 'bazarr':
          if (apiKey.trim().isEmpty) return 'API Key kosong';
          final res = await dio.get(
            '$url/api/system/status',
            options: Options(headers: {'X-Api-Key': apiKey.trim()}),
          );
          if (res.statusCode == 200) return 'OK';
          return 'Response ${res.statusCode}';

        case 'transmission':
          String sessionId = '';
          String? basicAuth;
          if ((username ?? '').isNotEmpty) {
            basicAuth = 'Basic ${_b64('$username:$password')}';
          }
          final headers = <String, dynamic>{
            'Content-Type': 'application/json',
            if (basicAuth != null) 'Authorization': basicAuth,
          };
          try {
            await dio.post(
              '$url/transmission/rpc',
              data: {'method': 'session-get'},
              options: Options(headers: headers),
            );
          } on DioException catch (e) {
            if (e.response?.statusCode == 409) {
              sessionId = e.response?.headers
                      .value('x-transmission-session-id') ?? '';
              final res2 = await dio.post(
                '$url/transmission/rpc',
                data: {'method': 'session-get'},
                options: Options(headers: {
                  ...headers,
                  'X-Transmission-Session-Id': sessionId,
                }),
              );
              if (res2.statusCode == 200) {
                final ver = res2.data['arguments']?['version'] ?? '?';
                return 'OK — v$ver';
              }
            }
            rethrow;
          }
          return 'OK';

        default:
          return 'Service tidak dikenal';
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Timeout — cek IP/port';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Tidak bisa konek — cek Tailscale & URL';
      }
      if (e.response?.statusCode == 401) return 'Auth gagal — cek API Key';
      if (e.response?.statusCode == 403) return 'Forbidden — cek API Key';
      if (e.response?.statusCode == 404) return 'URL salah (404)';
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  static String _b64(String s) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final bytes = s.codeUnits;
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
}

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppConfig _draft;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _draft = ref.read(appConfigProvider);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await ref.read(appConfigProvider.notifier).save(_draft);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings disimpan')),
        );
        // Pakai GoRouter pop — bukan Navigator
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('Connections'),
            const SizedBox(height: 4),
            const Text(
              'Isi Base URL dan API Key lalu tekan Test untuk verifikasi koneksi.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),

            _ServiceTile(
              service: 'seerr',
              name: 'Seerr',
              icon: Icons.explore_rounded,
              color: AppColors.teal,
              urlInitial: _draft.seerrBaseUrl,
              keyInitial: _draft.seerrApiKey,
              keyLabel: 'API Key',
              urlHint: 'http://100.x.x.x:5055',
              onUrlSaved: (v) => _draft = _draft.copyWith(seerrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(seerrApiKey: v),
            ),
            const SizedBox(height: 10),

            _ServiceTile(
              service: 'sonarr',
              name: 'Sonarr',
              icon: Icons.tv_rounded,
              color: const Color(0xFF2196F3),
              urlInitial: _draft.sonarrBaseUrl,
              keyInitial: _draft.sonarrApiKey,
              keyLabel: 'API Key',
              urlHint: 'http://100.x.x.x:8989',
              onUrlSaved: (v) => _draft = _draft.copyWith(sonarrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(sonarrApiKey: v),
            ),
            const SizedBox(height: 10),

            _ServiceTile(
              service: 'radarr',
              name: 'Radarr',
              icon: Icons.movie_rounded,
              color: const Color(0xFFFF9800),
              urlInitial: _draft.radarrBaseUrl,
              keyInitial: _draft.radarrApiKey,
              keyLabel: 'API Key',
              urlHint: 'http://100.x.x.x:7878',
              onUrlSaved: (v) => _draft = _draft.copyWith(radarrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(radarrApiKey: v),
            ),
            const SizedBox(height: 10),

            _TransmissionTile(
              urlInitial: _draft.transmissionBaseUrl,
              userInitial: _draft.transmissionUsername,
              passInitial: _draft.transmissionPassword,
              onUrlSaved: (v) => _draft = _draft.copyWith(transmissionBaseUrl: v),
              onUserSaved: (v) => _draft = _draft.copyWith(transmissionUsername: v),
              onPassSaved: (v) => _draft = _draft.copyWith(transmissionPassword: v),
            ),
            const SizedBox(height: 10),

            _ServiceTile(
              service: 'bazarr',
              name: 'Bazarr',
              icon: Icons.subtitles_rounded,
              color: const Color(0xFFE91E63),
              urlInitial: _draft.bazarrBaseUrl,
              keyInitial: _draft.bazarrApiKey,
              keyLabel: 'API Key',
              urlHint: 'http://100.x.x.x:6767',
              onUrlSaved: (v) => _draft = _draft.copyWith(bazarrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(bazarrApiKey: v),
            ),

            const SizedBox(height: 28),
            _sectionHeader('General'),
            const SizedBox(height: 10),
            _generalTile(Icons.palette_outlined, 'Appearance', 'Dark'),
            const SizedBox(height: 1),
            _generalTile(Icons.notifications_outlined, 'Notifications', ''),
            const SizedBox(height: 1),
            _generalTile(Icons.info_outline_rounded, 'About', 'ServioRL v0.1.0'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _generalTile(IconData icon, String title, String trailing) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(icon, color: AppColors.textSecondary, size: 20),
          title: Text(title,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing.isNotEmpty)
                Text(trailing,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.textDisabled, size: 18),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SERVICE TILE
// ══════════════════════════════════════════════════════════════════════════════

class _ServiceTile extends StatefulWidget {
  final String service;
  final String name;
  final IconData icon;
  final Color color;
  final String urlInitial;
  final String keyInitial;
  final String keyLabel;
  final String urlHint;
  final void Function(String) onUrlSaved;
  final void Function(String) onKeySaved;

  const _ServiceTile({
    required this.service,
    required this.name,
    required this.icon,
    required this.color,
    required this.urlInitial,
    required this.keyInitial,
    required this.keyLabel,
    required this.urlHint,
    required this.onUrlSaved,
    required this.onKeySaved,
  });

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _expanded = false;
  ConnStatus _status = ConnStatus.idle;
  String _statusMsg = '';

  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.urlInitial);
    _keyCtrl = TextEditingController(text: widget.keyInitial);
    if (widget.urlInitial.isNotEmpty && widget.keyInitial.isNotEmpty) {
      _statusMsg = 'Belum di-test';
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    widget.onUrlSaved(_urlCtrl.text);
    widget.onKeySaved(_keyCtrl.text);
    setState(() {
      _status = ConnStatus.testing;
      _statusMsg = 'Testing...';
    });
    final result = await _ServiceTester.test(
      service: widget.service,
      baseUrl: _urlCtrl.text,
      apiKey: _keyCtrl.text,
    );
    setState(() {
      _status = result.startsWith('OK') ? ConnStatus.ok : ConnStatus.fail;
      _statusMsg = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _status == ConnStatus.ok
              ? AppColors.teal.withOpacity(0.5)
              : _status == ConnStatus.fail
                  ? AppColors.error.withOpacity(0.5)
                  : AppColors.border,
          width: _status == ConnStatus.ok || _status == ConnStatus.fail
              ? 1.0
              : 0.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
                        if (_urlCtrl.text.isNotEmpty)
                          Text(_urlCtrl.text,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _StatusBadge(status: _status, message: _statusMsg),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textDisabled,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 0, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  TextFormField(
                    controller: _urlCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                        labelText: 'Base URL', hintText: widget.urlHint),
                    onSaved: (v) => widget.onUrlSaved(v ?? ''),
                    onChanged: (_) => setState(() {
                      _status = ConnStatus.idle;
                      _statusMsg = '';
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _keyCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(labelText: widget.keyLabel),
                    onSaved: (v) => widget.onKeySaved(v ?? ''),
                    onChanged: (_) => setState(() {
                      _status = ConnStatus.idle;
                      _statusMsg = '';
                    }),
                  ),
                  const SizedBox(height: 14),
                  if (_statusMsg.isNotEmpty && _status != ConnStatus.testing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            _status == ConnStatus.ok
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 14,
                            color: _status == ConnStatus.ok
                                ? AppColors.teal
                                : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _statusMsg,
                              style: TextStyle(
                                color: _status == ConnStatus.ok
                                    ? AppColors.teal
                                    : AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _status == ConnStatus.testing
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.teal))
                          : const Icon(Icons.cable_rounded, size: 16),
                      label: Text(_status == ConnStatus.testing
                          ? 'Testing...'
                          : 'Test Connection'),
                      onPressed: _status == ConnStatus.testing ? null : _test,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TRANSMISSION TILE
// ══════════════════════════════════════════════════════════════════════════════

class _TransmissionTile extends StatefulWidget {
  final String urlInitial;
  final String userInitial;
  final String passInitial;
  final void Function(String) onUrlSaved;
  final void Function(String) onUserSaved;
  final void Function(String) onPassSaved;

  const _TransmissionTile({
    required this.urlInitial,
    required this.userInitial,
    required this.passInitial,
    required this.onUrlSaved,
    required this.onUserSaved,
    required this.onPassSaved,
  });

  @override
  State<_TransmissionTile> createState() => _TransmissionTileState();
}

class _TransmissionTileState extends State<_TransmissionTile> {
  bool _expanded = false;
  bool _showPass = false;
  ConnStatus _status = ConnStatus.idle;
  String _statusMsg = '';

  late final TextEditingController _urlCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl  = TextEditingController(text: widget.urlInitial);
    _userCtrl = TextEditingController(text: widget.userInitial);
    _passCtrl = TextEditingController(text: widget.passInitial);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    widget.onUrlSaved(_urlCtrl.text);
    widget.onUserSaved(_userCtrl.text);
    widget.onPassSaved(_passCtrl.text);
    setState(() {
      _status = ConnStatus.testing;
      _statusMsg = 'Testing...';
    });
    final result = await _ServiceTester.test(
      service:  'transmission',
      baseUrl:  _urlCtrl.text,
      apiKey:   '',
      username: _userCtrl.text,
      password: _passCtrl.text,
    );
    setState(() {
      _status = result.startsWith('OK') ? ConnStatus.ok : ConnStatus.fail;
      _statusMsg = result;
    });
  }

  void _reset() => setState(() {
        _status = ConnStatus.idle;
        _statusMsg = '';
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _status == ConnStatus.ok
              ? AppColors.teal.withOpacity(0.5)
              : _status == ConnStatus.fail
                  ? AppColors.error.withOpacity(0.5)
                  : AppColors.border,
          width: _status == ConnStatus.ok || _status == ConnStatus.fail
              ? 1.0
              : 0.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: Color(0xFF9C27B0), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transmission',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
                        if (_urlCtrl.text.isNotEmpty)
                          Text(_urlCtrl.text,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _StatusBadge(status: _status, message: _statusMsg),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textDisabled,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 0, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Username & password opsional — isi jika auth diaktifkan di Transmission.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'http://100.x.x.x:9091'),
                    onSaved: (v) => widget.onUrlSaved(v ?? ''),
                    onChanged: (_) => _reset(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _userCtrl,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration:
                        const InputDecoration(labelText: 'Username (opsional)'),
                    onSaved: (v) => widget.onUserSaved(v ?? ''),
                    onChanged: (_) => _reset(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Password (opsional)',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _showPass = !_showPass),
                      ),
                    ),
                    onSaved: (v) => widget.onPassSaved(v ?? ''),
                    onChanged: (_) => _reset(),
                  ),
                  const SizedBox(height: 14),
                  if (_statusMsg.isNotEmpty && _status != ConnStatus.testing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            _status == ConnStatus.ok
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            size: 14,
                            color: _status == ConnStatus.ok
                                ? AppColors.teal
                                : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _statusMsg,
                              style: TextStyle(
                                color: _status == ConnStatus.ok
                                    ? AppColors.teal
                                    : AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: _status == ConnStatus.testing
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.teal))
                          : const Icon(Icons.cable_rounded, size: 16),
                      label: Text(_status == ConnStatus.testing
                          ? 'Testing...'
                          : 'Test Connection'),
                      onPressed: _status == ConnStatus.testing ? null : _test,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final ConnStatus status;
  final String message;
  const _StatusBadge({required this.status, required this.message});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case ConnStatus.idle:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message == 'Belum di-test' ? 'Belum di-test' : 'Setup',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        );

      case ConnStatus.testing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.teal),
              ),
              SizedBox(width: 5),
              Text('Testing',
                  style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );

      case ConnStatus.ok:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.tealSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 12, color: AppColors.teal),
              SizedBox(width: 4),
              Text('Connected',
                  style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );

      case ConnStatus.fail:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_rounded, size: 12, color: AppColors.error),
              SizedBox(width: 4),
              Text('Failed',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
    }
  }
}
