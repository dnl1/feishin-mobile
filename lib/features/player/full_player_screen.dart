import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import 'player.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final data = controller.getPlayerData();
    final song = data.currentSong?.song;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player')),
        body: const Center(child: Text('Nenhuma música na fila')),
      );
    }

    final playing = player.status == PlayerStatus.playing;

    return Scaffold(
      appBar: AppBar(title: const Text('Tocando agora')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 96,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              song.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              song.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('0:00', style: theme.textTheme.labelMedium),
                Expanded(child: Slider(value: 0, onChanged: null)),
                Text(
                  formatDurationMs(song.duration),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Anterior',
                  icon: const Icon(Icons.skip_previous),
                  onPressed: controller.mediaPrevious,
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  tooltip: playing ? 'Pausar' : 'Tocar',
                  iconSize: 36,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: controller.mediaTogglePlayPause,
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  tooltip: 'Próxima',
                  icon: const Icon(Icons.skip_next),
                  onPressed: player.queue.defaultOrder.length > 1
                      ? controller.mediaNext
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SegmentedButton<PlayerRepeat>(
              segments: const [
                ButtonSegment(
                  value: PlayerRepeat.none,
                  icon: Icon(Icons.repeat),
                  tooltip: 'Sem repetição',
                ),
                ButtonSegment(
                  value: PlayerRepeat.one,
                  icon: Icon(Icons.repeat_one),
                  tooltip: 'Repetir faixa',
                ),
                ButtonSegment(
                  value: PlayerRepeat.all,
                  icon: Icon(Icons.repeat_on),
                  tooltip: 'Repetir fila',
                ),
              ],
              selected: {player.repeat},
              onSelectionChanged: (value) => controller.setRepeat(value.single),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shuffle'),
              secondary: const Icon(Icons.shuffle),
              value: player.shuffle == PlayerShuffle.track,
              onChanged: (_) => controller.toggleShuffle(),
            ),
            const SizedBox(height: 16),
            Text('Fila', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final (index, queueSong)
                in controller.getQueueOrder().items.indexed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                selected: queueSong.uniqueId == data.currentSong?.uniqueId,
                leading: Text('${index + 1}'),
                title: Text(
                  queueSong.song.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  queueSong.song.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => controller.mediaPlayByIndex(index),
              ),
          ],
        ),
      ),
    );
  }
}
