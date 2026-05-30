import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/config_provider.dart';
import '../../core/theme/app_theme.dart';
import 'request_model.dart';
import 'requests_provider.dart';

enum _Tab { all, tv, movies }

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg     = ref.watch(appConfigProvider);
    final seerrOk = cfg.seerrBaseUrl.isNotEmpty && cfg.seerrApiKey.isNotEmpty;
    final state   = ref.watch(requestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: const Text('Requests'),
            actions: [
              if (seerrOk)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => ref.read(requestsProvider.notifier).refresh(),
                ),
            ],
            bottom: seerrOk
                ? TabBar(
                    controller: _tabCtrl,
                    indicatorColor: AppColors.teal,
                    indicatorWeight: 2,
                    labelColor: AppColors.teal,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Series'),
                      Tab(text: 'Movies'),
                    ],
                  )
                : null,
          ),
        ],
        body: !seerrOk
            ? _NotConfigured()
            : state.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
                error: (e, _) => _ErrorView(
                  error: e.toString(),
                  onRetry: () => ref.read(requestsProvider.notifier).refresh(),
                ),
                data: (all) {
                  if (all.isEmpty) {
                    return _EmptyView(
                        onRefresh: () =>
                            ref.read(requestsProvider.notifier).refresh());
                  }
                  final tv = all
                      .where((r) => r.mediaType == MediaType.tv)
                      .toList();
                  final movies = all
                      .where((r) => r.mediaType == MediaType.movie)
                      .toList();
                  return TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _RequestList(requests: all),
                      _RequestList(requests: tv),
                      _RequestList(requests: movies),
                    ],
                  );
                },
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
                  color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined,
                  size: 40, color: AppColors.textDisabled),
            ),
            const SizedBox(height: 20),
            const Text('Seerr belum dikonfigurasi',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
                'Isi Base URL dan API Key Seerr di Settings untuk melihat dan mengelola request.',
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
                color: AppColors.tealSurface, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded,
                size: 40, color: AppColors.teal),
          ),
          const SizedBox(height: 20),
          const Text('Tidak ada request',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Semua request sudah selesai.',
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
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text('Gagal terhubung ke Seerr',
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

class _RequestList extends ConsumerStatefulWidget {
  final List<MediaRequest> requests;
  const _RequestList({required this.requests});

  @override
  ConsumerState<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends ConsumerState<_RequestList> {
  _StatusFilter _filter = _StatusFilter.all;

  int _count(RequestStatus s) =>
      widget.requests.where((r) => r.status == s).length;

  List<MediaRequest> get _filtered => switch (_filter) {
        _StatusFilter.all => widget.requests,
        _StatusFilter.pending =>
          widget.requests.where((r) => r.status == RequestStatus.pending).toList(),
        _StatusFilter.approved =>
          widget.requests.where((r) => r.status == RequestStatus.approved).toList(),
        _StatusFilter.available =>
          widget.requests.where((r) => r.status == RequestStatus.available).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final pending   = _count(RequestStatus.pending);
    final approved  = _count(RequestStatus.approved);
    final available = _count(RequestStatus.available);
    final items     = _filtered;

    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: () => ref.read(requestsProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  _CountCard(
                    label: 'Pending', value: pending, color: AppColors.warning,
                    selected: _filter == _StatusFilter.pending,
                    onTap: () => setState(() => _filter =
                        _filter == _StatusFilter.pending
                            ? _StatusFilter.all
                            : _StatusFilter.pending),
                  ),
                  const SizedBox(width: 10),
                  _CountCard(
                    label: 'Approved', value: approved, color: AppColors.success,
                    selected: _filter == _StatusFilter.approved,
                    onTap: () => setState(() => _filter =
                        _filter == _StatusFilter.approved
                            ? _StatusFilter.all
                            : _StatusFilter.approved),
                  ),
                  const SizedBox(width: 10),
                  _CountCard(
                    label: 'Available', value: available, color: AppColors.teal,
                    selected: _filter == _StatusFilter.available,
                    onTap: () => setState(() => _filter =
                        _filter == _StatusFilter.available
                            ? _StatusFilter.all
                            : _StatusFilter.available),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text('Tidak ada request dengan status ini.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _RequestCard(request: items[i]),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _StatusFilter { all, pending, approved, available }

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CountCard({
    required this.label, required this.value, required this.color,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 1.5 : 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.toString(),
                  style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final MediaRequest request;
  const _RequestCard({required this.request});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12)),
            child: r.posterUrl().isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: r.posterUrl(),
                    width: 60, height: 90, fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(r),
                    errorWidget: (_, __, ___) => _placeholder(r))
                : _placeholder(r),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                            r.mediaType == MediaType.tv ? 'Series' : 'Movie',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 10)),
                      ),
                      if (r.year > 0) ...[
                        const SizedBox(width: 6),
                        Text('${r.year}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${r.requestedBy}  •  ${_timeAgo(r.createdAt)}',
                      style: const TextStyle(
                          color: AppColors.textDisabled, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: r.status),
                const SizedBox(height: 8),
                _ActionRow(request: r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(MediaRequest r) => Container(
        width: 60, height: 90,
        color: AppColors.surfaceVariant,
        child: Icon(
            r.mediaType == MediaType.tv ? Icons.tv_outlined : Icons.movie_outlined,
            color: AppColors.textDisabled, size: 22));
}

class _ActionRow extends ConsumerStatefulWidget {
  final MediaRequest request;
  const _ActionRow({required this.request});

  @override
  ConsumerState<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends ConsumerState<_ActionRow> {
  bool _loading = false;

  Future<void> _do(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.teal));
    }
    final r = widget.request;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (r.status == RequestStatus.pending)
          _IconAction(
            icon: Icons.check_rounded, color: AppColors.success, tooltip: 'Approve',
            onTap: () => _do(() => ref.read(requestsProvider.notifier).approve(r.id))),
        if (r.status == RequestStatus.pending) ...[
          const SizedBox(width: 6),
          _IconAction(
            icon: Icons.close_rounded, color: AppColors.error, tooltip: 'Decline',
            onTap: () => _do(() => ref.read(requestsProvider.notifier).decline(r.id))),
        ],
        const SizedBox(width: 6),
        _IconAction(
          icon: Icons.delete_outline_rounded,
          color: AppColors.textDisabled,
          tooltip: 'Hapus',
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('Hapus Request?'),
                content: Text(r.title),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal')),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus')),
                ],
              ),
            );
            if (ok == true) {
              await _do(() => ref.read(requestsProvider.notifier).delete(r.id));
            }
          },
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction({
    required this.icon, required this.color,
    required this.tooltip, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RequestStatus.pending   => ('Pending',   AppColors.warning),
      RequestStatus.approved  => ('Approved',  AppColors.success),
      RequestStatus.available => ('Available', AppColors.teal),
      RequestStatus.declined  => ('Declined',  AppColors.error),
      RequestStatus.unknown   => ('Unknown',   AppColors.textDisabled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
