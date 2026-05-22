import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined,     activeIcon: Icons.home_rounded,      label: 'Home',      path: '/home'),
    (icon: Icons.download_outlined, activeIcon: Icons.download_rounded,  label: 'Downloads', path: '/downloads'),
    (icon: Icons.inbox_outlined,    activeIcon: Icons.inbox_rounded,     label: 'Requests',  path: '/requests'),
    (icon: Icons.search_outlined,   activeIcon: Icons.search_rounded,    label: 'Search',    path: '/search'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded,  label: 'Settings',  path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: NavigationBar(
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
      ),
    );
  }
}
