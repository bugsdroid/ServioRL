import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.explore_outlined,   activeIcon: Icons.explore,   label: 'Discover',  path: '/discover'),
    (icon: Icons.movie_outlined,     activeIcon: Icons.movie,     label: 'Movies',    path: '/movies'),
    (icon: Icons.tv_outlined,        activeIcon: Icons.tv,        label: 'TV',        path: '/tv'),
    (icon: Icons.download_outlined,  activeIcon: Icons.download,  label: 'Downloads', path: '/downloads'),
    (icon: Icons.subtitles_outlined, activeIcon: Icons.subtitles, label: 'Subtitles', path: '/subtitles'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx < 0 ? 0 : idx,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
