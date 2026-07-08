import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/i18n/supported_locales.dart';

/// Picks the app language among the 36 ported locales (see docs/STATUS.md,
/// Fase 7) or resets to whatever the device reports. Unlike the theme
/// picker, easy_localization has no persisted "follow system" mode —
/// [resetLocale] is a one-shot action that re-reads the device locale, not
/// a standing preference.
class LocaleSettingsScreen extends StatelessWidget {
  const LocaleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.locale;
    final locales = [...context.supportedLocales]
      ..sort((a, b) => localeLabel(a).compareTo(localeLabel(b)));

    return Scaffold(
      appBar: AppBar(title: const Text('Idioma')),
      body: RadioGroup<Locale>(
        groupValue: current,
        onChanged: (locale) {
          if (locale != null) context.setLocale(locale);
        },
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.smartphone_outlined),
              title: const Text('Usar idioma do sistema'),
              subtitle: Text(
                'Detectado agora: ${localeLabel(context.deviceLocale)}',
              ),
              onTap: () => context.resetLocale(),
            ),
            const Divider(),
            for (final locale in locales)
              RadioListTile<Locale>(
                title: Text(localeLabel(locale)),
                value: locale,
              ),
          ],
        ),
      ),
    );
  }
}
