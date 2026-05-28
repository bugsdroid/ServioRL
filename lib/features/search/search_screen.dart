import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/config_provider.dart';
import '../../core/theme/app_theme.dart';
import 'search_model.dart';
import 'search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String q) {
    if (q.trim().isEmpty) return;
    ref.read(searchQueryProvider.notifier).state = q.trim();
    _focus.unfocus();
  }

  void _clear() {
    _ctrl.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isMovie = ref.watch(searchIsMovieProvider);
    final query   = ref.watch(searchQueryProvider);
    final cfg     = ref.watch(appConfigProvider);
    final seerrOk = cfg.seerrBaseUrl.isNotEmpty && cfg.seerrApiKey.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Search'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:  _ctrl,
                    focusNode:   _focus,
                    onSubmitted: _submit,
                    enabled: seerrOk,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: seerrOk
                          ? 'Search movies, series...'
                          : 'Configure Seerr in Settings first',
                      prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textDisabled,
                          size: 20),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: AppColors.textDisabled, size: 18),
                              onPressed: _clear,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Not configured warning ───────────────────────────────────
          if (!seerrOk)
            _NotConfiguredBanner(),

          // ── Movie / Series toggle ────────────────────────────────────
          if (seerrOk)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _ToggleBtn(
                    label: 'Movies',
                    selected: isMovie,
                    onTap: () {
                      ref.read(searchIsMovieProvider.notifier).state = true;
                      if (query.isNotEmpty) {
                        // re-trigger search
                        ref.read(searchQueryProvider.notifier).state = query;
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _ToggleBtn(
                    label: 'Series',
                    selected: !isMovie,
                    onTap: () {
                      ref.read(searchIsMovieProvider.notifier).state = false;
                      if (query.isNotEmpty) {
                        ref.read(searchQueryProvider.notifier).state = query;
                      }
                    },
                  ),
                ],
              ),
            ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: !seerrOk
                ? const SizedBox.shrink()
                : query.isNotEmpty
                    ? _SearchResults()
                    : _SearchHome(
                        onPopular: (q) {
                          _ctrl.text = q;
                          _submit(q);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Not configured banner ─────────────────────────────────────────────────────

class _NotConfiguredBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Center(
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
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seerr belum dikonfigurasi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Isi Base URL dan API Key Seerr di Settings untuk mulai mencari dan request film/series.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: const Text('Buka Settings'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle button ─────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.background
                : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Search home (popular + trending) ─────────────────────────────────────────

class _SearchHome extends ConsumerWidget {
  final void Function(String) onPopular;

  static const _popular = [
    'Dune Part Two',
    'Oppenheimer',
    'John Wick 4',
    'Avengers',
    'Avatar',
    'Interstellar',
  ];

  const _SearchHome({required this.onPopular});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingMovies = ref.watch(trendingMoviesProvider);
    final trendingTv     = ref.watch(trendingTvProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // ── Popular searches ───────────────────────────────────────────
        const Text(
          'Popular Searches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popular
              .map((q) => GestureDetector(
                    onTap: () => onPopular(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.border, width: 0.5),
                      ),
                      child: Text(
                        q,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 28),

        // ── Trending Movies ────────────────────────────────────────────
        _SectionHeader(title: 'Trending Movies'),
        const SizedBox(height: 12),
        trendingMovies.when(
          loading: () => const _PosterGridSkeleton(),
          error: (e, _) => _GridError(
            message: 'Tidak bisa load trending — $e',
          ),
          data: (list) => list.isEmpty
              ? const _GridError(message: 'Tidak ada data trending')
              : _PosterGrid(items: list),
        ),

        const SizedBox(height: 28),

        // ── Trending Series ────────────────────────────────────────────
        _SectionHeader(title: 'Trending Series'),
        const SizedBox(height: 12),
        trendingTv.when(
          loading: () => const _PosterGridSkeleton(),
          error: (e, _) => _GridError(
            message: 'Tidak bisa load trending — $e',
          ),
          data: (list) => list.isEmpty
              ? const _GridError(message: 'Tidak ada data trending')
              : _PosterGrid(items: list),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
}

// ── Poster grid ───────────────────────────────────────────────────────────────

class _PosterGrid extends ConsumerWidget {
  final List<SearchResult> items;
  const _PosterGrid({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _PosterCard(item: items[i]),
      ),
    );
  }
}

class _PosterCard extends ConsumerWidget {
  final SearchResult item;
  const _PosterCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDetail(context, item, ref),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.posterUrl().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.posterUrl(),
                      width: 100,
                      height: 130,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _skeleton(),
                      errorWidget: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
            const SizedBox(height: 5),
            Text(
              item.title,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.year > 0)
              Text(
                item.year.toString(),
                style: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _skeleton() => Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _fallback() => Container(
        width: 100,
        height: 130,
        color: AppColors.surfaceVariant,
        child: Icon(
          item.mediaType == MediaType.tv
              ? Icons.tv_outlined
              : Icons.movie_outlined,
          color: AppColors.textDisabled,
          size: 28,
        ),
      );

  void _showDetail(BuildContext context, SearchResult item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _DetailSheet(item: item, ref: ref),
    );
  }
}

class _PosterGridSkeleton extends StatelessWidget {
  const _PosterGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 100,
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _GridError extends StatelessWidget {
  final String message;
  const _GridError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Search results ────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchResultsProvider);

    return state.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.teal)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Gagal terhubung ke Seerr',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e.toString(),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada hasil ditemukan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: results.length,
          itemBuilder: (ctx, i) => _SearchResultCard(item: results[i]),
        );
      },
    );
  }
}

// ── Search result card ────────────────────────────────────────────────────────

class _SearchResultCard extends ConsumerWidget {
  final SearchResult item;
  const _SearchResultCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = item;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isScrollControlled: true,
        builder: (_) => _DetailSheet(item: r, ref: ref),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: r.posterUrl().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: r.posterUrl('w92'),
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 56,
                          height: 80,
                          color: AppColors.surfaceVariant),
                      errorWidget: (_, __, ___) => Container(
                          width: 56,
                          height: 80,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.movie_outlined,
                              color: AppColors.textDisabled, size: 20)),
                    )
                  : Container(
                      width: 56,
                      height: 80,
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

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (r.year > 0)
                          Text(
                            '${r.year}  •  ',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            r.mediaType == MediaType.tv
                                ? 'Series'
                                : 'Movie',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10),
                          ),
                        ),
                        if (r.voteAverage > 0) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 12),
                          Text(
                            ' ${r.voteAverage.toStringAsFixed(1)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    if (r.overview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        r.overview,
                        style: const TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Request button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _RequestBtn(item: r),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request button ────────────────────────────────────────────────────────────

class _RequestBtn extends ConsumerStatefulWidget {
  final SearchResult item;
  const _RequestBtn({required this.item});

  @override
  ConsumerState<_RequestBtn> createState() => _RequestBtnState();
}

class _RequestBtnState extends ConsumerState<_RequestBtn> {
  bool _loading = false;
  bool _done    = false;

  Future<void> _request() async {
    if (_loading || _done || widget.item.alreadyRequested) return;
    setState(() => _loading = true);
    try {
      await ref.read(searchRepositoryProvider).requestMedia(
            widget.item.id,
            widget.item.mediaTypeStr,
          );
      setState(() {
        _loading = false;
        _done    = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.item.title} requested!')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.item;

    if (r.mediaAvailable) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.tealSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Available',
          style: TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      );
    }

    if (r.alreadyRequested || _done) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Requested',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      );
    }

    return GestureDetector(
      onTap: _request,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.background),
              )
            : const Text(
                'Request',
                style: TextStyle(
                    color: AppColors.background,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final SearchResult item;
  final WidgetRef ref;
  const _DetailSheet({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final r = item;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Backdrop
            if (r.backdropUrl().isNotEmpty)
              CachedNetworkImage(
                imageUrl: r.backdropUrl(),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 100,
                  child: ColoredBox(color: AppColors.surfaceVariant),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    r.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Meta
                  Row(
                    children: [
                      if (r.year > 0)
                        Text(
                          '${r.year}  •  ',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      Text(
                        r.mediaType == MediaType.tv
                            ? 'Series'
                            : 'Movie',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13),
                      ),
                      if (r.voteAverage > 0) ...[
                        const Text('  •  ',
                            style: TextStyle(
                                color: AppColors.textSecondary)),
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        Text(
                          ' ${r.voteAverage.toStringAsFixed(1)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(child: _RequestBtn(item: r)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Overview
                  if (r.overview.isNotEmpty) ...[
                    const Text(
                      'Overview',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.overview,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
