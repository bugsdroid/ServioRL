import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/serviorl_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: const ServioRLLogo(),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SystemStatus(),
                const SizedBox(height: 20),
                _SectionLabel('Overview'),
                const SizedBox(height: 10),
                _ServiceGrid(),
                const SizedBox(height: 24),
                _SectionHeader(label: 'Activity', onTap: () {}),
                const SizedBox(height: 10),
                _ActivityList(),
                const SizedBox(height: 24),
                _SectionLabel('Download Overview'),
                const SizedBox(height: 10),
                _DownloadOverview(),
                const SizedBox(height: 20),
                _StorageBar(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tealSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text('All systems operational',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleMedium);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SectionHeader({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Text('View all',
                  style: TextStyle(color: AppColors.teal, fontSize: 13)),
            ),
        ],
      );
}

// ── Service grid: Seerr / Sonarr / Radarr / Transmission ─────────────────────

class _ServiceGrid extends StatelessWidget {
  static const _services = [
    (name: 'Seerr',        icon: Icons.explore_rounded,   color: AppColors.teal),
    (name: 'Sonarr',       icon: Icons.tv_rounded,         color: Color(0xFF2196F3)),
    (name: 'Radarr',       icon: Icons.movie_rounded,      color: Color(0xFFFF9800)),
    (name: 'Transmission', icon: Icons.download_rounded,   color: Color(0xFF9C27B0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _services.map((s) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ServiceCard(name: s.name, icon: s.icon, color: s.color),
        ),
      )).toList(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  const _ServiceCard({required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              const Text('Online',
                  style: TextStyle(color: AppColors.success, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  static const _items = [
    (title: 'Dune: Part Two',    subtitle: 'Movie downloaded',   time: '2m ago',  icon: Icons.movie_rounded),
    (title: 'The Boys S04E06',   subtitle: 'Episode downloaded', time: '5m ago',  icon: Icons.tv_rounded),
    (title: 'Oppenheimer',       subtitle: 'Added to Radarr',    time: '12m ago', icon: Icons.add_circle_outline_rounded),
    (title: 'Foundation S02E03', subtitle: 'Episode downloaded', time: '18m ago', icon: Icons.tv_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 18, color: AppColors.teal),
                ),
                title: Text(item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    )),
                subtitle: Text(item.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    )),
                trailing: Text(item.time,
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    )),
              ),
              if (i < _items.length - 1)
                const Divider(height: 0, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class _DownloadOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'Downloading', value: '8',  color: AppColors.teal),
        const SizedBox(width: 10),
        _StatCard(label: 'Seeding',     value: '24', color: AppColors.success),
        const SizedBox(width: 10),
        _StatCard(label: 'Paused',      value: '2',  color: AppColors.warning),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
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
    );
  }
}

class _StorageBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const used = 1.2;
    const total = 2.0;
    const pct = used / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Storage',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
              Text('${(pct * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text('${used}TB / ${total}TB used',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}
