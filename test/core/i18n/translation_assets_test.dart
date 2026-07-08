import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:feishin_mobile/core/i18n/supported_locales.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fidelity checks on assets/translations/*.json — the flattened,
/// easy_localization-ready output of the one-off Node/i18next resolution
/// script described in docs/STATUS.md, Fase 7. These aren't hand-written,
/// so the risk is a bug in that script (unresolved `$t()` nesting, stray
/// `{{var}}` interpolation, a broken plural group), not typos.
void main() {
  Map<String, dynamic> load(String locale) {
    final file = File('assets/translations/$locale.json');
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  Iterable<Object?> leaves(Object? node) {
    if (node is Map) {
      return node.values.expand(leaves);
    }
    return [node];
  }

  final localeFileNames = supportedLocales
      .map((l) => l.toStringWithSeparator(separator: '-'))
      .toList();

  test('all 36 ported locales have an asset file', () {
    expect(localeFileNames.length, 36);
    for (final locale in localeFileNames) {
      expect(
        File('assets/translations/$locale.json').existsSync(),
        isTrue,
        reason: locale,
      );
    }
  });

  test('no locale has unresolved i18next nesting or interpolation', () {
    for (final locale in localeFileNames) {
      final data = load(locale);
      for (final value in leaves(data)) {
        if (value is! String) continue;
        expect(
          value.contains(r'$t('),
          isFalse,
          reason: '$locale: unresolved \$t() nesting in "$value"',
        );
        expect(
          value.contains('{{'),
          isFalse,
          reason: '$locale: leftover {{}} interpolation in "$value"',
        );
      }
    }
  });

  test(r'nested $t() reference resolves to plain text', () {
    final en = load('en');
    expect(en['action']['addToFavorites'], 'Add to Favorites');
    expect(en['action']['createPlaylist'], 'Create Playlist');

    final pt = load('pt-BR');
    expect(pt['action']['addToFavorites'], 'Adicionar em Favoritos');
  });

  test('runtime interpolation placeholders use easy_localization syntax', () {
    final en = load('en');
    expect(
      en['action']['downloadStarted'],
      'Started download of {count} items',
    );
  });

  test('plural concepts resolve as category maps, not flattened strings', () {
    final en = load('en');
    expect(en['entity']['playlist'], {'one': 'Playlist', 'other': 'Playlists'});
    expect(en['entity']['favorite'], {'one': 'Favorite', 'other': 'Favorites'});

    // pt-BR has an extra CLDR "many" category the en source doesn't use.
    final pt = load('pt-BR');
    expect(pt['entity']['playlist']['many'], isNotNull);
  });

  test('pt-BR falls back through pt before reaching en, matching i18next', () {
    final en = load('en');
    final pt = load('pt');
    final ptBr = load('pt-BR');

    // Missing from pt-BR's own source but present in pt (Portugal) — since
    // all 36 locales load into one i18next instance (mirroring i18n.ts),
    // the language chain is pt-BR -> pt -> en, so this must resolve to
    // pt's translation, not skip straight to English.
    expect(
      ptBr['table']['config']['general']['alignRight'],
      'Alinhar à direita',
    );
    expect(
      ptBr['table']['config']['general']['alignRight'],
      pt['table']['config']['general']['alignRight'],
    );

    // Missing from *both* pt-BR and pt — only then does it fall through to
    // the global fallbackLng: en.
    expect(
      ptBr['form']['shareItem']['successMustClick'],
      en['form']['shareItem']['successMustClick'],
    );
  });
}
