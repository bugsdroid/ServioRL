import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'torrent_model.dart';
import 'torrent_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(torrentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(torrentProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(error: e.toString(), ref: ref),
        data: (torrents) => _TorrentList(torrents: torrents),
      ),
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final WidgetRef ref;
  const _ErrorView({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Tidak bisa terhubung ke Transmission',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
              onPressed: () => ref.read(torrentProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Torrent list ─────────────────────────────────────────────────────────────

class _TorrentList extends StatefulWidget {
  final List<Torrent> torrents;
  const _TorrentList({required this.torrents});

  @override
  State<_TorrentList> createState() => _TorrentListState();
}

class _TorrentListState extends State<_TorrentList> {
  // Filter: all / downloading / seeding / stopped / stalled
  _Filter _filter = _Filter.all;

  List<Torrent> get _filtered => widget.torrents.where((t) {
        return switch (_filter) {
          _Filter.all        => true,
          _Filter.downloading => t.status.isDownloading && !t.isStalled,
          _Filter.seeding    => t.status.isSeeding,
          _Filter.stopped    => t.status.isStopped,
          _Filter.stalled    => t.isStalled,
        };
      }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      children: [
        // ── Filter chips ──────────────────────────────────────────────────
        _FilterBar(
          current: _filter,
          counts: {
            _Filter.all:         widget.torrents.length,
            _Filter.downloading: widget.torrents.where((t) => t.status.isDownloading && !t.isStalled).length,
            _Filter.seeding:     widget.torrents.where((t) => t.status.isSeeding).length,
            _Filter.stopped:     widget.torrents.where((t) => t.status.isStopped).length,
            _Filter.stalled:     widget.torrents.where((t) => t.isStalled).length,
          },
          onChanged: (f) => setState(() => _filter = f),
        ),

        // ── List ─────────────────────────────────────────────────────────
        if (filtered.isEmpty)
          const Expanded(
            child: Center(child: Text('Tidak ada torrent')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _TorrentCard(torrent: filtered[i]),
            ),
          ),
      ],
    );
  }
}

enum _Filter { all, downloading, seeding, stopped, stalled }

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter current;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onChanged;

  const _FilterBar({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  static const _labels = {
    _Filter.all:         'All',
    _Filter.downloading: 'DL',
    _Filter.seeding:     'Seed',
    _Filter.stopped:     'Stop',
    _Filter.stalled:     'Stalled',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _Filter.values.map((f) {
          final count = counts[f] ?? 0;
          final selected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${_labels[f]} $count'),
              selected: selected,
              onSelected: (_) => onChanged(f),
              // Highlight stalled in amber
              selectedColor: f == _Filter.stalled
                  ? Theme.of(context).colorScheme.errorContainer
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Torrent card ─────────────────────────────────────────────────────────────

class _TorrentCard extends ConsumerWidget {
  final Torrent torrent;
  const _TorrentCard({required this.torrent});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = bytes.toDouble();
    var i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(1)} ${units[i]}';
  }

  String _formatEta(int eta) {
    if (eta < 0) return '∞';
    if (eta < 60) return '${eta}s';
    if (eta < 3600) return '${eta ~/ 60}m';
    return '${eta ~/ 3600}h ${(eta % 3600) ~/ 60}m';
  }

  Color _progressColor(BuildContext context, Torrent t) {
    if (t.isStalled) return Theme.of(context).colorScheme.error;
    if (t.status.isSeeding) return Colors.green;
    if (t.status.isStopped) return Theme.of(context).colorScheme.outline;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = torrent;
    final pct = (t.percentDone * 100).toStringAsFixed(1);
    final color = _progressColor(context, t);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + status badge ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(torrent: t),
              ],
            ),

            const SizedBox(height: 8),

            // ── Progress bar ───────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: t.percentDone,
                minHeight: 6,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
            ),

            const SizedBox(height: 6),

            // ── Stats row ──────────────────────────────────────────────
            Row(
              children: [
                Text('$pct%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (t.status.isDownloading) ...[
                  Icon(Icons.arrow_downward, size: 12,
                      color: Theme.of(context).colorScheme.primary),
                  Text(_formatBytes(t.rateDownload) + '/s',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 6),
                ],
                if (t.rateUpload > 0) ...[
                  Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                  Text(_formatBytes(t.rateUpload) + '/s',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 6),
                ],
                if (t.status.isDownloading && t.eta > 0) ...[
                  Icon(Icons.schedule, size: 12,
                      color: Theme.of(context).colorScheme.outline),
                  Text(_formatEta(t.eta),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                const Spacer(),
                Text(
                  '${t.peersConnected} peers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: t.isStalled
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),

            // ── Error string ───────────────────────────────────────────
            if (t.error != 0 && t.errorString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t.errorString,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],

            // ── Action buttons ─────────────────────────────────────────
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Start / Stop toggle
                if (t.status.isStopped)
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    tooltip: 'Start',
                    onPressed: () =>
                        ref.read(torrentProvider.notifier).start(t.id),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.pause_rounded),
                    tooltip: 'Stop',
                    onPressed: () =>
                        ref.read(torrentProvider.notifier).stop(t.id),
                  ),

                // Remove
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error),
                  tooltip: 'Remove',
                  onPressed: () => _confirmRemove(context, ref, t),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, Torrent t) async {
    bool deleteData = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Hapus Torrent?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: deleteData,
                onChanged: (v) => setState(() => deleteData = v ?? false),
                title: const Text('Hapus file juga'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(torrentProvider.notifier)
          .remove(t.id, deleteData: deleteData);
    }
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final Torrent torrent;
  const _StatusBadge({required this.torrent});

  @override
  Widget build(BuildContext context) {
    final t = torrent;
    final (label, color) = t.isStalled
        ? ('Stalled', Theme.of(context).colorScheme.errorContainer)
        : t.status.isDownloading
            ? ('DL', Theme.of(context).colorScheme.primaryContainer)
            : t.status.isSeeding
                ? ('Seed', Colors.green.shade100)
                : t.status.isStopped
                    ? ('Stop', Theme.of(context).colorScheme.surfaceVariant)
                    : (t.status.label, Theme.of(context).colorScheme.surfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              )),
    );
  }
}
