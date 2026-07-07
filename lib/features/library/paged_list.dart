/// Infinite-scroll pagination over the repository list endpoints, porting
/// the intent of the original filter/pagination pattern (query-keys.ts +
/// utils-list-count.ts): the total count is taken from the page response
/// itself (`x-total-count` rides along with every Navidrome list call), so
/// no separate count request is ever issued.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/music_server_repository.dart';
import '../../data/paginated.dart';
import '../../data/repository_provider.dart';

class PagedListState<T> {
  const PagedListState({
    required this.items,
    required this.totalRecordCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<T> items;
  final int totalRecordCount;
  final bool isLoadingMore;

  /// Set when a load-more request fails — the list stays usable and the UI
  /// can offer a retry (the initial-load error is carried by [AsyncValue]).
  final bool loadMoreFailed;

  bool get hasMore => items.length < totalRecordCount;

  PagedListState<T> copyWith({bool? isLoadingMore, bool? loadMoreFailed}) =>
      PagedListState(
        items: items,
        totalRecordCount: totalRecordCount,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );
}

/// Base for the per-entity list controllers. Subclasses receive the family
/// argument through their constructor (Riverpod 3 family notifiers) and
/// implement [fetchPage] against [repository].
abstract class PagedListController<T> extends AsyncNotifier<PagedListState<T>> {
  static const int pageSize = 60;

  @protected
  late MusicServerRepository repository;

  @protected
  Future<PaginatedList<T>> fetchPage(int startIndex, int limit);

  @override
  Future<PagedListState<T>> build() async {
    final repo = await ref.watch(musicServerRepositoryProvider.future);
    if (repo == null) {
      throw StateError('Nenhum servidor selecionado');
    }
    repository = repo;

    final page = await fetchPage(0, pageSize);
    return PagedListState(
      items: page.items,
      totalRecordCount: page.totalRecordCount,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );

    try {
      final page = await fetchPage(current.items.length, pageSize);
      state = AsyncData(
        PagedListState(
          items: [...current.items, ...page.items],
          totalRecordCount: page.totalRecordCount,
        ),
      );
    } on Exception {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}
