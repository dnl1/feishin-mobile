import 'package:feishin_mobile/data/music_server_repository.dart';
import 'package:feishin_mobile/data/repository_provider.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:feishin_mobile/features/player/player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repository.dart';

void main() {
  ProviderContainer buildContainer({MusicServerRepository? repository}) {
    var counter = 0;
    final container = ProviderContainer(
      overrides: [
        uniqueIdGeneratorProvider.overrideWithValue(() => 'q-${counter++}'),
        if (repository != null)
          musicServerRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  PlayerController controller(ProviderContainer container) =>
      container.read(playerControllerProvider.notifier);

  PlayerState playerState(ProviderContainer container) =>
      container.read(playerControllerProvider);

  group('PlayerController', () {
    test('setQueue starts playback and exposes PlayerData', () {
      final container = buildContainer();
      final player = controller(container);

      player.setQueue([
        makeSong('s-1', name: 'One'),
        makeSong('s-2', name: 'Two'),
      ]);

      final state = playerState(container);
      expect(state.status, PlayerStatus.playing);
      expect(state.index, 0);
      expect(state.queue.defaultOrder, ['q-0', 'q-1']);

      final data = player.getPlayerData();
      expect(data.currentSong?.song.name, 'One');
      expect(data.nextSong?.song.name, 'Two');
      expect(data.queueLength, 2);
    });

    test('addToQueueByType appends and inserts next in default order', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([makeSong('s-1'), makeSong('s-2')]);

      player.addToQueueByType([makeSong('s-3')], PlayMode.last);
      expect(playerState(container).queue.defaultOrder, ['q-0', 'q-1', 'q-2']);

      player.addToQueueByType([makeSong('s-4')], PlayMode.next);
      expect(playerState(container).queue.defaultOrder, [
        'q-0',
        'q-3',
        'q-1',
        'q-2',
      ]);
    });

    test('add now replaces the queue and can start on a requested song id', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([makeSong('old')]);

      player.addToQueueByType(
        [makeSong('s-1'), makeSong('s-2'), makeSong('s-3')],
        PlayMode.now,
        playSongId: 's-2',
      );

      final state = playerState(container);
      expect(state.queue.defaultOrder, ['q-1', 'q-2', 'q-3']);
      expect(state.index, 1);
      expect(player.getCurrentSong()?.song.id, 's-2');
      expect(state.status, PlayerStatus.playing);
    });

    test(
      'toggleShuffle keeps the current song first then restores queue index',
      () {
        final container = buildContainer();
        final player = controller(container);
        player.setQueue([makeSong('s-1'), makeSong('s-2'), makeSong('s-3')]);
        player.mediaPlayByIndex(1);

        player.toggleShuffle();
        var state = playerState(container);
        expect(state.shuffle, PlayerShuffle.track);
        expect(state.index, 0);
        expect(state.queue.shuffled.first, 1);
        expect(player.getCurrentSong()?.song.id, 's-2');

        player.toggleShuffle();
        state = playerState(container);
        expect(state.shuffle, PlayerShuffle.none);
        expect(state.index, 1);
        expect(state.queue.shuffled, isEmpty);
        expect(player.getCurrentSong()?.song.id, 's-2');
      },
    );

    test('mediaAutoNext advances in shuffled order and swaps player slots', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([makeSong('s-1'), makeSong('s-2'), makeSong('s-3')]);
      player.toggleShuffle();

      final firstState = playerState(container);
      expect(firstState.index, 0);
      expect(firstState.playerNum, 1);

      final data = player.mediaAutoNext();
      final state = playerState(container);

      expect(state.index, 1);
      expect(state.playerNum, 2);
      expect(state.status, PlayerStatus.playing);
      expect(
        data.currentSong?.uniqueId,
        state.queue.defaultOrder[state.queue.shuffled[1]],
      );
    });

    test('repeat one auto-next keeps player slot and current index', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([makeSong('s-1'), makeSong('s-2')]);
      player.setRepeat(PlayerRepeat.one);

      player.mediaAutoNext();

      final state = playerState(container);
      expect(state.index, 0);
      expect(state.playerNum, 1);
      expect(state.status, PlayerStatus.playing);
    });

    test('pause-on-next pauses once and clears the flag', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([makeSong('s-1'), makeSong('s-2')]);
      player.setPauseOnNextSongEnd(true);

      player.mediaAutoNext();

      final state = playerState(container);
      expect(state.index, 1);
      expect(state.status, PlayerStatus.paused);
      expect(state.pauseOnNextSongEnd, isFalse);
    });

    test('clearSelected removes queue songs and prunes orphaned song map', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([makeSong('s-1'), makeSong('s-2'), makeSong('s-3')]);
      final selected = player.getQueueOrder().items[1];

      player.clearSelected([selected]);

      final state = playerState(container);
      expect(state.queue.defaultOrder, ['q-0', 'q-2']);
      expect(state.queue.songs.keys, ['q-0', 'q-2']);
    });

    test('moveSelectedToTop and bottom reorder while keeping current song', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([
        makeSong('s-1'),
        makeSong('s-2'),
        makeSong('s-3'),
        makeSong('s-4'),
      ]);
      player.mediaPlayByIndex(2);
      final queue = player.getQueueOrder().items;

      player.moveSelectedToTop([queue[3]]);
      expect(playerState(container).queue.defaultOrder, [
        'q-3',
        'q-0',
        'q-1',
        'q-2',
      ]);
      expect(player.getCurrentSong()?.song.id, 's-3');

      player.moveSelectedToBottom([queue[0]]);
      expect(playerState(container).queue.defaultOrder, [
        'q-3',
        'q-1',
        'q-2',
        'q-0',
      ]);
      expect(player.getCurrentSong()?.song.id, 's-3');
    });

    test('moveSelectedToNext places items after the current track', () {
      final container = buildContainer();
      final player = controller(container);
      player.setQueue([
        makeSong('s-1'),
        makeSong('s-2'),
        makeSong('s-3'),
        makeSong('s-4'),
      ]);
      player.mediaPlayByIndex(1);
      final queue = player.getQueueOrder().items;

      player.moveSelectedToNext([queue[3]]);

      expect(playerState(container).queue.defaultOrder, [
        'q-0',
        'q-1',
        'q-3',
        'q-2',
      ]);
      expect(player.getCurrentSong()?.song.id, 's-2');
    });

    test('volume and speed are clamped to player limits', () {
      final container = buildContainer();
      final player = controller(container);

      player.setVolume(130);
      player.setSpeed(3);
      expect(playerState(container).volume, 100);
      expect(playerState(container).speed, 2);

      player.decreaseVolume(150);
      player.setSpeed(0.1);
      expect(playerState(container).volume, 0);
      expect(playerState(container).speed, 0.5);
    });

    test(
      'restoreQueueFromServer replaces queue and returns saved position',
      () async {
        final repository = FakeQueueRepository(
          queue: ServerPlayQueue(
            changed: '2026-07-07T10:00:00Z',
            changedBy: 'demo',
            currentIndex: 1,
            entry: [makeSong('s-1'), makeSong('s-2')],
            positionMs: 12345,
            username: 'demo',
          ),
        );
        final container = buildContainer(repository: repository);
        final player = controller(container);

        final queue = await player.restoreQueueFromServer();

        expect(queue.positionMs, 12345);
        expect(player.getCurrentSong()?.song.id, 's-2');
        expect(playerState(container).queue.defaultOrder, ['q-0', 'q-1']);
        expect(playerState(container).status, PlayerStatus.playing);
      },
    );

    test('saveQueueToServer sends song ids, index and position', () async {
      final repository = FakeQueueRepository();
      final container = buildContainer(repository: repository);
      final player = controller(container);
      player.setQueue([makeSong('s-1'), makeSong('s-2')]);
      player.mediaPlayByIndex(1);

      await player.saveQueueToServer(positionMs: 99000);

      expect(repository.savedSongIds, ['s-1', 's-2']);
      expect(repository.savedCurrentIndex, 1);
      expect(repository.savedPositionMs, 99000);
    });

    test('saveQueueToServer rejects queues from another server', () async {
      final repository = FakeQueueRepository();
      final container = buildContainer(repository: repository);
      final player = controller(container);
      player.setQueue([makeSong('s-1').copyWith(serverId: 'other')]);

      expect(() => player.saveQueueToServer(), throwsA(isA<StateError>()));
    });
  });
}

class FakeQueueRepository implements MusicServerRepository {
  FakeQueueRepository({ServerPlayQueue? queue})
    : queue =
          queue ??
          const ServerPlayQueue(
            changed: null,
            changedBy: null,
            currentIndex: 0,
            entry: [],
            positionMs: null,
            username: 'demo',
          );

  final ServerPlayQueue queue;
  List<String>? savedSongIds;
  int? savedCurrentIndex;
  int? savedPositionMs;

  @override
  ServerConfig get server => ServerConfig(
    id: 'srv-1',
    name: 'Fake',
    type: ServerType.navidrome,
    url: 'https://fake.example.com',
    userId: 'u1',
    username: 'demo',
  );

  @override
  Future<ServerPlayQueue> getPlayQueue() async => queue;

  @override
  Future<void> savePlayQueue({
    required List<String> songIds,
    int? currentIndex,
    int? positionMs,
  }) async {
    savedSongIds = songIds;
    savedCurrentIndex = currentIndex;
    savedPositionMs = positionMs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}
