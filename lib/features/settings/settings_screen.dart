import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/config_provider.dart';
import '../../core/config/app_config.dart';

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

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ref.read(appConfigProvider.notifier).save(_draft);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );

  Widget _field({
    required String label,
    required String initial,
    required void Function(String) onSaved,
    bool obscure = false,
    bool required = true,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          initialValue: initial,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Required' : null
              : null,
          onSaved: (v) => onSaved(v ?? ''),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Sonarr ──────────────────────────────────────────────────────
            _section('Sonarr'),
            _field(
              label: 'Base URL  (e.g. http://100.x.x.x:8989)',
              initial: _draft.sonarrBaseUrl,
              onSaved: (v) => _draft = _draft.copyWith(sonarrBaseUrl: v),
            ),
            _field(
              label: 'API Key',
              initial: _draft.sonarrApiKey,
              onSaved: (v) => _draft = _draft.copyWith(sonarrApiKey: v),
            ),

            // ── Radarr ──────────────────────────────────────────────────────
            _section('Radarr'),
            _field(
              label: 'Base URL  (e.g. http://100.x.x.x:7878)',
              initial: _draft.radarrBaseUrl,
              onSaved: (v) => _draft = _draft.copyWith(radarrBaseUrl: v),
            ),
            _field(
              label: 'API Key',
              initial: _draft.radarrApiKey,
              onSaved: (v) => _draft = _draft.copyWith(radarrApiKey: v),
            ),

            // ── Overseerr ───────────────────────────────────────────────────
            _section('Overseerr'),
            _field(
              label: 'Base URL  (e.g. http://100.x.x.x:5055)',
              initial: _draft.overseerrBaseUrl,
              onSaved: (v) => _draft = _draft.copyWith(overseerrBaseUrl: v),
            ),
            _field(
              label: 'API Key',
              initial: _draft.overseerrApiKey,
              onSaved: (v) => _draft = _draft.copyWith(overseerrApiKey: v),
            ),

            // ── Transmission ────────────────────────────────────────────────
            _section('Transmission'),
            _field(
              label: 'Base URL  (e.g. http://100.x.x.x:9091)',
              initial: _draft.transmissionBaseUrl,
              onSaved: (v) => _draft = _draft.copyWith(transmissionBaseUrl: v),
            ),
            _field(
              label: 'Username (optional)',
              initial: _draft.transmissionUsername,
              required: false,
              onSaved: (v) => _draft = _draft.copyWith(transmissionUsername: v),
            ),
            _field(
              label: 'Password (optional)',
              initial: _draft.transmissionPassword,
              required: false,
              obscure: true,
              onSaved: (v) => _draft = _draft.copyWith(transmissionPassword: v),
            ),

            // ── Bazarr ──────────────────────────────────────────────────────
            _section('Bazarr'),
            _field(
              label: 'Base URL  (e.g. http://100.x.x.x:6767)',
              initial: _draft.bazarrBaseUrl,
              onSaved: (v) => _draft = _draft.copyWith(bazarrBaseUrl: v),
            ),
            _field(
              label: 'API Key',
              initial: _draft.bazarrApiKey,
              onSaved: (v) => _draft = _draft.copyWith(bazarrApiKey: v),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
