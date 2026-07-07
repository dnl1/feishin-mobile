# Status

Checklist de progresso do plano em [PLAN.md](PLAN.md). Atualizar a cada
sessão de trabalho — isso é o que responde "o que falta" sem precisar reler
o histórico do chat.

## Fase 0 — Fundação + spikes de risco

- [x] Projeto Flutter criado (alvo iOS, bundle `com.dnl1.feishin`)
- [x] Riverpod + go_router + freezed/json_serializable + dio + flutter_secure_storage + hive instalados
- [x] Domain model portado 1:1 de `domain-types.ts`: `Song`, `Album`,
      `AlbumArtist`, `Artist`, `Genre`, `Playlist`, `User`,
      `InternetRadioStation`, `RelatedArtist`, `GainInfo`,
      `ServerConfig`/`ServerCredentials` (`lib/domain/`)
- [x] Teste de round-trip JSON do domain model (`test/domain/`)
- [x] CI no GitHub Actions: `analyze-and-test` (Ubuntu) + `ios-build` (macOS
      runner, `flutter build ios --no-codesign`)
- [x] Repositório público: https://github.com/dnl1/feishin-mobile
- [x] **CI validado ponta a ponta**: os dois jobs (`analyze-and-test` e
      `ios-build`) passaram no primeiro push pra `main` — o scaffold compila
      de verdade num toolchain Xcode real, não só localmente
      ([run 28837763466](https://github.com/dnl1/feishin-mobile/actions/runs/28837763466))
- [ ] **Spike A (áudio)** — protótipo `flutter_soloud` + `audio_service`
      fim a fim (stream HTTP real, EQ, compressor, lock screen). **Bloqueado**:
      precisa rodar em simulador/dispositivo iOS real, não só compilar — CI
      headless não mede CPU/bateria/jank. Ver "Bloqueios" abaixo.
- [ ] **Spike B (visualizer)** — `fftea` + `CustomPainter` lendo
      `getWave`/`getLinearFft` do SoLoud a 30-60fps sem jank. Mesmo
      bloqueio do Spike A.

**Fase 0 não está completa** até os dois spikes rodarem de verdade — é o
critério de saída definido no plano, não "compilou no CI".

## Fase 1 — Auth + camada de dados Navidrome

Código completo e testado (60 testes verdes, `flutter analyze` limpo).
A Fase 1 **não depende dos spikes** (é Dart puro, sem áudio) — por isso foi
adiantada enquanto os spikes seguem bloqueados por hardware.

- [x] `NavidromeApi` (Dio): endpoints do contrato ND (`/api/...`) + login
      (`/auth/login`) + ping Subsonic (versão do servidor). Inclui captura
      de token rotacionado (`x-nd-authorization`) e re-auth automática em
      401 com single-flight (porta do interceptor de `navidrome-api.ts`)
      — `lib/data/navidrome/navidrome_api.dart`
- [x] `NdNormalize`: porta 1:1 de `navidrome-normalize.ts` (participants/
      subRoles, datas parciais com fallback minYear, tags de álbum →
      recordLabels/releaseTypes/version, cache-bust de imagem, sentinela
      `0001-` de playDate, semântica de truthiness do TS) —
      `lib/data/navidrome/navidrome_normalizer.dart`
- [x] Sort maps domain→ND portados de `domain-types.ts`
      (`lib/data/navidrome/navidrome_types.dart`, `lib/data/queries.dart`)
- [x] Interface `MusicServerRepository` + `NavidromeRepository` (espelha
      `navidrome-controller.ts`: contagens via `x-total-count`, genre via
      tag pós-BFR, `role=albumartist`, `missing=false`, URL builders de
      stream/download/cover art via credencial Subsonic)
- [x] Feature detection por versão (`getFeatures`/`hasFeature` +
      `VERSION_INFO`) — `lib/core/server_features.dart`
- [x] `AuthController` (Riverpod): config de servidor em Hive (não-secreto),
      credenciais + senha opcional em `flutter_secure_storage` (Keychain,
      `first_unlock` p/ streaming em background) — `lib/features/auth/`
- [x] Telas: lista de servidores, adicionar servidor (login), home com
      smoke-test real (contagens de álbuns/artistas/músicas) + `go_router`
      com redirect quando não há servidor
- [x] Testes: normalizer (fixtures ND), API (adapter Dio fake: headers,
      401→re-auth, rotação de token), repository (BFR on/off, URLs), auth
      controller (Hive temp + secure storage em memória), widget tests
- [ ] **Validação em device/simulador iOS contra Navidrome real** — mesmo
      bloqueio de hardware dos spikes (critério de verificação do PLAN.md)

## Fase 2 — Biblioteca (somente leitura)

Código completo e testado (65 testes verdes, `flutter analyze` limpo).

- [x] Paginação: `PagedListController` genérico (infinite scroll) portando o
      padrão de `query-keys.ts`/`utils-list-count.ts` — a contagem total vem
      do `x-total-count` de cada página, **nunca** há chamada separada de
      count (`lib/features/library/paged_list.dart`)
- [x] Controllers family por entidade (álbuns/músicas/artistas/gêneros/
      playlists) com chave em records (igualdade estrutural) + providers de
      detalhe (`library_providers.dart`)
- [x] Telas: grid de álbuns (com drill-down por gênero/artista), detalhe de
      álbum (multi-disco, chips de gênero), artistas + detalhe (discografia
      por ano), músicas, gêneros, playlists (lista + detalhe com todas as
      faixas), rádios — todas com sort sheet (asc/desc), pull-to-refresh,
      retry de erro e imagem de capa via `cached_network_image`
- [x] Shell de navegação: `StatefulShellRoute` com tabs Início/Biblioteca
      (Busca/Config + mini player chegam na Fase 3, conforme plano); Home
      virou dashboard clicável com contagens
- [x] Testes: paged controller (primeira página com count, loadMore até
      esgotar, chamadas concorrentes colapsam, falha mantém itens + retry) e
      widget test e2e (tab Biblioteca → grid → scroll infinito dispara 2ª
      página → detalhe do álbum) com repositório fake
- [ ] Telas de **pastas** (folders) — adiada: precisa do client Subsonic
      (`getMusicDirectory`), que será portado junto com favoritos/lyrics na
      Fase 5; não bloqueia as demais fases
- [ ] Validação em device/simulador iOS contra Navidrome real (mesmo
      bloqueio de hardware)

## Fase 3 — Engine de playback core

- [x] Base pura de fila/playback iniciada: enums `PlayMode`/`PlayerRepeat`/
      `PlayerShuffle`/`PlayerStatus`/`PlayerStyle`, `QueueData`, `PlayerData`
      e helpers portados de `player.store.ts` (`calculateNextSong`,
      `getDualPlayerSongs`, mapeamento shuffled→queue, geração/ajuste de
      índices shuffled, `calculateNextIndex`, navegação manual next/previous,
      `toggleRepeat`) — `lib/features/player/`
- [x] Testes da base de fila/playback cobrindo repeat none/all/one, shuffle
      com índice de reprodução diferente do índice visual, dual-player em
      repeat-one, ajuste de índices em inserção e navegação manual —
      `test/features/player_queue_test.dart` (`flutter test`: 71 testes
      verdes; `flutter analyze` limpo)
- [x] Store/controller Riverpod de player iniciado: `PlayerController` com
      estado síncrono, geração injetável de `_uniqueId`, `setQueue`,
      `addToQueueByType` (`now`/`shuffle`/`next`/`last`), play/pause/stop,
      next/previous/auto-next, repeat/shuffle, pause-on-next, volume/speed/
      mute, clear/remove e move selected top/bottom/next/around target —
      `lib/features/player/player_controller.dart`
- [x] Testes do controller cobrindo setQueue, add next/last/now, shuffle
      preservando faixa atual, auto-next, repeat-one, pause-on-next,
      remove/move selected e clamps de volume/speed —
      `test/features/player_controller_test.dart` (`flutter test`: 82 testes
      verdes; `flutter analyze` limpo)
- [x] Restore/autosave de fila via endpoints Navidrome (`getQueue`/
      `saveQueue`): `ServerPlayQueue` no contrato agnóstico,
      `NavidromeRepository.getPlayQueue/savePlayQueue` normalizando
      `items/current/position`, e `PlayerController.restoreQueueFromServer`/
      `saveQueueToServer` com validação contra filas de múltiplos servidores
- [x] Testes de queue restore/autosave no repositório e controller: payload
      POST `/api/queue`, fila vazia, normalização de músicas, restore aplicando
      `setQueue`, save enviando IDs/índice/posição e rejeição de servidor
      misturado (`flutter test`: 88 testes verdes; `flutter analyze` limpo)
- [x] UI inicial do player sem engine nativa: mini player dockado acima da
      bottom tab bar, rota `/player` com full player, controles play/pause/
      next/previous/repeat/shuffle e lista da fila; detalhe de álbum agora
      inicia a fila ao tocar em uma música (`flutter test`: 89 testes verdes;
      `flutter analyze` limpo)
- [ ] Integração SoLoud + `audio_service` — segue bloqueada pelo Spike A
      (precisa rodar em simulador/device iOS real)

## Fase 7 — Temas + i18n (en/pt-BR; 34 locales restantes ficam como próximo passo)

Escolhida para avançar em paralelo à Fase 3 porque é 100% Dart/Flutter, sem
nenhuma dependência de áudio nativo — não corre risco de retrabalho quando o
Spike A for validado (ver estratégia de verificação sem Mac abaixo).

- [x] Script de extração (`scripts/`, não versionado — one-off) parseando os
      32 arquivos `AppThemeConfiguration` de `src/shared/themes/*/*.ts` do
      repo original (`~/work/repos/feishin`), aplicando o mesmo merge com
      `defaultTheme.colors` que `getAppTheme` faz no web, e gerando
      `lib/core/theme/app_theme_tokens_data.dart` (mecânico, evita
      transcrever à mão 32×12 valores de cor)
- [x] `AppThemeId` (enum 1:1 com `AppTheme` de `app-theme-types.ts`, com
      labels de `THEME_DATA`) + `AppThemeTokens` (12 tokens de cor + `mode`)
      — `lib/core/theme/`
- [x] `buildAppThemeData(AppThemeId)`: mapeia os tokens pra `ColorScheme`
      Material 3 (parte de `ColorScheme.dark()`/`.light()` pros papéis que o
      contrato do feishin não define, sobrescreve primary/surface/error/
      outline/etc.) + `FeishinColors` (`ThemeExtension`) pros tokens sem
      papel M3 equivalente (`background-alternate`, `state-success`,
      `state-warning`) — `lib/core/theme/app_theme.dart`,
      `lib/core/theme/feishin_colors.dart`
- [x] `ThemeStore` (Hive, mesmo padrão do `ServerStore`) + `ThemeController`
      (Riverpod) persistindo a escolha do usuário (`null` = seguir claro/
      escuro do sistema com os temas default) — `lib/features/settings/`
- [x] `ThemeSettingsScreen`: lista os 32 temas agrupados claro/escuro com
      swatch de preview, `/settings/theme`, acessível pelo ícone de paleta
      na home; `MaterialApp` em `main.dart` usa `theme`/`darkTheme`/
      `themeMode` a partir do controller
- [x] Testes: fidelidade dos tokens gerados contra a fonte TS (spot-check em
      6 temas, incluindo cor em hex e fallback pro tema default), mapeamento
      pra `ColorScheme`/`FeishinColors` pros 32 temas, `ThemeStore`/
      `ThemeController` (Hive temp, mesmo padrão da Fase 1), e golden tests
      renderizando um preview de tela sob 6 temas representativos — cobre a
      "camada 1" da estratégia de verificação sem Mac (abaixo)
      (`flutter test`: 110 testes verdes; `flutter analyze` limpo)
- [x] **Camada 2 da estratégia sem Mac**: job `ios-theme-screenshots` na CI
      (`.github/workflows/ci.yml`) sobe um iOS Simulator real (escolhido pelo
      runtime iOS mais recente disponível no runner, não só "qualquer
      iPhone" — evita um device de runtime incompatível com o Xcode ativo)
      e roda `integration_test/theme_screenshots_test.dart` via `flutter
      drive` (`test_driver/integration_test.dart`), publicando o PNG de cada
      um dos 6 temas representativos como artifact (`theme-screenshots`) +
      log verboso do drive (`theme-screenshots-drive-log`) pra diagnosticar
      se travar de novo. Confirmado rodando de ponta a ponta (job verde em
      14m13s) e os PNGs baixados batem visualmente com os golden tests do
      Linux — fonte San Francisco real, dimensões de device reais
- [x] **i18n (escopo: `en` + `pt-BR`)**: os JSONs de `src/i18n/locales/*.json`
      do app original usam sintaxe i18next que não entra "direto" como o
      `PLAN.md` original assumia — referências cruzadas `$t(entity.playlist,
      {"count":1})` (~11% das 1315 chaves) e ~24 conceitos com variantes
      plural por categoria CLDR (`_one`/`_few`/`_many`/`_other`, varia por
      idioma). Resolvido com um script Node one-off que roda o **i18next
      real** (não reimplementa as regras de plural/nesting à mão) contra
      `en.json`/`pt-BR.json`, resolvendo toda referência `$t()` e agrupando
      variantes plural em mapas de categoria, preservando `{{var}}` →
      `{var}` (sintaxe do easy_localization) pra interpolação em runtime —
      gera `assets/translations/{en,pt-BR}.json` (32 conceitos plural, 0
      `$t()`/`{{}}` residual, fallback pt-BR→en verificado)
- [x] `easy_localization` inicializado em `main.dart`
      (`supportedLocales: [en, pt-BR]`), `LocaleSettingsScreen` em
      `/settings/language` (seguir sistema via `resetLocale()` + os 2
      idiomas via `setLocale()`), ícone de idioma na home
- [x] Testes: fidelidade dos assets de tradução (nesting resolvido, plurais
      como mapa de categoria, fallback pt-BR→en) —
      `test/core/i18n/translation_assets_test.dart`. Os widget tests de
      ponta a ponta (Fases 1-3) agora sobem via `EasyLocalization` real
      (`flutter test`: 115 testes verdes; `flutter analyze` limpo)
- [ ] **Backlog**: os outros 34 locales — mesmo script, só precisa apontar
      pros arquivos e adicionar a `supportedLocales`; nenhum retrabalho
      esperado, é a mesma transformação mecânica já validada em en/pt-BR
- [ ] Validação visual em device/simulador iOS real (ProMotion, cores OLED,
      dynamic type) — reservada pra polish da Fase 8, não bloqueia o porte

### Estratégia de verificação sem Mac (Fase 7 e além)

Sem hardware Apple neste ambiente (ver "Bloqueios conhecidos"), a validação
de temas usa duas camadas — **as duas implementadas e verificadas**:

1. **Golden/widget tests no Linux** — sem simulador ou device, pega
   mapeamento errado de token → papel do `ColorScheme`, contraste ruim,
   override de Material faltando (`test/core/theme/app_theme_golden_test.dart`).
2. **Screenshot real via CI macOS** — job `ios-theme-screenshots` sobe o
   Simulator e publica screenshot de cada tema como artifact, dando
   evidência de renderização iOS real sem precisar de Mac próprio. Primeira
   tentativa travou ~30min no handshake do `flutter drive` com um device de
   runtime não-default; corrigido escolhendo sempre o runtime iOS mais
   recente disponível, com timeouts (`timeout-minutes` em job/steps) e log
   verboso como artifact pra não repetir uma trava sem diagnóstico.

## Fases 4, 5, 6, 8

| Fase | Escopo | Status |
|---|---|---|
| 4 | Playback extra (EQ, sleep timer, scrobble, auto-DJ, downloads) | Não iniciada |
| 5 | Favoritos, busca, lyrics, sharing, similares (+ pastas da Fase 2) | Não iniciada |
| 6 | Visualizer | Não iniciada (depende do Spike B) |
| 8 | Configurações, polish, App Store | Não iniciada |

## Bloqueios conhecidos

- **Sem Mac físico neste ambiente** (dev local é Linux/WSL2, sem Xcode/
  simulador). O CI no GitHub Actions cobre "compila pra iOS", mas os spikes
  da Fase 0 exigem interação real (medir crossfade, CPU, bateria) — isso só
  dá pra fazer em um simulador/device de verdade. Encaminhamentos possíveis:
  usar um Mac físico, Mac na nuvem (MacStadium/Codemagic/Expo EAS-like), ou
  pedir pra alguém com Mac rodar o spike manualmente a partir deste repo.
- **Sem conta Apple Developer** — não bloqueia nada até a Fase 8
  (TestFlight/App Store precisa dela; build/dev local com `--no-codesign`
  não precisa).
- **Só Navidrome implementado por decisão do usuário** — Jellyfin/Subsonic
  ficam para depois da Fase 1 provar a arquitetura (`MusicServerRepository`
  já desenhada pra isso ser aditivo, não retrabalho).

## Decisões já fechadas (não reabrir sem motivo novo)

Documentadas com a justificativa completa em [PLAN.md](PLAN.md):

- Engine de áudio: **flutter_soloud**, não `just_audio` (just_audio não
  expõe grafo AVAudioEngine no iOS pra inserir EQ/compressor).
- Visualizer: **descartado o estilo Milkdrop/butterchurn**, mantido só
  espectro/osciloscópio nativo (`fftea` + `CustomPainter`).
- Plataforma: iOS primeiro; Flutter deve substituir o Electron por completo
  no futuro (inclusive desktop) — por isso a engine de áudio foi escolhida
  pensando em cross-platform, não só iOS.
- Backend: começa só com Navidrome.
- Discord RPC, remote control, MPRIS, hotkeys/command palette, playback
  local via mpv: **cortados do escopo iOS**, não adiados (ver PLAN.md,
  seção "O que fica de fora do v1").
