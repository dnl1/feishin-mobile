import 'package:feishin_mobile/data/queries.dart';
import 'package:feishin_mobile/data/repository_provider.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:feishin_mobile/features/library/library_providers.dart';
import 'package:feishin_mobile/features/library/paged_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repository.dart';

const AlbumsArg arg = (
  artistId: null,
  genreId: null,
  sortBy: AlbumListSort.name,
  sortOrder: SortOrder.asc,
);

void main() {
  late FakeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeRepository(
      albums: List.generate(150, (i) => makeAlbum('al-$i')),
    );
    container = ProviderContainer(
      overrides: [
        musicServerRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'first page carries items and the total count (no count call)',
    () async {
      final state = await container.read(
        albumListControllerProvider(arg).future,
      );

      expect(state.items, hasLength(PagedListController.pageSize));
      expect(state.totalRecordCount, 150);
      expect(state.hasMore, isTrue);
      expect(repository.albumListCalls, 1);
    },
  );

  test('loadMore appends pages until the total is reached', () async {
    await container.read(albumListControllerProvider(arg).future);
    final notifier = container.read(albumListControllerProvider(arg).notifier);

    await notifier.loadMore();
    expect(
      container.read(albumListControllerProvider(arg)).value!.items,
      hasLength(120),
    );

    await notifier.loadMore();
    final state = container.read(albumListControllerProvider(arg)).value!;
    expect(state.items, hasLength(150));
    expect(state.hasMore, isFalse);

    // Exhausted — further calls are no-ops.
    final callsBefore = repository.albumListCalls;
    await notifier.loadMore();
    expect(repository.albumListCalls, callsBefore);
  });

  test('concurrent loadMore calls collapse into one request', () async {
    await container.read(albumListControllerProvider(arg).future);
    final notifier = container.read(albumListControllerProvider(arg).notifier);

    await Future.wait([notifier.loadMore(), notifier.loadMore()]);

    expect(
      container.read(albumListControllerProvider(arg)).value!.items,
      hasLength(120),
    );
    // 1 initial + 1 loadMore (the second call bailed on isLoadingMore).
    expect(repository.albumListCalls, 2);
  });

  test(
    'failed loadMore keeps the loaded items and flags the failure',
    () async {
      await container.read(albumListControllerProvider(arg).future);
      final notifier = container.read(
        albumListControllerProvider(arg).notifier,
      );

      repository.failNextAlbumList = true;
      await notifier.loadMore();

      var state = container.read(albumListControllerProvider(arg)).value!;
      expect(state.items, hasLength(60));
      expect(state.loadMoreFailed, isTrue);
      expect(state.isLoadingMore, isFalse);

      // Retry succeeds and clears the flag.
      await notifier.loadMore();
      state = container.read(albumListControllerProvider(arg)).value!;
      expect(state.items, hasLength(120));
      expect(state.loadMoreFailed, isFalse);
    },
  );
}
