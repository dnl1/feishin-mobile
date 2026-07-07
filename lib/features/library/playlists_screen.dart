import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/queries.dart';
import '../../domain/domain.dart';
import 'library_providers.dart';
import 'widgets/cover_art.dart';
import 'widgets/error_retry.dart';
import 'widgets/paged_scroll.dart';
import 'widgets/sort_sheet.dart';

const _sortOptions = [
  SortOption(PlaylistListSort.name, 'Nome'),
  SortOption(PlaylistListSort.updatedAt, 'Atualizada recentemente'),
  SortOption(PlaylistListSort.songCount, 'Nº de músicas'),
  SortOption(PlaylistListSort.duration, 'Duração'),
  SortOption(PlaylistListSort.owner, 'Dono'),
];

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  PlaylistListSort _sortBy = PlaylistListSort.name;
  SortOrder _sortOrder = SortOrder.asc;

  PlaylistsArg get _arg => (sortBy: _sortBy, sortOrder: _sortOrder);

  Future<void> _pickSort() async {
    final selection = await showSortSheet(
      context: context,
      options: _sortOptions,
      current: _sortBy,
      currentOrder: _sortOrder,
    );
    if (selection != null) {
      setState(() {
        _sortBy = selection.sortBy;
        _sortOrder = selection.sortOrder;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistListControllerProvider(_arg));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _pickSort),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(playlistListControllerProvider(_arg).future),
          child: PagedScrollListener(
            onLoadMore: () => ref
                .read(playlistListControllerProvider(_arg).notifier)
                .loadMore(),
            child: ListView.builder(
              itemCount: value.items.length + 1,
              itemBuilder: (context, index) {
                if (index == value.items.length) {
                  return LoadMoreFooter(
                    isLoading: value.isLoadingMore,
                    failed: value.loadMoreFailed,
                    onRetry: () => ref
                        .read(playlistListControllerProvider(_arg).notifier)
                        .loadMore(),
                  );
                }

                return _PlaylistTile(playlist: value.items[index]);
              },
            ),
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(playlistListControllerProvider(_arg)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final isSmart = playlist.rules != null && playlist.rules!.isNotEmpty;
    final subtitle = [
      if (playlist.songCount != null) '${playlist.songCount} músicas',
      if (playlist.owner != null) playlist.owner!,
      if (isSmart) 'inteligente',
    ];

    return ListTile(
      leading: SizedBox(
        width: 48,
        child: CoverArt(
          imageId: playlist.imageId,
          size: 100,
          borderRadius: 4,
          fallbackIcon: Icons.queue_music,
        ),
      ),
      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle.join(' · ')),
      onTap: () => context.push('/library/playlists/${playlist.id}'),
    );
  }
}
