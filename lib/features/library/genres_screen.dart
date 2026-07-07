import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/queries.dart';
import '../../domain/domain.dart';
import 'library_providers.dart';
import 'widgets/error_retry.dart';
import 'widgets/paged_scroll.dart';
import 'widgets/sort_sheet.dart';

const _sortOptions = [
  SortOption(GenreListSort.name, 'Nome'),
  SortOption(GenreListSort.albumCount, 'Nº de álbuns'),
  SortOption(GenreListSort.songCount, 'Nº de músicas'),
];

class GenresScreen extends ConsumerStatefulWidget {
  const GenresScreen({super.key});

  @override
  ConsumerState<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends ConsumerState<GenresScreen> {
  GenreListSort _sortBy = GenreListSort.name;
  SortOrder _sortOrder = SortOrder.asc;

  GenresArg get _arg => (sortBy: _sortBy, sortOrder: _sortOrder);

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
    final state = ref.watch(genreListControllerProvider(_arg));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gêneros'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: _pickSort),
        ],
      ),
      body: switch (state) {
        AsyncData(:final value) => PagedScrollListener(
          onLoadMore: () =>
              ref.read(genreListControllerProvider(_arg).notifier).loadMore(),
          child: ListView.builder(
            itemCount: value.items.length + 1,
            itemBuilder: (context, index) {
              if (index == value.items.length) {
                return LoadMoreFooter(
                  isLoading: value.isLoadingMore,
                  failed: value.loadMoreFailed,
                  onRetry: () => ref
                      .read(genreListControllerProvider(_arg).notifier)
                      .loadMore(),
                );
              }

              final genre = value.items[index];
              return _GenreTile(genre: genre);
            },
          ),
        ),
        AsyncError(:final error) => ErrorRetry(
          error: error,
          onRetry: () => ref.invalidate(genreListControllerProvider(_arg)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({required this.genre});

  final Genre genre;

  @override
  Widget build(BuildContext context) {
    final counts = [
      if (genre.albumCount != null) '${genre.albumCount} álbuns',
      if (genre.songCount != null) '${genre.songCount} músicas',
    ];

    return ListTile(
      leading: const Icon(Icons.label_outline),
      title: Text(genre.name),
      subtitle: counts.isEmpty ? null : Text(counts.join(' · ')),
      onTap: () => context.push(
        Uri(
          path: '/library/albums-by-genre',
          queryParameters: {'genreId': genre.id, 'name': genre.name},
        ).toString(),
      ),
    );
  }
}
