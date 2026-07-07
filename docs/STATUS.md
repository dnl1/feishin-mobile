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

## Fases 1-8

Não iniciadas — dependem da Fase 0 fechar primeiro (a decisão de engine de
áudio já está tomada e documentada no PLAN.md, mas só fica validada depois
do Spike A rodar em device real).

| Fase | Escopo | Status |
|---|---|---|
| 1 | Auth + camada de dados Navidrome | Não iniciada |
| 2 | Biblioteca (somente leitura) | Não iniciada |
| 3 | Engine de playback core | Não iniciada |
| 4 | Playback extra (EQ, sleep timer, scrobble, auto-DJ, downloads) | Não iniciada |
| 5 | Favoritos, busca, lyrics, sharing, similares | Não iniciada |
| 6 | Visualizer | Não iniciada |
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
