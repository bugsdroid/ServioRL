import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Movies ──────────────────────────────────────────────────
          _LibraryCard(
            icon: Icons.movie_rounded,
            color: const Color(0xFFFF9800),
            title: 'Movies',
            subtitle: 'Browse & manage Radarr library',
            onTap: () => context.push('/movies'),
          ),
          const SizedBox(height: 12),

          // ── TV Series ───────────────────────────────────────────────
          _LibraryCard(
            icon: Icons.tv_rounded,
            color: const Color(0xFF2196F3),
            title: 'TV Series',
            subtitle: 'Browse & manage Sonarr library',
            onTap: () => context.push('/tv'),
          ),
          const SizedBox(height: 12),

          // ── Subtitles ───────────────────────────────────────────────
          _LibraryCard(
            icon: Icons.subtitles_rounded,
            color: const Color(0xFFE91E63),
            title: 'Subtitles',
            subtitle: 'Find missing subtitles via Bazarr',
            onTap: () => context.push('/subtitles'),
          ),
          const SizedBox(height: 32),

          // ── Settings shortcut ───────────────────────────────────────
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          _LibraryCard(
            icon: Icons.settings_rounded,
            color: AppColors.textSecondary,
            title: 'Settings',
            subtitle: 'Configure service connections',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LibraryCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
