import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/queries.dart';
import '../../domain/domain.dart';
import 'library_providers.dart';
import 'widgets/cover_art.dart';
import 'widgets/error_retry.dart';
import 'widgets/paged_scroll.dart';
import 'widgets/sort_sheet.dart';

const _sortOptions = [
  SortOption(SongListSort.name, 'Título'),
  SortOption(SongListSort.album, 'Álbum'),
  SortOption(SongListSort.artist, 'Artista'),
  SortOption(SongListSort.year, 'Ano'),
  SortOption(SongListSort.recentlyAdded, 'Adicionadas recentemente'),
  SortOption(SongListSort.recentlyPlayed, 'Tocadas recentemente'),
  SortOption(SongListSort.playCount, 'Execuções'),
  SortOption(SongListSort.rating, 'Avaliação'),
  SortOption(SongListSort.duration, 'Duração'),
  SortOption(SongListSort.random, 'Aleatório'),
];

/// Paginated song list. Doubles as the genre drill-down when [genreId] is
/// set.
class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key, this.genreId, this.title});

  final String? genreId;
  final String? title;

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  SongListSort _sortBy = SongListSort.name;
  SortOrder _sortOrder = SortOrder.asc;

  SongsArg get _arg => (
    albumArtistId: null,
    genreId: widget.genreId,
    sortBy: _sortBy,
    sortOrder: _sortOrder,
  );

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
    final state = ref.watch(songListControllerProvider(_arg));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Músicas'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _pickSort),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(songListControllerProvider(_arg).future),
          child: PagedScrollListener(
            onLoadMore: () =>
                ref.read(songListControllerProvider(_arg).notifier).loadMore(),
            child: ListView.builder(
              itemCount: value.items.length + 1,
              itemBuilder: (context, index) {
                if (index == value.items.length) {
                  return LoadMoreFooter(
                    isLoading: value.isLoadingMore,
                    failed: value.loadMoreFailed,
                    onRetry: () => ref
                        .read(songListControllerProvider(_arg).notifier)
                        .loadMore(),
                  );
                }

                return SongTile(song: value.items[index]);
              },
            ),
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(songListControllerProvider(_arg)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class SongTile extends StatelessWidget {
  const SongTile({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 48,
        child: CoverArt(imageId: song.imageId, size: 100, borderRadius: 4),
      ),
      title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [song.artistName, if (song.album != null) song.album].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(formatDurationMs(song.duration)),
      // Playback lands in phase 3 — tapping is a no-op for now.
      onTap: () {},
    );
  }
}
