# Reescrever o Feishin em Flutter (iOS primeiro, desktop depois)

## Contexto

O Feishin hoje é Electron + React/TypeScript/Mantine, com uma engine de player já
abstraída (Web Audio API / HTML5 Audio para o modo "web", `mpv` nativo para o modo
"local"), uma camada de API já normalizada para 3 backends (Navidrome/Jellyfin/
Subsonic → um domain model comum), 30 temas, 36 idiomas, e um layout mobile já
existente (`mobile-layout.tsx`) usado como referência estrutural.

Decisão do usuário: reescrever em **Flutter**, começando por **iOS**, com o
objetivo de longo prazo de o Flutter **substituir o Electron por completo**
(incluindo desktop via Flutter Desktop). Por isso, toda decisão de arquitetura
abaixo prioriza portabilidade cross-platform, não só "funciona no iOS". V1 mira
**paridade total de features**, mas começando com **um único backend (Navidrome)**
— a camada de dados é desenhada para não precisar de retrabalho ao adicionar
Jellyfin/Subsonic depois.

Duas decisões de arquitetura de alto risco foram pesquisadas e validadas
(ver seção "Decisões técnicas validadas") antes de fechar o plano, porque
apostar errado nelas invalidaria fases inteiras do trabalho.

## Decisões técnicas validadas

### Engine de áudio: `flutter_soloud`, não `just_audio`

O app atual precisa de: EQ paramétrico por bandas, compressor de dinâmica,
crossfade/gapless, streaming HTTP (não arquivos locais), e um analyser
FFT/waveform para o visualizer.

- `just_audio` no iOS embrulha `AVQueuePlayer`, **não** expõe um grafo
  `AVAudioEngine` onde dá para inserir `AVAudioUnitEQ`/compressor — a issue
  [ryanheise/just_audio#334](https://github.com/ryanheise/just_audio/issues/334)
  pedindo exatamente isso está aberta desde 2021, sem solução. Usar just_audio
  exigiria reescrever a engine de playback do zero em cima de `AVAudioEngine`
  (Swift puro), o que é iOS/macOS-only e não ajuda a meta de Windows/Linux.
- `flutter_soloud` (binding FFI do engine SoLoud) já tem `FilterType.parametricEq`
  (1-64 bandas), `compressorFilter`, `limiterFilter`, `biquadResonantFilter`,
  streaming HTTP real (`loadUrl`/`setBufferStream`, com exemplo de rádio Icecast
  + metadata ICY), múltiplas vozes simultâneas com `fadeVolume` (crossfade mais
  simples que o hack de dual-buffer atual), e `getWave`/`getLinearFft` para o
  analyser — e roda em iOS, macOS, Windows, Linux, Android e Web hoje.
- Trade-off aceito: `audio_service` (controles de lock screen/background) não
  tem integração pronta com SoLoud — vamos escrever um `BaseAudioHandler` fino
  que espelha posição/estado do SoLoud pro `audio_service`. É plugin de um único
  mantenedor (risco de bugs nativos mais difíceis de contornar que pacotes Dart
  puros) — por isso a Fase 0 inclui um spike dedicado antes de comprometer as
  fases seguintes.

**Ação da Fase 0**: spike de 1-2 dias — stream real de um servidor Navidrome,
EQ+compressor ativos, medir suavidade do crossfade e uso de CPU — antes de
seguir.

### Visualizer: manter o espectro/osciloscópio, descartar o Milkdrop/butterchurn

- `webview_flutter` hospedando butterchurn: tecnicamente possível, mas a ponte
  JS só passa strings — FFT a 60fps vira JSON encode/decode por frame (jank e
  gasto de bateria reais só para o visualizer).
- Reescrever Milkdrop nativamente via `FragmentProgram`/shaders: shaders do
  `dart:ui` são single-pass, sem os estágios de feedback/ping-pong que os
  presets do Milkdrop usam — é um esforço de meses de especialista em gráficos,
  não cabe no v1.
- **Decisão**: descartar o visualizer estilo Milkdrop. Portar só o equivalente
  ao `audiomotion-analyzer` (espectro/osciloscópio), usando o pacote `fftea`
  (FFT em Dart) + `CustomPainter`, alimentado pelo `getWave`/`getLinearFft` do
  próprio SoLoud. Isso já é portável para desktop de graça.

## O que fica de fora do v1 (cortado, não adiado)

Esses recursos dependem de arquitetura Electron/desktop que simplesmente não
existe no iOS — não é escopo futuro, é incompatibilidade estrutural:

- **Discord RPC** (`features/discord-rpc/`) — precisa do socket IPC local do
  cliente desktop do Discord.
- **Remote control** (`features/remote/`, `main/features/core/remote/`) — hoje
  é o desktop virando um servidor HTTP/WS para o celular controlar. Perde o
  sentido quando o próprio celular é o player.
- **MPRIS** (`use-mpris.ts`) — D-Bus é Linux/macOS-only; substituído por
  `audio_service` (MPNowPlayingInfoCenter) nativo do iOS.
- **`setSinkId` / seleção de dispositivo de saída** — sem equivalente iOS, é
  gerenciado pelo sistema.
- **Playback local via `mpv`** — sem varredura arbitrária de filesystem em
  sandbox iOS. V1 só reproduz streams do servidor (que já é o caminho
  dominante de uso real, `PlayerType.WEB`).
- **Command palette e hotkeys de teclado** — UX desktop-cêntrica; nem faz
  sentido em touch-only (o app atual carrega isso sem necessidade até no
  `mobile-layout.tsx` hoje — não vamos repetir o problema).

## Fases

### Fase 0 — Fundação + spikes de risco
- Projeto Flutter (alvo iOS por ora; estrutura pronta para macOS/Windows/Linux
  depois), lint/format, esqueleto de CI.
- Riverpod (state mgmt) + `go_router` (rotas, espelhando o enum `AppRoute` de
  `src/renderer/router/routes.ts`) + `freezed`/`json_serializable` + `dio`.
- **Spike A** (áudio): protótipo `flutter_soloud` + `audio_service` fim a fim —
  stream HTTP real, EQ, compressor, lock screen. Critério de saída: decisão
  documentada, sem CPU/bateria fora da curva.
- **Spike B** (visualizer): confirmar `fftea` + `CustomPainter` lendo
  `getWave`/`getLinearFft` do SoLoud a 30-60fps sem jank.
- Domain model em Dart (Freezed) espelhando `src/shared/types/domain-types.ts`:
  `Song`, `Album`, `AlbumArtist`, `Artist`, `Genre`, `Playlist`, `User`,
  `InternetRadioStation`.

### Fase 1 — Auth + camada de dados Navidrome
- `NavidromeApi` (Dio), espelhando os ~30 endpoints de
  `src/renderer/api/navidrome/navidrome-api.ts` (contrato `@ts-rest/core` →
  métodos Dio equivalentes).
- `NavidromeNormalizer`, espelhando
  `src/shared/api/navidrome/navidrome-normalize.ts` → domain model comum.
- Interface `MusicServerRepository` (mesmo com só Navidrome implementado agora)
  — é o que evita retrabalho ao adicionar Jellyfin/Subsonic depois, espelhando
  o papel de `src/renderer/api/controller.ts`.
- `AuthController` + `flutter_secure_storage` (Keychain) para credenciais —
  mais seguro que o `localStorage` atual (`src/renderer/store/auth.store.ts`).
  Config de servidores (não-secreta) em `Hive`/`shared_preferences`.
- Telas de login e lista/adição de servidor
  (ref: `src/renderer/features/login/`, `src/renderer/features/servers/`).

### Fase 2 — Biblioteca (somente leitura)
- Telas de álbuns, artistas/album-artists, gêneros, músicas, pastas, playlists
  (lista + detalhe), espelhando `src/renderer/features/{albums,artists,genres,
  songs,folders,playlists}/`.
- Paginação: portar o padrão filter/pagination de
  `src/renderer/api/query-keys.ts` + `utils-list-count.ts` (evitar chamada
  duplicada de contagem) usando Riverpod `AsyncNotifier`.

### Fase 3 — Engine de playback core
- Fila: portar 1:1 a forma de dados de `player.store.ts`
  (`QueueData { default, shuffled, songs }`) e os algoritmos puros de
  shuffle/repeat (`calculateNextIndex`, mapeamento shuffled↔queue) — são
  funções puras, baixo risco de porte.
- SoLoud: múltiplas vozes com `fadeVolume` para crossfade/gapless (substitui o
  hack de dual-buffer do `web-player-engine.tsx`).
- `audio_service`: `BaseAudioHandler` custom espelhando estado do SoLoud
  (substitui `use-media-session.ts` + `use-mpris.ts` em um só).
- Progresso/timestamp em provider separado (leve, atualizado por timer) —
  mesmo motivo de separação do `timestamp.store.ts` atual (evitar rebuild
  excessivo).
- Shell de navegação: bottom tab bar nativo iOS (Home/Biblioteca/Busca/
  Configurações) + mini player + full-screen player — estrutura inspirada no
  `mobile-layout.tsx` (single-pane + player fixo embaixo), adaptada à convenção
  de tab bar do iOS em vez do drawer/hambúrguer atual.

### Fase 4 — Playback extra
- UI de EQ + compressor ligada aos filtros do SoLoud
  (ref: `features/settings/components/playback/eq/`).
- Sleep timer — porte direto, lógica pura (`sleep-timer.store.ts`).
- Scrobble — portar limiares/eventos de `use-scrobble.ts`.
- Auto-DJ — portar `use-auto-dj.ts` + `auto-dj-songs.ts`/`auto-dj-albums.ts`.
- Restore/autosave de fila via endpoints `getQueue`/`saveQueue` do Navidrome
  (ref: `use-queue-restore.ts`, `use-autosave.ts`).
- Downloads: `dio` baixando pro diretório de documentos do app sandbox
  (`path_provider`), expondo via Files app (ref: `download-action.tsx`).

### Fase 5 — Favoritos, busca, lyrics, sharing, similares
- Favoritos/ratings sincronizando de volta pra fila (mirror de
  `updateQueueFavorites`/`updateQueueRatings`).
- Busca global.
- Lyrics (sincronizada + não-sincronizada) + cache offline em Hive — mesmo
  comportamento atual de só persistir lyrics offline (`main.tsx`,
  `shouldDehydrateQuery`).
- Sharing — só um POST pro endpoint de share do servidor.
- Painel de músicas similares.

### Fase 6 — Visualizer
- Espectro/osciloscópio nativo via `fftea` + `CustomPainter` (decisão da
  seção anterior).

### Fase 7 — Temas + i18n
- Portar as 30 temas (`src/renderer/themes/use-app-theme.ts`) como
  `ThemeData`/`ThemeExtension` em Dart — mecânico, só tokens de cor, dá pra
  gerar por script a partir do TS existente.
- Portar os 36 locales (`src/i18n/locales/*.json`, 1315 chaves) via
  `easy_localization` (aceita JSON direto, sem precisar reescrever traduções).

### Fase 8 — Configurações, polish, App Store
- Telas de configurações restantes (general/playback/appearance — sem a aba
  Window, que é Electron-only, e sem Hotkeys).
- Analytics (wrapper HTTP simples pro Umami, mesmo endpoint atual).
- Ícone, launch screen, provisionamento Apple Developer, TestFlight.

## Escopo futuro (fora deste plano, mas a arquitetura já permite)

- Jellyfin e Subsonic/OpenSubsonic — aditivos via a interface
  `MusicServerRepository` da Fase 1.
- Android.
- Flutter Desktop (macOS/Windows/Linux) para aposentar o Electron — motivo
  principal por trás da escolha do `flutter_soloud` na Fase 0.

## Verificação

- Cada fase termina rodando o app no simulador iOS (ou device via TestFlight
  interno) contra um servidor Navidrome real de teste — não só testes
  unitários dos algoritmos portados (fila/shuffle/repeat são bons candidatos a
  teste unitário direto, comparando com os mesmos casos de
  `player.store.ts`).
- Fase 0 só é considerada concluída com os dois spikes (áudio e visualizer)
  validados com métrica objetiva (sem estouro de CPU/bateria, sem jank
  perceptível), não só "compilou".
- Fase 3 (core playback) é o gate mais importante: antes de seguir para as
  fases 4+, validar manualmente gapless, crossfade, EQ, compressor e lock
  screen controls em um device físico (simulador não reflete bateria/áudio
  real de forma confiável).
