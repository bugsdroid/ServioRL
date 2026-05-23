import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'subtitle_model.dart';
import 'subtitles_provider.dart';

// ── Language options yang sering dipakai ──────────────────────────────────────
const _kLanguages = [
  (code: 'en', name: 'English'),
  (code: 'id', name: 'Indonesian'),
  (code: 'zh', name: 'Chinese'),
  (code: 'ja', name: 'Japanese'),
  (code: 'ko', name: 'Korean'),
  (code: 'es', name: 'Spanish'),
  (code: 'fr', name: 'French'),
  (code: 'de', name: 'German'),
];

// ══════════════════════════════════════════════════════════════════════════════
// SUBTITLES SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SubtitlesScreen extends ConsumerWidget {
  const SubtitlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredSubtitlesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: state.whenOrNull(
              data: (list) {
                final all = ref.watch(missingSubtitlesProvider).valueOrNull ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subtitles'),
                    Text('${all.length} missing',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                );
              },
            ) ?? const Text('Subtitles'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () =>
                    ref.read(missingSubtitlesProvider.notifier).refresh(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: _FilterBar(),
            ),
          ),
        ],
        body: state.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.teal)),
          error: (e, _) => _ErrorView(error: e.toString(), ref: ref),
          data: (items) => items.isEmpty
              ? _EmptyView()
              : _SubtitleList(items: items),
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(subtitleFilterProvider);
    final all     = ref.watch(missingSubtitlesProvider).valueOrNull ?? [];

    final counts = {
      SubtitleFilter.all:      all.length,
      SubtitleFilter.movies:   all.where((i) => i.isMovie).length,
      SubtitleFilter.episodes: all.where((i) => !i.isMovie).length,
    };

    const labels = {
      SubtitleFilter.all:      'All',
      SubtitleFilter.movies:   'Movies',
      SubtitleFilter.episodes: 'Episodes',
    };

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: SubtitleFilter.values.map((f) {
          final selected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${labels[f]} ${counts[f]}'),
              selected: selected,
              onSelected: (_) =>
                  ref.read(subtitleFilterProvider.notifier).state = f,
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

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.tealSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.subtitles_rounded,
                  size: 48, color: AppColors.teal),
            ),
            const SizedBox(height: 20),
            const Text('All subtitles complete!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            const Text('No missing subtitles found.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
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
              const Text('Cannot connect to Bazarr',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
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
                    ref.read(missingSubtitlesProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      );
}

// ── Subtitle list ─────────────────────────────────────────────────────────────

class _SubtitleList extends StatelessWidget {
  final List<SubtitleItem> items;
  const _SubtitleList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _SubtitleCard(item: items[i]),
    );
  }
}

// ── Subtitle card ─────────────────────────────────────────────────────────────

class _SubtitleCard extends ConsumerWidget {
  final SubtitleItem item;
  const _SubtitleCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = item;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: s.isMovie
                      ? const Color(0xFFFF9800).withOpacity(0.15)
                      : const Color(0xFF2196F3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  s.isMovie ? Icons.movie_rounded : Icons.tv_rounded,
                  size: 16,
                  color: s.isMovie
                      ? const Color(0xFFFF9800)
                      : const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.displayTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    // Missing languages
                    Row(
                      children: [
                        const Icon(Icons.subtitles_off_rounded,
                            size: 12, color: AppColors.error),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Missing: ${s.missing}',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Action buttons ─────────────────────────────────────────
          Row(
            children: [
              // Auto search
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                  label: const Text('Auto Search'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _autoSearch(context, ref, s),
                ),
              ),
              const SizedBox(width: 8),
              // Manual search
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.search_rounded, size: 14),
                  label: const Text('Manual Search'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _openManualSearch(context, s),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _autoSearch(
      BuildContext context, WidgetRef ref, SubtitleItem s) async {
    final repo = ref.read(subtitleRepositoryProvider);
    try {
      if (s.isMovie) {
        await repo.autoSearchMovie(s.radarrId);
      } else {
        await repo.autoSearchEpisode(s.sonarrEpisodeId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto search started')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openManualSearch(BuildContext context, SubtitleItem s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LanguagePickerSheet(item: s),
    );
  }
}

// ── Language picker sheet ─────────────────────────────────────────────────────

class _LanguagePickerSheet extends StatelessWidget {
  final SubtitleItem item;
  const _LanguagePickerSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Select Language',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Text(item.displayTitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          ..._kLanguages.map((lang) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(lang.code.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
                title: Text(lang.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textDisabled, size: 18),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubtitleSearchScreen(
                        item:     item,
                        language: lang.code,
                        languageName: lang.name,
                      ),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUBTITLE SEARCH SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SubtitleSearchScreen extends ConsumerWidget {
  final SubtitleItem item;
  final String language;
  final String languageName;

  const SubtitleSearchScreen({
    super.key,
    required this.item,
    required this.language,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaId = item.isMovie ? item.radarrId : item.sonarrEpisodeId;
    final args = (
      mediaId:  mediaId,
      language: language,
      isMovie:  item.isMovie,
    );
    final state = ref.watch(subtitleSearchProvider(args));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$languageName Subtitles'),
            Text(item.displayTitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: state.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.textDisabled),
              const SizedBox(height: 12),
              Text('Search failed: $e',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (results) {
          if (results.isEmpty) {
            return const Center(
              child: Text('No subtitles found',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: results.length,
            itemBuilder: (ctx, i) => _SubtitleResultCard(
              result: results[i],
              item:   item,
              language: language,
            ),
          );
        },
      ),
    );
  }
}

// ── Subtitle result card ──────────────────────────────────────────────────────

class _SubtitleResultCard extends ConsumerStatefulWidget {
  final SubtitleResult result;
  final SubtitleItem item;
  final String language;
  const _SubtitleResultCard({
    required this.result,
    required this.item,
    required this.language,
  });

  @override
  ConsumerState<_SubtitleResultCard> createState() =>
      _SubtitleResultCardState();
}

class _SubtitleResultCardState
    extends ConsumerState<_SubtitleResultCard> {
  bool _loading = false;
  bool _done    = false;

  Future<void> _download() async {
    if (_loading || _done) return;
    setState(() => _loading = true);

    final repo = ref.read(subtitleRepositoryProvider);
    final r    = widget.result;
    final item = widget.item;

    try {
      if (item.isMovie) {
        await repo.downloadMovieSubtitle(
          radarrId:   item.radarrId,
          language:   widget.language,
          subtitleId: r.id,
          provider:   r.provider,
        );
      } else {
        await repo.downloadEpisodeSubtitle(
          episodeId:  item.sonarrEpisodeId,
          language:   widget.language,
          subtitleId: r.id,
          provider:   r.provider,
        );
      }
      setState(() { _loading = false; _done = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subtitle downloaded!')),
        );
        // Refresh missing list
        ref.read(missingSubtitlesProvider.notifier).refresh();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Release name + download button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(r.release.isNotEmpty ? r.release : r.url,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _download,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _done
                        ? AppColors.surfaceVariant
                        : AppColors.teal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background))
                      : Text(
                          _done ? 'Downloaded' : 'Download',
                          style: TextStyle(
                            color: _done
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

          // Stats
          Wrap(
            spacing: 12,
            children: [
              // Score
              _stat(Icons.stars_rounded, r.scoreStr,
                  r.score > 0.8
                      ? AppColors.teal
                      : r.score > 0.5
                          ? AppColors.warning
                          : AppColors.textSecondary),
              // Provider
              _stat(Icons.source_rounded, r.provider,
                  AppColors.textSecondary),
              // Format
              if (r.format.isNotEmpty)
                _stat(Icons.description_outlined, r.format.toUpperCase(),
                    AppColors.textDisabled),
              // HI
              if (r.hearingImpaired)
                _stat(Icons.hearing_rounded, 'HI', AppColors.info),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      );
}
