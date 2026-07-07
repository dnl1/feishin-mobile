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

## Fases 3-8

| Fase | Escopo | Status |
|---|---|---|
| 3 | Engine de playback core | Não iniciada (depende do Spike A) |
| 4 | Playback extra (EQ, sleep timer, scrobble, auto-DJ, downloads) | Não iniciada |
| 5 | Favoritos, busca, lyrics, sharing, similares (+ pastas da Fase 2) | Não iniciada |
| 6 | Visualizer | Não iniciada (depende do Spike B) |
| 7 | Temas + i18n | Não iniciada |
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
