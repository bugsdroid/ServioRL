import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/config_provider.dart';
import '../../core/theme/app_theme.dart';
import 'movie_model.dart';
import 'movies_provider.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg      = ref.watch(appConfigProvider);
    final notReady = cfg.radarrBaseUrl.isEmpty || cfg.radarrApiKey.isEmpty;
    final state    = ref.watch(filteredMoviesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: notReady
          ? _NotConfigured()
          : NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background,
                  title: state.whenOrNull(
                    data: (list) {
                      final all = ref.watch(moviesProvider).valueOrNull ?? [];
                      final dl  = all.where((m) => m.hasFile).length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Movies'),
                          Text(
                            '$dl / ${all.length} downloaded',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ) ?? const Text('Movies'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () =>
                          ref.read(moviesProvider.notifier).refresh(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort_rounded, size: 20),
                      onPressed: () => _showSortSheet(context, ref),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(100),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: TextField(
                            onChanged: (v) =>
                                ref.read(movieSearchProvider.notifier).state = v,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search library...',
                              prefixIcon: Icon(Icons.search,
                                  color: AppColors.textDisabled, size: 20),
                            ),
                          ),
                        ),
                        _FilterBar(),
                      ],
                    ),
                  ),
                ),
              ],
              body: state.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
                error: (e, _) => _ErrorView(
                  error: e.toString(),
                  onRetry: () => ref.read(moviesProvider.notifier).refresh(),
                ),
                data: (movies) => movies.isEmpty
                    ? const Center(
                        child: Text('Tidak ada film ditemukan',
                            style:
                                TextStyle(color: AppColors.textSecondary)))
                    : _MovieGrid(movies: movies),
              ),
            ),
    );
  }

  void _showSortSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(ref: ref),
    );
  }
}

// ── Not configured ────────────────────────────────────────────────────────────

class _NotConfigured extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Movies'),
      ),
      body: Center(
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
                child: const Icon(Icons.movie_outlined,
                    size: 40, color: AppColors.textDisabled),
              ),
              const SizedBox(height: 20),
              const Text(
                'Radarr belum dikonfigurasi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Isi Base URL dan API Key Radarr di Settings untuk melihat library film.',
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
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(movieFilterProvider);
    final all     = ref.watch(moviesProvider).valueOrNull ?? [];

    final counts = {
      MovieFilter.all:        all.length,
      MovieFilter.downloaded: all.where((m) => m.hasFile).length,
      MovieFilter.missing:    all.where((m) => !m.hasFile && m.monitored).length,
      MovieFilter.monitored:  all.where((m) => m.monitored).length,
    };

    const labels = {
      MovieFilter.all:        'All',
      MovieFilter.downloaded: 'Downloaded',
      MovieFilter.missing:    'Missing',
      MovieFilter.monitored:  'Monitored',
    };

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: MovieFilter.values.map((f) {
          final selected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${labels[f]} ${counts[f]}'),
              selected: selected,
              onSelected: (_) =>
                  ref.read(movieFilterProvider.notifier).state = f,
              selectedColor: AppColors.tealSurface,
              checkmarkColor: AppColors.teal,
              labelStyle: TextStyle(
                color: selected ? AppColors.teal : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Movie grid ────────────────────────────────────────────────────────────────

class _MovieGrid extends StatelessWidget {
  final List<Movie> movies;
  const _MovieGrid({required this.movies});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
      ),
      itemCount: movies.length,
      itemBuilder: (ctx, i) => _MoviePoster(movie: movies[i]),
    );
  }
}

class _MoviePoster extends StatelessWidget {
  final Movie movie;
  const _MoviePoster({required this.movie});

  @override
  Widget build(BuildContext context) {
    final m = movie;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  m.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: m.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceVariant),
                          errorWidget: (_, __, ___) => _posterFallback(m),
                        )
                      : _posterFallback(m),
                  if (m.hasFile)
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 12, 5, 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          m.quality,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (!m.hasFile && m.monitored)
                    Positioned(
                      top: 5, right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Missing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            m.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            m.year > 0 ? m.year.toString() : '',
            style: const TextStyle(
                color: AppColors.textDisabled, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _posterFallback(Movie m) => Container(
        color: AppColors.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined,
                color: AppColors.textDisabled, size: 28),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                m.title,
                style: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
}

// ── Sort sheet ────────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final WidgetRef ref;
  const _SortSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(movieSortProvider);
    const options = {
      MovieSort.title:  'Title (A–Z)',
      MovieSort.year:   'Year (newest)',
      MovieSort.size:   'Size (largest)',
      MovieSort.rating: 'Rating (highest)',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort by',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...MovieSort.values.map((s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  options[s]!,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                trailing: s == current
                    ? const Icon(Icons.check, color: AppColors.teal)
                    : null,
                onTap: () {
                  ref.read(movieSortProvider.notifier).state = s;
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal terhubung ke Radarr',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// MOVIE DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class MovieDetailScreen extends ConsumerWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = movie;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  m.fanartUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: m.fanartUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceVariant),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.surfaceVariant),
                        )
                      : Container(color: AppColors.surfaceVariant),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showActions(context, ref, m),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  m.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    if (m.year > 0) _meta(m.year.toString()),
                    _meta(m.status.label),
                    if (m.runtimeStr.isNotEmpty) _meta(m.runtimeStr),
                    if (m.ratings > 0)
                      _meta('⭐ ${m.ratings.toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (m.hasFile)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tealSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.teal, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '${m.quality}  •  ${m.sizeStr}',
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (m.monitored)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Missing',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.search_rounded, size: 16),
                        label: const Text('Interactive Search'),
                        onPressed: () =>
                            _openInteractiveSearch(context, ref, m),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.manage_search_rounded,
                            size: 16),
                        label: const Text('Auto Search'),
                        onPressed: () async {
                          await ref
                              .read(moviesProvider.notifier)
                              .searchMovie(m.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Auto search dimulai untuk ${m.title}'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (m.genres.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: m.genres
                        .map((g) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.border, width: 0.5),
                              ),
                              child: Text(
                                g,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (m.overview.isNotEmpty) ...[
                  const Text(
                    'Overview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.overview,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
                if (m.studio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Studio: ${m.studio}',
                    style: const TextStyle(
                        color: AppColors.textDisabled, fontSize: 12),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String text) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
      );

  void _openInteractiveSearch(
      BuildContext context, WidgetRef ref, Movie m) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => InteractiveSearchScreen(movie: m)),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, Movie m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MovieActionsSheet(movie: m, ref: ref),
    );
  }
}

// ── Movie actions sheet ───────────────────────────────────────────────────────

class _MovieActionsSheet extends StatelessWidget {
  final Movie movie;
  final WidgetRef ref;
  const _MovieActionsSheet({required this.movie, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.search_rounded, color: AppColors.teal),
            title: const Text('Interactive Search',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        InteractiveSearchScreen(movie: movie)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            title: const Text('Hapus Film',
                style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Hapus Film?'),
                  content: Text(movie.title),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref
                    .read(movieRepositoryProvider)
                    .deleteMovie(movie.id);
                await ref.read(moviesProvider.notifier).refresh();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INTERACTIVE SEARCH SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class InteractiveSearchScreen extends ConsumerWidget {
  final Movie movie;
  const InteractiveSearchScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interactiveSearchProvider(movie.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interactive Search'),
            Text(
              movie.title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: state.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_rounded,
                    size: 48, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                Text(
                  'Gagal: $e',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (releases) {
          if (releases.isEmpty) {
            return const Center(
              child: Text('Tidak ada release ditemukan',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: releases.length,
            itemBuilder: (ctx, i) => _ReleaseCard(
              release: releases[i],
              movie: movie,
              ref: ref,
            ),
          );
        },
      ),
    );
  }
}

// ── Release card ──────────────────────────────────────────────────────────────

class _ReleaseCard extends StatefulWidget {
  final RadarrRelease release;
  final Movie movie;
  final WidgetRef ref;
  const _ReleaseCard(
      {required this.release, required this.movie, required this.ref});

  @override
  State<_ReleaseCard> createState() => _ReleaseCardState();
}

class _ReleaseCardState extends State<_ReleaseCard> {
  bool _loading = false;
  bool _grabbed = false;

  Future<void> _grab() async {
    if (_loading || _grabbed) return;
    setState(() => _loading = true);
    try {
      await widget.ref
          .read(movieRepositoryProvider)
          .grabRelease(widget.release.guid, 0);
      setState(() {
        _loading = false;
        _grabbed = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Release berhasil di-grab!')),
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
    final r = widget.release;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: r.rejected
            ? AppColors.card.withOpacity(0.5)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: r.rejected
              ? AppColors.border.withOpacity(0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  r.title,
                  style: TextStyle(
                    color: r.rejected
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!r.rejected)
                GestureDetector(
                  onTap: _grab,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _grabbed
                          ? AppColors.surfaceVariant
                          : AppColors.teal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background),
                          )
                        : Text(
                            _grabbed ? 'Grabbed' : 'Grab',
                            style: TextStyle(
                              color: _grabbed
                                  ? AppColors.textSecondary
                                  : AppColors.background,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _stat(Icons.high_quality_rounded, r.quality, AppColors.teal),
              if (r.sizeStr.isNotEmpty)
                _stat(Icons.storage_rounded, r.sizeStr,
                    AppColors.textSecondary),
              _stat(
                Icons.arrow_upward_rounded,
                '${r.seeders}',
                r.seeders > 5
                    ? AppColors.success
                    : r.seeders > 0
                        ? AppColors.warning
                        : AppColors.error,
              ),
              _stat(Icons.schedule_rounded, '${r.age}d',
                  AppColors.textSecondary),
              _stat(Icons.source_rounded, r.indexer,
                  AppColors.textDisabled),
            ],
          ),
          if (r.rejections.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.rejections.join(' • '),
              style:
                  const TextStyle(color: AppColors.error, fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
