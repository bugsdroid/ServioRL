import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/home_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/library_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/requests/requests_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/movies/movies_screen.dart';
import '../../features/tv/tv_screen.dart';
import '../../features/subtitles/subtitles_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      // ── Shell routes (dengan bottom nav) ──────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (c, s) => const HomeScreen(),
          ),
          GoRoute(
            path: '/downloads',
            builder: (c, s) => const DownloadsScreen(),
          ),
          GoRoute(
            path: '/requests',
            builder: (c, s) => const RequestsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (c, s) => const SearchScreen(),
          ),
          GoRoute(
            path: '/library',
            builder: (c, s) => const LibraryScreen(),
          ),
        ],
      ),

      // ── Full-screen routes (tanpa bottom nav, pakai back button) ──
      GoRoute(
        path: '/settings',
        builder: (c, s) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/movies',
        builder: (c, s) => const MoviesScreen(),
      ),
      GoRoute(
        path: '/tv',
        builder: (c, s) => const TvScreen(),
      ),
      GoRoute(
        path: '/subtitles',
        builder: (c, s) => const SubtitlesScreen(),
      ),
    ],
  );
});
