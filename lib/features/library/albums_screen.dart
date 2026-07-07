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
  SortOption(AlbumListSort.name, 'Nome'),
  SortOption(AlbumListSort.albumArtist, 'Artista do álbum'),
  SortOption(AlbumListSort.year, 'Ano'),
  SortOption(AlbumListSort.recentlyAdded, 'Adicionados recentemente'),
  SortOption(AlbumListSort.recentlyPlayed, 'Tocados recentemente'),
  SortOption(AlbumListSort.playCount, 'Execuções'),
  SortOption(AlbumListSort.rating, 'Avaliação'),
  SortOption(AlbumListSort.favorited, 'Favoritos'),
  SortOption(AlbumListSort.duration, 'Duração'),
  SortOption(AlbumListSort.songCount, 'Nº de músicas'),
  SortOption(AlbumListSort.random, 'Aleatório'),
];

/// Album grid with infinite scroll. Doubles as the genre/artist drill-down
/// view when [genreId]/[artistId] are set.
class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({
    super.key,
    this.artistId,
    this.genreId,
    this.title,
    this.initialSortBy = AlbumListSort.name,
    this.initialSortOrder = SortOrder.asc,
  });

  final String? artistId;
  final String? genreId;
  final AlbumListSort initialSortBy;
  final SortOrder initialSortOrder;
  final String? title;

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  late AlbumListSort _sortBy = widget.initialSortBy;
  late SortOrder _sortOrder = widget.initialSortOrder;

  AlbumsArg get _arg => (
    artistId: widget.artistId,
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
    final state = ref.watch(albumListControllerProvider(_arg));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Álbuns'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _pickSort),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(albumListControllerProvider(_arg).future),
          child: PagedScrollListener(
            onLoadMore: () =>
                ref.read(albumListControllerProvider(_arg).notifier).loadMore(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: value.items.length,
                    itemBuilder: (context, index) =>
                        _AlbumCard(album: value.items[index]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LoadMoreFooter(
                    isLoading: value.isLoadingMore,
                    failed: value.loadMoreFailed,
                    onRetry: () => ref
                        .read(albumListControllerProvider(_arg).notifier)
                        .loadMore(),
                  ),
                ),
              ],
            ),
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(albumListControllerProvider(_arg)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/library/albums/${album.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoverArt(imageId: album.imageId, size: 300),
          const SizedBox(height: 6),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            [
              album.albumArtistName,
              if (album.releaseYear != null) '${album.releaseYear}',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
