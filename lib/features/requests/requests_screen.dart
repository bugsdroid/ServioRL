import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import 'request_model.dart';
import 'requests_provider.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Tab: 0=Seerr, 1=Sonarr, 2=Radarr  (filter by source/type)
  // Sesuai mockup: tab Overseerr | Sonarr | Radarr
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: const Text('Requests'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () =>
                    ref.read(requestsProvider.notifier).refresh(),
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.teal,
              indicatorWeight: 2,
              labelColor: AppColors.teal,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'Seerr'),
                Tab(text: 'Sonarr'),
                Tab(text: 'Radarr'),
              ],
            ),
          ),
        ],
        body: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
          error: (e, _) => _ErrorView(error: e.toString(), ref: ref),
          data: (all) {
            // Filter per tab
            final seerr  = all; // semua request dari Seerr
            final tv     = all.where((r) => r.mediaType == MediaType.tv).toList();
            final movies = all.where((r) => r.mediaType == MediaType.movie).toList();

            return TabBarView(
              controller: _tab,
              children: [
                _RequestsBody(requests: seerr,  label: 'Seerr'),
                _RequestsBody(requests: tv,     label: 'Sonarr'),
                _RequestsBody(requests: movies, label: 'Radarr'),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final WidgetRef ref;
  const _ErrorView({required this.error, required this.ref});

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
            const Text('Cannot connect to Seerr',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.read(requestsProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Requests body (per tab) ───────────────────────────────────────────────────

class _RequestsBody extends ConsumerWidget {
  final List<MediaRequest> requests;
  final String label;
  const _RequestsBody({required this.requests, required this.label});

  List<MediaRequest> _filtered(List<MediaRequest> all, _StatusFilter f) {
    return switch (f) {
      _StatusFilter.all      => all,
      _StatusFilter.pending  => all.where((r) => r.status == RequestStatus.pending).toList(),
      _StatusFilter.approved => all.where((r) => r.status == RequestStatus.approved).toList(),
      _StatusFilter.available=> all.where((r) => r.status == RequestStatus.available).toList(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _RequestsBodyState(requests: requests);
  }
}

class _RequestsBodyState extends StatefulWidget {
  final List<MediaRequest> requests;
  const _RequestsBodyState({required this.requests});

  @override
  State<_RequestsBodyState> createState() => __RequestsBodyStateState();
}

class __RequestsBodyStateState extends State<_RequestsBodyState> {
  _StatusFilter _filter = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    // Counts
    final pending   = widget.requests.where((r) => r.status == RequestStatus.pending).length;
    final approved  = widget.requests.where((r) => r.status == RequestStatus.approved).length;
    final available = widget.requests.where((r) => r.status == RequestStatus.available).length;

    final filtered = switch (_filter) {
      _StatusFilter.all       => widget.requests,
      _StatusFilter.pending   => widget.requests.where((r) => r.status == RequestStatus.pending).toList(),
      _StatusFilter.approved  => widget.requests.where((r) => r.status == RequestStatus.approved).toList(),
      _StatusFilter.available => widget.requests.where((r) => r.status == RequestStatus.available).toList(),
    };

    return CustomScrollView(
      slivers: [
        // ── Status summary cards ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _CountCard(
                  label: 'Pending',
                  value: pending,
                  color: AppColors.warning,
                  selected: _filter == _StatusFilter.pending,
                  onTap: () => setState(() => _filter =
                      _filter == _StatusFilter.pending
                          ? _StatusFilter.all
                          : _StatusFilter.pending),
                ),
                const SizedBox(width: 10),
                _CountCard(
                  label: 'Approved',
                  value: approved,
                  color: AppColors.success,
                  selected: _filter == _StatusFilter.approved,
                  onTap: () => setState(() => _filter =
                      _filter == _StatusFilter.approved
                          ? _StatusFilter.all
                          : _StatusFilter.approved),
                ),
                const SizedBox(width: 10),
                _CountCard(
                  label: 'Available',
                  value: available,
                  color: AppColors.teal,
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

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Section: Pending requests ────────────────────────────────
        if (_filter == _StatusFilter.all || _filter == _StatusFilter.pending)
          ..._buildSection(
            context,
            title: 'Pending Requests',
            items: widget.requests
                .where((r) => r.status == RequestStatus.pending)
                .toList(),
          ),

        // ── Section: Recently Approved ───────────────────────────────
        if (_filter == _StatusFilter.all || _filter == _StatusFilter.approved)
          ..._buildSection(
            context,
            title: 'Recently Approved',
            items: widget.requests
                .where((r) => r.status == RequestStatus.approved)
                .toList(),
          ),

        // ── Section: Available ───────────────────────────────────────
        if (_filter == _StatusFilter.all || _filter == _StatusFilter.available)
          ..._buildSection(
            context,
            title: 'Available',
            items: widget.requests
                .where((r) => r.status == RequestStatus.available)
                .toList(),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  List<Widget> _buildSection(BuildContext context,
      {required String title, required List<MediaRequest> items}) {
    if (items.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _RequestCard(request: items[i]),
          childCount: items.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    ];
  }
}

enum _StatusFilter { all, pending, approved, available }

// ── Count card ────────────────────────────────────────────────────────────────

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CountCard({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  )),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends ConsumerWidget {
  final MediaRequest request;
  const _RequestCard({required this.request});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Poster ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: r.posterUrl().isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: r.posterUrl(),
                    width: 56,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56, height: 80,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.movie_outlined,
                          color: AppColors.textDisabled, size: 20),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56, height: 80,
                      color: AppColors.surfaceVariant,
                      child: Icon(
                        r.mediaType == MediaType.tv
                            ? Icons.tv_outlined
                            : Icons.movie_outlined,
                        color: AppColors.textDisabled,
                        size: 20,
                      ),
                    ),
                  )
                : Container(
                    width: 56, height: 80,
                    color: AppColors.surfaceVariant,
                    child: Icon(
                      r.mediaType == MediaType.tv
                          ? Icons.tv_outlined
                          : Icons.movie_outlined,
                      color: AppColors.textDisabled,
                      size: 20,
                    ),
                  ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(r.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),

                  // Year + type
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
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (r.year > 0) ...[
                        const SizedBox(width: 6),
                        Text('• ${r.year}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            )),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Requested by + time
                  Text(
                    'Requested by ${r.requestedBy}  •  ${_timeAgo(r.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // ── Status badge ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _StatusBadge(status: r.status),
          ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}
