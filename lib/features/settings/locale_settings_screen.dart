import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Picks the app language among the currently shipped locales (see
/// docs/STATUS.md, Fase 7 — only `en`/`pt-BR` are ported so far) or resets
/// to whatever the device reports. Unlike the theme picker, easy_localization
/// has no persisted "follow system" mode — [resetLocale] is a one-shot
/// action that re-reads the device locale, not a standing preference.
class LocaleSettingsScreen extends StatelessWidget {
  const LocaleSettingsScreen({super.key});

  static final _labels = {
    const Locale('en'): 'English',
    const Locale('pt', 'BR'): 'Português (Brasil)',
  };

  @override
  Widget build(BuildContext context) {
    final current = context.locale;

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
                'Detectado agora: ${_labels[context.deviceLocale] ?? context.deviceLocale}',
              ),
              onTap: () => context.resetLocale(),
            ),
            const Divider(),
            for (final locale in context.supportedLocales)
              RadioListTile<Locale>(
                title: Text(_labels[locale] ?? locale.toString()),
                value: locale,
              ),
          ],
        ),
      ),
    );
  }
}
