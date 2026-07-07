import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/queries.dart';
import '../features/auth/auth_controller.dart';
import '../features/home/home_screen.dart';
import '../features/library/album_detail_screen.dart';
import '../features/library/albums_screen.dart';
import '../features/library/artist_detail_screen.dart';
import '../features/library/artists_screen.dart';
import '../features/library/genres_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/playlist_detail_screen.dart';
import '../features/library/playlists_screen.dart';
import '../features/library/radios_screen.dart';
import '../features/library/songs_screen.dart';
import '../features/player/full_player_screen.dart';
import '../features/servers/add_server_screen.dart';
import '../features/servers/servers_screen.dart';
import '../features/settings/locale_settings_screen.dart';
import '../features/settings/theme_settings_screen.dart';
import '../features/shell/app_shell.dart';

/// Routes grow with the phases (Busca/Configurações tabs + player land with
/// phase 3) — mirroring `AppRoute` of the original app.
final routerProvider = Provider<GoRouter>((ref) {
  // Bumped on every auth change so redirects re-run (e.g. the current
  // server was just removed).
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider).value;
      if (auth == null) {
        // Still loading persisted servers — let the current route render its
        // loading state; a refresh tick re-evaluates once loaded.
        return null;
      }

      final onServers = state.matchedLocation.startsWith('/servers');
      if (auth.currentServer == null && !onServers) {
        return '/servers';
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'albums',
                    builder: (context, state) => const AlbumsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => AlbumDetailScreen(
                          albumId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'albums-by-genre',
                    builder: (context, state) => AlbumsScreen(
                      genreId: state.uri.queryParameters['genreId'],
                      title: state.uri.queryParameters['name'],
                      initialSortBy: AlbumListSort.name,
                    ),
                  ),
                  GoRoute(
                    path: 'artists',
                    builder: (context, state) => const ArtistsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => ArtistDetailScreen(
                          artistId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'songs',
                    builder: (context, state) => const SongsScreen(),
                  ),
                  GoRoute(
                    path: 'genres',
                    builder: (context, state) => const GenresScreen(),
                  ),
                  GoRoute(
                    path: 'playlists',
                    builder: (context, state) => const PlaylistsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => PlaylistDetailScreen(
                          playlistId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'radios',
                    builder: (context, state) => const RadiosScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) => const FullPlayerScreen(),
      ),
      GoRoute(
        path: '/servers',
        builder: (context, state) => const ServersScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddServerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const LocaleSettingsScreen(),
      ),
    ],
  );
});
