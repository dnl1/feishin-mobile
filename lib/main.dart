import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/i18n/supported_locales.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_id.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/server_store.dart';
import 'features/settings/theme_controller.dart';
import 'features/settings/theme_store.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();
  final serverBox = await Hive.openBox<String>(ServerStore.boxName);
  final themeBox = await Hive.openBox<String>(ThemeStore.boxName);

  runApp(
    EasyLocalization(
      supportedLocales: supportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useFallbackTranslations: true,
      child: ProviderScope(
        overrides: [
          serverStoreProvider.overrideWithValue(ServerStore(serverBox)),
          themeStoreProvider.overrideWithValue(ThemeStore(themeBox)),
        ],
        child: const FeishinApp(),
      ),
    ),
  );
}

class FeishinApp extends ConsumerWidget {
  const FeishinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'Feishin',
      theme: buildAppThemeData(selected ?? AppThemeId.defaultLight),
      darkTheme: buildAppThemeData(selected ?? AppThemeId.defaultDark),
      themeMode: selected == null
          ? ThemeMode.system
          : (tokensFor(selected).mode == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
