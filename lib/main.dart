import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/server_store.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final serverBox = await Hive.openBox<String>(ServerStore.boxName);

  runApp(
    ProviderScope(
      overrides: [
        serverStoreProvider.overrideWithValue(ServerStore(serverBox)),
      ],
      child: const FeishinApp(),
    ),
  );
}

class FeishinApp extends ConsumerWidget {
  const FeishinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Feishin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
