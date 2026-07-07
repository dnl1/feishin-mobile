import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/home/home_screen.dart';
import '../features/servers/add_server_screen.dart';
import '../features/servers/servers_screen.dart';

/// Routes grow with the phases (library/search/settings tabs land with the
/// phase-3 navigation shell) — mirroring `AppRoute` of the original app.
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
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
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
    ],
  );
});
