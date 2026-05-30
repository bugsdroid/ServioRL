import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/config_provider.dart';
import '../../core/theme/app_theme.dart';
import 'torrent_model.dart';
import 'torrent_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg      = ref.watch(appConfigProvider);
    final notReady = cfg.transmissionBaseUrl.isEmpty;
    final state    = ref.watch(torrentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Downloads',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                if (!notReady)
                  state.whenOrNull(
                    data: (list) {
                      final dl   = list.where((t) => t.status.isDownloading).length;
                      final seed = list.where((t) => t.status.isSeeding).length;
                      return Text(
                        '$dl downloading  •  $seed seeding',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                  ) ?? const SizedBox.shrink(),
              ],
            ),
            actions: [
              if (!notReady)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => ref.read(torrentProvider.notifier).refresh(),
                ),
            ],
          ),
        ],
        body: notReady
            ? _NotConfigured()
            : state.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
                error: (e, _) => _ErrorView(
                  error: e.toString(),
                  onRetry: () => ref.read(torrentProvider.notifier).refresh(),
                ),
                data: (torrents) => torrents.isEmpty
                    ? _EmptyView(
                        onRefresh: () => ref.read(torrentProvider.notifier).refresh())
                    : _TorrentList(torrents: torrents),
              ),
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download_outlined,
                  size: 40, color: AppColors.textDisabled),
            ),
            const SizedBox(height: 20),
            const Text('Transmission belum dikonfigurasi',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'Isi Base URL Transmission di Settings untuk melihat dan mengelola download.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Buka Settings'),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tealSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 40, color: AppColors.teal),
          ),
          const SizedBox(height: 20),
          const Text('Tidak ada torrent',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Queue kosong.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text('Gagal terhubung ke Transmission',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _TorrentList extends ConsumerStatefulWidget {
  final List<Torrent> torrents;
  const _TorrentList({required this.torrents});

  @override
  ConsumerState<_TorrentList> createState() => _TorrentListState();
}

class _TorrentListState extends ConsumerState<_TorrentList>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Torrent> _filtered(int idx) => switch (idx) {
        0 => widget.torrents,
        1 => widget.torrents.where((t) => t.status.isDownloading).toList(),
        2 => widget.torrents.where((t) => t.status.isSeeding).toList(),
        3 => widget.torrents.where((t) => t.status.isStopped).toList(),
        _ => widget.torrents,
      };

  @override
  Widget build(BuildContext context) {
    final dl   = widget.torrents.where((t) => t.status.isDownloading).length;
    final seed = widget.torrents.where((t) => t.status.isSeeding).length;
    final stop = widget.torrents.where((t) => t.status.isStopped).length;

    return Column(
      children: [
        Container(
          color: AppColors.background,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.teal,
            indicatorWeight: 2,
            labelColor: AppColors.teal,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(text: 'All (${widget.torrents.length})'),
              Tab(text: 'Downloading ($dl)'),
              Tab(text: 'Seeding ($seed)'),
              Tab(text: 'Paused ($stop)'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: List.generate(4, (i) {
              final list = _filtered(i);
              return RefreshIndicator(
                color: AppColors.teal,
                onRefresh: () => ref.read(torrentProvider.notifier).refresh(),
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text('Tidak ada torrent di kategori ini',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13)),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: list.length,
                        itemBuilder: (ctx, idx) => _TorrentCard(torrent: list[idx]),
                      ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _TorrentCard extends ConsumerWidget {
  final Torrent torrent;
  const _TorrentCard({required this.torrent});

  String _speed(int bps) {
    if (bps <= 0) return '0 B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }

  String _size(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _eta(int secs) {
    if (secs < 0) return '∞';
    if (secs < 60) return '${secs}s';
    if (secs < 3600) return '${secs ~/ 60}m';
    return '${secs ~/ 3600}h ${(secs % 3600) ~/ 60}m';
  }

  Color _barColor(Torrent t) {
    if (t.isStalled) return AppColors.error;
    if (t.status.isSeeding) return AppColors.success;
    if (t.status.isStopped) return AppColors.textDisabled;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = torrent;
    final pct      = t.percentDone;
    final barColor = _barColor(t);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(t.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              _ActionButton(torrent: t),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              if (t.status.isDownloading && t.rateDownload > 0) ...[
                const Icon(Icons.arrow_downward_rounded,
                    size: 11, color: AppColors.teal),
                const SizedBox(width: 2),
                Text(_speed(t.rateDownload),
                    style: const TextStyle(color: AppColors.teal, fontSize: 11)),
                const SizedBox(width: 8),
              ],
              if (t.rateUpload > 0) ...[
                const Icon(Icons.arrow_upward_rounded,
                    size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 2),
                Text(_speed(t.rateUpload),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(width: 8),
              ],
              Text(_size(t.totalSize),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              const Spacer(),
              if (t.isStalled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Stalled',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)))
              else if (t.status.isSeeding)
                Text(
                  'Ratio ${(t.rateUpload / (t.totalSize == 0 ? 1 : t.totalSize)).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11))
              else if (t.eta > 0)
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 11, color: AppColors.textDisabled),
                    const SizedBox(width: 2),
                    Text(_eta(t.eta),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
            ],
          ),
          if (t.error != 0 && t.errorString.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(t.errorString,
                style: const TextStyle(color: AppColors.error, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final Torrent torrent;
  const _ActionButton({required this.torrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = torrent;
    final notifier = ref.read(torrentProvider.notifier);

    if (t.status.isSeeding) {
      return Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.upload_rounded, size: 16, color: AppColors.success),
      );
    }

    if (t.status.isStopped) {
      return GestureDetector(
        onTap: () => notifier.start(t.id),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.teal),
        ),
      );
    }

    return GestureDetector(
      onTap: () => notifier.stop(t.id),
      onLongPress: () => _confirmRemove(context, ref, t),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.pause_rounded, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, Torrent t) async {
    bool deleteData = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Hapus Torrent?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: deleteData,
                activeColor: AppColors.teal,
                onChanged: (v) => setState(() => deleteData = v ?? false),
                title: const Text('Hapus file juga',
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 13)),
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
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(torrentProvider.notifier).remove(t.id, deleteData: deleteData);
    }
  }
}
