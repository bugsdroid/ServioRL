import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_shell.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/movies/movies_screen.dart';
import '../../features/tv/tv_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/subtitles/subtitles_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/discover',
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/discover',  builder: (c, s) => const DiscoverScreen()),
          GoRoute(path: '/movies',    builder: (c, s) => const MoviesScreen()),
          GoRoute(path: '/tv',        builder: (c, s) => const TvScreen()),
          GoRoute(path: '/downloads', builder: (c, s) => const DownloadsScreen()),
          GoRoute(path: '/subtitles', builder: (c, s) => const SubtitlesScreen()),
        ],
      ),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    ],
  );
});
