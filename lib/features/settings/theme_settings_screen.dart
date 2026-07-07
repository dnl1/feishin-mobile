import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_id.dart';
import 'theme_controller.dart';

/// Lists all 32 ported themes grouped by light/dark, plus a "follow system"
/// option. Tapping a theme applies it immediately via [themeControllerProvider].
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeControllerProvider);
    final notifier = ref.read(themeControllerProvider.notifier);

    final dark = AppThemeId.values.where(
      (id) => tokensFor(id).mode == Brightness.dark,
    );
    final light = AppThemeId.values.where(
      (id) => tokensFor(id).mode == Brightness.light,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tema')),
      body: RadioGroup<AppThemeId?>(
        groupValue: selected,
        onChanged: notifier.select,
        child: ListView(
          children: [
            const RadioListTile<AppThemeId?>(
              title: Text('Seguir sistema'),
              subtitle: Text('Usa o tema padrão claro/escuro do iOS'),
              value: null,
            ),
            const _SectionHeader('Claros'),
            for (final id in light) _ThemeTile(id: id),
            const _SectionHeader('Escuros'),
            for (final id in dark) _ThemeTile(id: id),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.id});

  final AppThemeId id;

  @override
  Widget build(BuildContext context) {
    final tokens = tokensFor(id);

    return RadioListTile<AppThemeId?>(
      title: Text(id.label),
      value: id,
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Swatch(tokens.background),
          _Swatch(tokens.surface),
          _Swatch(tokens.primary),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
