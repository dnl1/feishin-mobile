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
  SortOption(AlbumArtistListSort.name, 'Nome'),
  SortOption(AlbumArtistListSort.albumCount, 'Nº de álbuns'),
  SortOption(AlbumArtistListSort.songCount, 'Nº de músicas'),
  SortOption(AlbumArtistListSort.playCount, 'Execuções'),
  SortOption(AlbumArtistListSort.rating, 'Avaliação'),
  SortOption(AlbumArtistListSort.favorited, 'Favoritos'),
];

class ArtistsScreen extends ConsumerStatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ConsumerState<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends ConsumerState<ArtistsScreen> {
  AlbumArtistListSort _sortBy = AlbumArtistListSort.name;
  SortOrder _sortOrder = SortOrder.asc;

  ArtistsArg get _arg => (sortBy: _sortBy, sortOrder: _sortOrder);

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
    final state = ref.watch(artistListControllerProvider(_arg));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artistas'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _pickSort),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(artistListControllerProvider(_arg).future),
          child: PagedScrollListener(
            onLoadMore: () => ref
                .read(artistListControllerProvider(_arg).notifier)
                .loadMore(),
            child: ListView.builder(
              itemCount: value.items.length + 1,
              itemBuilder: (context, index) {
                if (index == value.items.length) {
                  return LoadMoreFooter(
                    isLoading: value.isLoadingMore,
                    failed: value.loadMoreFailed,
                    onRetry: () => ref
                        .read(artistListControllerProvider(_arg).notifier)
                        .loadMore(),
                  );
                }

                final artist = value.items[index];
                return _ArtistTile(artist: artist);
              },
            ),
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(artistListControllerProvider(_arg)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ArtistTile extends StatelessWidget {
  const _ArtistTile({required this.artist});

  final AlbumArtist artist;

  @override
  Widget build(BuildContext context) {
    final counts = [
      if (artist.albumCount != null) '${artist.albumCount} álbuns',
      if (artist.songCount != null) '${artist.songCount} músicas',
    ];

    return ListTile(
      leading: SizedBox(
        width: 48,
        child: CoverArt(
          imageId: artist.imageId,
          size: 100,
          borderRadius: 24,
          fallbackIcon: Icons.person,
        ),
      ),
      title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: counts.isEmpty ? null : Text(counts.join(' · ')),
      onTap: () => context.push('/library/artists/${artist.id}'),
    );
  }
}
