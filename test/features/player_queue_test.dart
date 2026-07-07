import 'dart:math';

import 'package:feishin_mobile/domain/domain.dart';
import 'package:feishin_mobile/features/player/player.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repository.dart';

void main() {
  group('player queue helpers', () {
    test(
      'calculateNextSong follows repeat semantics from the Electron store',
      () {
        final songs = [_queueSong('a'), _queueSong('b'), _queueSong('c')];

        expect(calculateNextSong(0, songs, PlayerRepeat.none)?.uniqueId, 'b');
        expect(calculateNextSong(2, songs, PlayerRepeat.none), isNull);
        expect(calculateNextSong(2, songs, PlayerRepeat.all)?.uniqueId, 'a');
        expect(calculateNextSong(1, songs, PlayerRepeat.one)?.uniqueId, 'b');
        expect(calculateNextSong(0, const [], PlayerRepeat.all), isNull);
      },
    );

    test('calculateNextIndex returns pause flag at the end without repeat', () {
      expect(
        calculateNextIndex(
          currentIndex: 2,
          queueLength: 3,
          repeat: PlayerRepeat.none,
        ).shouldPause,
        isTrue,
      );
      expect(
        calculateNextIndex(
          currentIndex: 2,
          queueLength: 3,
          repeat: PlayerRepeat.all,
        ).nextIndex,
        0,
      );
      expect(
        calculateNextIndex(
          currentIndex: 1,
          queueLength: 3,
          repeat: PlayerRepeat.one,
        ).nextIndex,
        1,
      );
    });

    test(
      'getPlayerData maps shuffled playback positions to queue positions',
      () {
        final queue = _queue(['a', 'b', 'c'], shuffled: [2, 0, 1]);
        final data = getPlayerData(
          PlayerQueueSnapshot(
            index: 1,
            playerNum: 1,
            repeat: PlayerRepeat.all,
            shuffle: PlayerShuffle.track,
            status: PlayerStatus.playing,
            queue: queue,
          ),
        );

        expect(data.currentSong?.uniqueId, 'a');
        expect(data.index, 0);
        expect(data.previousSong?.uniqueId, 'c');
        expect(data.nextSong?.uniqueId, 'b');
        expect(data.player1?.uniqueId, 'a');
        expect(data.player2?.uniqueId, 'b');
      },
    );

    test('repeat one keeps the same dual-player slot primed', () {
      final queue = _queue(['a', 'b']);
      final data = getPlayerData(
        PlayerQueueSnapshot(
          index: 1,
          playerNum: 2,
          repeat: PlayerRepeat.one,
          shuffle: PlayerShuffle.none,
          status: PlayerStatus.playing,
          queue: queue,
        ),
      );

      expect(data.currentSong?.uniqueId, 'b');
      expect(data.nextSong?.uniqueId, 'b');
      expect(data.player1, isNull);
      expect(data.player2?.uniqueId, 'b');
    });

    test(
      'shuffle insertion helpers preserve current position and adjust indexes',
      () {
        expect(
          adjustShuffledIndexesForInsertion(
            shuffled: [3, 0, 2],
            insertPosition: 2,
            insertCount: 2,
          ),
          [5, 0, 4],
        );

        final result = addIndexesToShuffled(
          shuffled: [2, 0, 1],
          currentShuffledIndex: 1,
          newIndexes: [3, 4],
          random: Random(7),
        );

        expect(result.take(2), [2, 0]);
        expect(result.skip(2).toSet(), {1, 3, 4});
      },
    );

    test('manual next and previous match store edge behavior', () {
      expect(
        mediaNextIndex(
          currentIndex: 2,
          queueLength: 3,
          repeat: PlayerRepeat.none,
        ),
        2,
      );
      expect(
        mediaNextIndex(
          currentIndex: 2,
          queueLength: 3,
          repeat: PlayerRepeat.all,
        ),
        0,
      );
      expect(
        mediaPreviousIndex(
          currentIndex: 0,
          queueLength: 3,
          repeat: PlayerRepeat.all,
        ),
        2,
      );
      expect(toggleRepeat(PlayerRepeat.none), PlayerRepeat.one);
      expect(toggleRepeat(PlayerRepeat.one), PlayerRepeat.all);
      expect(toggleRepeat(PlayerRepeat.all), PlayerRepeat.none);
    });
  });
}

QueueData _queue(List<String> ids, {List<int> shuffled = const []}) {
  return QueueData(
    defaultOrder: ids,
    shuffled: shuffled,
    songs: {for (final id in ids) id: _queueSong(id)},
  );
}

QueueSong _queueSong(String id) => QueueSong(song: makeSong(id), uniqueId: id);
