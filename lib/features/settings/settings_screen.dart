import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/config_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Connections ─────────────────────────────────────────────
            _sectionHeader('Connections'),
            const SizedBox(height: 8),

            // Seerr
            _ServiceTile(
              name: 'Seerr',
              icon: Icons.explore_rounded,
              color: AppColors.teal,
              urlInitial: _draft.seerrBaseUrl,
              keyInitial: _draft.seerrApiKey,
              onUrlSaved: (v) => _draft = _draft.copyWith(seerrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(seerrApiKey: v),
            ),
            const SizedBox(height: 8),

            // Sonarr
            _ServiceTile(
              name: 'Sonarr',
              icon: Icons.tv_rounded,
              color: const Color(0xFF2196F3),
              urlInitial: _draft.sonarrBaseUrl,
              keyInitial: _draft.sonarrApiKey,
              onUrlSaved: (v) => _draft = _draft.copyWith(sonarrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(sonarrApiKey: v),
            ),
            const SizedBox(height: 8),

            // Radarr
            _ServiceTile(
              name: 'Radarr',
              icon: Icons.movie_rounded,
              color: const Color(0xFFFF9800),
              urlInitial: _draft.radarrBaseUrl,
              keyInitial: _draft.radarrApiKey,
              onUrlSaved: (v) => _draft = _draft.copyWith(radarrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(radarrApiKey: v),
            ),
            const SizedBox(height: 8),

            // Transmission
            _ServiceTile(
              name: 'Transmission',
              icon: Icons.download_rounded,
              color: const Color(0xFF9C27B0),
              urlInitial: _draft.transmissionBaseUrl,
              keyInitial: _draft.transmissionUsername,
              keyLabel: 'Username',
              onUrlSaved: (v) => _draft = _draft.copyWith(transmissionBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(transmissionUsername: v),
              extraChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextFormField(
                  initialValue: _draft.transmissionPassword,
                  obscureText: true,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSaved: (v) =>
                      _draft = _draft.copyWith(transmissionPassword: v ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bazarr
            _ServiceTile(
              name: 'Bazarr',
              icon: Icons.subtitles_rounded,
              color: const Color(0xFFE91E63),
              urlInitial: _draft.bazarrBaseUrl,
              keyInitial: _draft.bazarrApiKey,
              onUrlSaved: (v) => _draft = _draft.copyWith(bazarrBaseUrl: v),
              onKeySaved: (v) => _draft = _draft.copyWith(bazarrApiKey: v),
            ),
            const SizedBox(height: 8),

            // Add service placeholder
            _AddServiceButton(),

            // ── General ─────────────────────────────────────────────────
            const SizedBox(height: 24),
            _sectionHeader('General'),
            const SizedBox(height: 8),
            _generalTile(Icons.palette_outlined,       'Appearance',    'System'),
            const SizedBox(height: 1),
            _generalTile(Icons.notifications_outlined, 'Notifications', ''),
            const SizedBox(height: 1),
            _generalTile(Icons.info_outline_rounded,   'About',         'ServioRL v0.1.0'),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
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
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14)),
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

// ── Service tile (expandable) ─────────────────────────────────────────────────

class _ServiceTile extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String urlInitial;
  final String keyInitial;
  final String keyLabel;
  final void Function(String) onUrlSaved;
  final void Function(String) onKeySaved;
  final Widget? extraChild;

  const _ServiceTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.urlInitial,
    required this.keyInitial,
    required this.onUrlSaved,
    required this.onKeySaved,
    this.keyLabel = 'API Key',
    this.extraChild,
  });

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isConfigured = widget.urlInitial.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
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
                        if (widget.urlInitial.isNotEmpty)
                          Text(widget.urlInitial,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isConfigured
                          ? AppColors.tealSurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isConfigured ? 'Connected' : 'Setup',
                      style: TextStyle(
                        color: isConfigured
                            ? AppColors.teal
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: widget.urlInitial,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'http://100.x.x.x:port',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                    onSaved: (v) => widget.onUrlSaved(v ?? ''),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: widget.keyInitial,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(labelText: widget.keyLabel),
                    onSaved: (v) => widget.onKeySaved(v ?? ''),
                  ),
                ],
              ),
            ),
            if (widget.extraChild != null) widget.extraChild!,
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AddServiceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: AppColors.textSecondary, size: 18),
        ),
        title: const Text('Add Service',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: const Text('Connect a new service',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ),
    );
  }
}
