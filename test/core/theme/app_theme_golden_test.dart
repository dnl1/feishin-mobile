import 'package:feishin_mobile/core/theme/app_theme.dart';
import 'package:feishin_mobile/core/theme/app_theme_id.dart';
import 'package:feishin_mobile/core/theme/feishin_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny "album row" preview that exercises the ColorScheme roles and
/// FeishinColors extension a real screen would use — cheap enough to render
/// under every representative theme without a device/simulator (see
/// docs/STATUS.md, Fase 7 verification strategy).
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.id});

  final AppThemeId id;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppThemeData(id),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Feishin')),
        body: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final colors = theme.extension<FeishinColors>()!;
            return Container(
              color: colors.backgroundAlternate,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Álbum de exemplo', style: theme.textTheme.titleLarge),
                  Text(
                    'Artista de exemplo',
                    style: TextStyle(color: colors.foregroundMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Reproduzir'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: colors.stateSuccess),
                      Icon(Icons.warning, color: colors.stateWarning),
                      Icon(Icons.error, color: theme.colorScheme.error),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  const representative = [
    AppThemeId.defaultDark,
    AppThemeId.defaultLight,
    AppThemeId.nord,
    AppThemeId.highContrastDark,
    AppThemeId.glassyDark,
    AppThemeId.rosePineMoon,
  ];

  for (final id in representative) {
    testWidgets('golden: ${id.name} theme preview', (tester) async {
      await tester.pumpWidget(_ThemePreview(id: id));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/theme_${id.name}.png'),
      );
    });
  }
}
