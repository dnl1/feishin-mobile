import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_providers.dart';
import 'widgets/cover_art.dart';
import 'widgets/error_retry.dart';

class RadiosScreen extends ConsumerWidget {
  const RadiosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stations = ref.watch(radioStationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rádios')),
      body: switch (stations) {
        AsyncData(:final value) when value.isEmpty => const Center(
          child: Text('Nenhuma rádio cadastrada no servidor.'),
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(radioStationsProvider.future),
          child: ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) {
              final station = value[index];
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  child: CoverArt(
                    imageId: station.imageId,
                    size: 100,
                    borderRadius: 4,
                    fallbackIcon: Icons.radio,
                  ),
                ),
                title: Text(station.name),
                subtitle: Text(
                  station.streamUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Playback lands in phase 3 — tapping is a no-op for now.
                onTap: () {},
              );
            },
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(radioStationsProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
