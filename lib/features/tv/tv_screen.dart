import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/config_provider.dart';
import '../../core/theme/app_theme.dart';
import 'tv_model.dart';
import 'tv_provider.dart';

class TvScreen extends ConsumerWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg      = ref.watch(appConfigProvider);
    final notReady = cfg.sonarrBaseUrl.isEmpty || cfg.sonarrApiKey.isEmpty;
    final state    = ref.watch(filteredTvProvider);

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
                      final all = ref.watch(tvSeriesProvider).valueOrNull ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TV Series'),
                          Text(
                            '${all.length} series',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      );
                    },
                  ) ?? const Text('TV Series'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () =>
                          ref.read(tvSeriesProvider.notifier).refresh(),
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
                                ref.read(tvSearchProvider.notifier).state = v,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search series...',
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
                error: (e, _) => _ErrorView(error: e.toString(), ref: ref),
                data: (series) => series.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada series ditemukan',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : _SeriesGrid(series: series),
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
        title: const Text('TV Series'),
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
                child: const Icon(Icons.tv_outlined,
                    size: 40, color: AppColors.textDisabled),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sonarr belum dikonfigurasi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Isi Base URL dan API Key Sonarr di Settings untuk melihat library series.',
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
                onPressed: () =>
                    Navigator.of(context).pushNamed('/settings'),
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
    final current = ref.watch(tvFilterProvider);
    final all     = ref.watch(tvSeriesProvider).valueOrNull ?? [];

    final counts = {
      TvFilter.all:        all.length,
      TvFilter.continuing: all.where((s) => s.status == SeriesStatus.continuing).length,
      TvFilter.ended:      all.where((s) => s.status == SeriesStatus.ended).length,
      TvFilter.missing:    all.where((s) => s.missingEpisodes > 0 && s.monitored).length,
      TvFilter.monitored:  all.where((s) => s.monitored).length,
    };

    const labels = {
      TvFilter.all:        'All',
      TvFilter.continuing: 'Airing',
      TvFilter.ended:      'Ended',
      TvFilter.missing:    'Missing',
      TvFilter.monitored:  'Monitored',
    };

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: TvFilter.values.map((f) {
          final selected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${labels[f]} ${counts[f]}'),
              selected: selected,
              onSelected: (_) =>
                  ref.read(tvFilterProvider.notifier).state = f,
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

// ── Series grid ───────────────────────────────────────────────────────────────

class _SeriesGrid extends StatelessWidget {
  final List<TvSeries> series;
  const _SeriesGrid({required this.series});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
      ),
      itemCount: series.length,
      itemBuilder: (ctx, i) => _SeriesPoster(series: series[i]),
    );
  }
}

class _SeriesPoster extends StatelessWidget {
  final TvSeries series;
  const _SeriesPoster({required this.series});

  @override
  Widget build(BuildContext context) {
    final s = series;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TvDetailScreen(series: s)),
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
                  s.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: s.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceVariant),
                          errorWidget: (_, __, ___) => _fallback(s),
                        )
                      : _fallback(s),

                  // Progress bar
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Column(
                      children: [
                        if (s.missingEpisodes > 0 && s.monitored)
                          Container(
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(
                                bottom: 3, right: 3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${s.missingEpisodes}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        LinearProgressIndicator(
                          value: s.progressPct,
                          minHeight: 3,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            s.missingEpisodes > 0
                                ? AppColors.warning
                                : AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ON AIR badge
                  if (s.status == SeriesStatus.continuing)
                    Positioned(
                      top: 5, left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ON AIR',
                          style: TextStyle(
                            color: AppColors.background,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
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
            s.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            s.progressStr,
            style: const TextStyle(
                color: AppColors.textDisabled, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _fallback(TvSeries s) => Container(
        color: AppColors.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv_outlined,
                color: AppColors.textDisabled, size: 28),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                s.title,
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
    final current = ref.watch(tvSortProvider);
    const options = {
      TvSort.title:    'Title (A–Z)',
      TvSort.year:     'Year (newest)',
      TvSort.episodes: 'Episodes (most)',
      TvSort.network:  'Network (A–Z)',
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
          ...TvSort.values.map((s) => ListTile(
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
                  ref.read(tvSortProvider.notifier).state = s;
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
  final WidgetRef ref;
  const _ErrorView({required this.error, required this.ref});

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
                'Gagal terhubung ke Sonarr',
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
                onPressed: () =>
                    ref.read(tvSeriesProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// TV DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class TvDetailScreen extends ConsumerWidget {
  final TvSeries series;
  const TvDetailScreen({super.key, required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = series;

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
                  s.fanartUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: s.fanartUrl,
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
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  s.title,
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
                    if (s.year > 0) _meta(s.year.toString()),
                    _meta(s.status.label),
                    if (s.network.isNotEmpty) _meta(s.network),
                    if (s.runtimeStr.isNotEmpty) _meta(s.runtimeStr),
                    if (s.ratings > 0)
                      _meta('⭐ ${s.ratings.toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: s.progressPct,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                s.missingEpisodes > 0
                                    ? AppColors.warning
                                    : AppColors.teal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.progressStr,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (s.missingEpisodes > 0) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${s.missingEpisodes} missing',
                          style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Genres
                if (s.genres.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.genres
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

                // Overview
                if (s.overview.isNotEmpty) ...[
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
                    s.overview,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Seasons
                const Text(
                  'Seasons',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(s.seasonCount, (i) {
                  final seasonNum = s.seasonCount - i;
                  return _SeasonTile(
                      series: s, seasonNumber: seasonNum);
                }),
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
}

// ── Season tile ───────────────────────────────────────────────────────────────

class _SeasonTile extends StatefulWidget {
  final TvSeries series;
  final int seasonNumber;
  const _SeasonTile(
      {required this.series, required this.seasonNumber});

  @override
  State<_SeasonTile> createState() => _SeasonTileState();
}

class _SeasonTileState extends State<_SeasonTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'S${widget.seasonNumber}',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Season ${widget.seasonNumber}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Consumer(builder: (ctx, ref, _) {
                    return IconButton(
                      icon: const Icon(Icons.search_rounded,
                          size: 18, color: AppColors.textSecondary),
                      tooltip: 'Search season',
                      onPressed: () async {
                        await ref
                            .read(tvRepositoryProvider)
                            .searchSeason(
                              widget.series.id,
                              widget.seasonNumber,
                            );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Searching Season ${widget.seasonNumber}...'),
                            ),
                          );
                        }
                      },
                    );
                  }),
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
          if (_expanded)
            Consumer(builder: (ctx, ref, _) {
              final state = ref.watch(episodeProvider((
                seriesId:     widget.series.id,
                seasonNumber: widget.seasonNumber,
              )));
              return state.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.teal, strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 12),
                  ),
                ),
                data: (episodes) => Column(
                  children: [
                    const Divider(
                        height: 0, indent: 14, endIndent: 14),
                    ...episodes.map((ep) => _EpisodeTile(
                          episode: ep,
                          series:  widget.series,
                        )),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Episode tile ──────────────────────────────────────────────────────────────

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final TvSeries series;
  const _EpisodeTile(
      {required this.episode, required this.series});

  @override
  Widget build(BuildContext context) {
    final ep = episode;
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ep.hasFile
              ? AppColors.tealSurface
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            'E${ep.episodeNumber.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: ep.hasFile
                  ? AppColors.teal
                  : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        ep.title,
        style: TextStyle(
          color: ep.hasFile
              ? AppColors.textPrimary
              : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: ep.quality.isNotEmpty
          ? Text(ep.quality,
              style: const TextStyle(
                  color: AppColors.teal, fontSize: 11))
          : ep.airDate != null
              ? Text(
                  '${ep.airDate!.day}/${ep.airDate!.month}/${ep.airDate!.year}',
                  style: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 11),
                )
              : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ep.hasFile
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: ep.hasFile
                ? AppColors.teal
                : AppColors.textDisabled,
            size: 16,
          ),
          const SizedBox(width: 4),
          Consumer(builder: (ctx, ref, _) {
            return IconButton(
              icon: const Icon(Icons.search_rounded,
                  size: 16, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Interactive search',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TvInteractiveSearchScreen(
                    episode: ep,
                    series:  series,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TV INTERACTIVE SEARCH SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class TvInteractiveSearchScreen extends ConsumerWidget {
  final Episode episode;
  final TvSeries series;
  const TvInteractiveSearchScreen(
      {super.key, required this.episode, required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tvInteractiveSearchProvider(episode.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interactive Search'),
            Text(
              '${series.title} · ${episode.code}',
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
              child: Text(
                'Tidak ada release ditemukan',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: releases.length,
            itemBuilder: (ctx, i) =>
                _TvReleaseCard(release: releases[i], ref: ref),
          );
        },
      ),
    );
  }
}

// ── TV Release card ───────────────────────────────────────────────────────────

class _TvReleaseCard extends StatefulWidget {
  final SonarrRelease release;
  final WidgetRef ref;
  const _TvReleaseCard({required this.release, required this.ref});

  @override
  State<_TvReleaseCard> createState() => _TvReleaseCardState();
}

class _TvReleaseCardState extends State<_TvReleaseCard> {
  bool _loading = false;
  bool _grabbed = false;

  Future<void> _grab() async {
    if (_loading || _grabbed) return;
    setState(() => _loading = true);
    try {
      await widget.ref
          .read(tvRepositoryProvider)
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
              _stat(Icons.high_quality_rounded, r.quality,
                  AppColors.teal),
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
              style: const TextStyle(
                  color: AppColors.error, fontSize: 10),
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
