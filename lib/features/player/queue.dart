import 'dart:math';

import '../../domain/domain.dart';
import 'player_types.dart';

class QueueData {
  const QueueData({
    required this.defaultOrder,
    required this.shuffled,
    required this.songs,
  });

  factory QueueData.empty() =>
      const QueueData(defaultOrder: [], shuffled: [], songs: {});

  /// Mirrors `QueueData.default`; renamed because `default` is reserved in Dart.
  final List<String> defaultOrder;
  final List<int> shuffled;
  final Map<String, QueueSong> songs;

  QueueData copyWith({
    List<String>? defaultOrder,
    List<int>? shuffled,
    Map<String, QueueSong>? songs,
  }) => QueueData(
    defaultOrder: defaultOrder ?? this.defaultOrder,
    shuffled: shuffled ?? this.shuffled,
    songs: songs ?? this.songs,
  );
}

class QueueOrder {
  const QueueOrder({required this.groups, required this.items});

  final List<QueueGroup> groups;
  final List<QueueSong> items;
}

class QueueGroup {
  const QueueGroup({required this.count, required this.name});

  final int count;
  final String name;
}

class DualPlayerSongs {
  const DualPlayerSongs({required this.player1, required this.player2});

  final QueueSong? player1;
  final QueueSong? player2;
}

class NextIndexResult {
  const NextIndexResult({required this.nextIndex, required this.shouldPause});

  final int nextIndex;
  final bool shouldPause;
}

class PlayerData {
  const PlayerData({
    required this.currentSong,
    required this.index,
    required this.nextSong,
    required this.num,
    required this.player1,
    required this.player2,
    required this.previousSong,
    required this.queueLength,
    required this.status,
  });

  final QueueSong? currentSong;
  final int index;
  final QueueSong? nextSong;
  final int num;
  final QueueSong? player1;
  final QueueSong? player2;
  final QueueSong? previousSong;
  final int queueLength;
  final PlayerStatus status;
}

class PlayerQueueSnapshot {
  const PlayerQueueSnapshot({
    required this.index,
    required this.playerNum,
    required this.repeat,
    required this.shuffle,
    required this.status,
    required this.queue,
  });

  final int index;
  final int playerNum;
  final PlayerRepeat repeat;
  final PlayerShuffle shuffle;
  final PlayerStatus status;
  final QueueData queue;

  bool get isShuffleEnabled =>
      shuffle == PlayerShuffle.track && queue.shuffled.isNotEmpty;
}

QueueOrder getQueueOrder(QueueData queue) {
  final items = <QueueSong>[];
  for (final id in queue.defaultOrder) {
    final song = queue.songs[id];
    if (song != null) {
      items.add(song);
    }
  }

  return QueueOrder(
    groups: [QueueGroup(count: items.length, name: 'All')],
    items: items,
  );
}

QueueSong? calculateNextSong(
  int currentIndex,
  List<QueueSong> queueItems,
  PlayerRepeat repeat,
) {
  if (queueItems.isEmpty) {
    return null;
  }

  if (repeat == PlayerRepeat.one) {
    return _itemAtOrNull(queueItems, currentIndex);
  }

  final isLastTrack = currentIndex == queueItems.length - 1;
  if (repeat == PlayerRepeat.all) {
    return isLastTrack
        ? queueItems.first
        : _itemAtOrNull(queueItems, currentIndex + 1);
  }

  return _itemAtOrNull(queueItems, currentIndex + 1);
}

DualPlayerSongs getDualPlayerSongs({
  required int playerNum,
  required QueueSong? currentSong,
  required QueueSong? nextSong,
  required PlayerRepeat repeat,
}) {
  if (repeat == PlayerRepeat.one) {
    return DualPlayerSongs(
      player1: playerNum == 1 ? currentSong : null,
      player2: playerNum == 2 ? currentSong : null,
    );
  }

  return DualPlayerSongs(
    player1: playerNum == 1 ? currentSong : nextSong,
    player2: playerNum == 2 ? currentSong : nextSong,
  );
}

bool isShuffleEnabled({
  required PlayerShuffle shuffle,
  required List<int> shuffled,
}) => shuffle == PlayerShuffle.track && shuffled.isNotEmpty;

int mapShuffledToQueueIndex(int shuffledIndex, List<int> shuffled) {
  if (shuffledIndex >= 0 && shuffledIndex < shuffled.length) {
    return shuffled[shuffledIndex];
  }

  return shuffledIndex;
}

List<int> addIndexesToShuffled({
  required List<int> shuffled,
  required int currentShuffledIndex,
  required List<int> newIndexes,
  Random? random,
}) {
  final beforeCurrent = shuffled.sublist(0, currentShuffledIndex + 1);
  final afterCurrent = shuffled.sublist(currentShuffledIndex + 1);
  final toShuffle = [...afterCurrent, ...newIndexes];

  return [...beforeCurrent, ...shuffleInPlace(toShuffle, random: random)];
}

List<int> adjustShuffledIndexesForInsertion({
  required List<int> shuffled,
  required int insertPosition,
  required int insertCount,
}) => [
  for (final index in shuffled)
    if (index >= insertPosition) index + insertCount else index,
];

NextIndexResult calculateNextIndex({
  required int currentIndex,
  required int queueLength,
  required PlayerRepeat repeat,
}) {
  if (queueLength <= 0) {
    return const NextIndexResult(nextIndex: -1, shouldPause: true);
  }

  final clampedCurrentIndex = currentIndex.clamp(0, queueLength - 1).toInt();
  final isLastTrack = clampedCurrentIndex == queueLength - 1;

  if (repeat == PlayerRepeat.one) {
    return NextIndexResult(nextIndex: clampedCurrentIndex, shouldPause: false);
  }

  if (repeat == PlayerRepeat.all) {
    return NextIndexResult(
      nextIndex: isLastTrack ? 0 : clampedCurrentIndex + 1,
      shouldPause: false,
    );
  }

  if (isLastTrack) {
    return NextIndexResult(nextIndex: clampedCurrentIndex, shouldPause: true);
  }

  return NextIndexResult(
    nextIndex: clampedCurrentIndex + 1,
    shouldPause: false,
  );
}

int? findShuffledPositionForQueueIndex(int queueIndex, List<int> shuffled) {
  final shuffledPosition = shuffled.indexOf(queueIndex);
  return shuffledPosition == -1 ? null : shuffledPosition;
}

List<int> generateShuffledIndexes(int length, {Random? random}) {
  final indexes = List<int>.generate(length, (index) => index);
  return shuffleInPlace(indexes, random: random);
}

List<T> shuffleInPlace<T>(List<T> items, {Random? random}) {
  final generator = random ?? Random.secure();
  for (var i = items.length - 1; i > 0; i--) {
    final j = generator.nextInt(i + 1);
    final temp = items[i];
    items[i] = items[j];
    items[j] = temp;
  }
  return items;
}

PlayerData getPlayerData(PlayerQueueSnapshot state) {
  final queue = getQueueOrder(state.queue);
  final index = state.index;

  var queueIndex = index;
  if (state.isShuffleEnabled) {
    queueIndex = mapShuffledToQueueIndex(index, state.queue.shuffled);
  }

  final currentSong = _itemAtOrNull(queue.items, queueIndex);
  final previousSong = _previousSong(
    queueItems: queue.items,
    playbackIndex: index,
    queueIndex: queueIndex,
    repeat: state.repeat,
    shuffled: state.queue.shuffled,
    shuffleEnabled: state.isShuffleEnabled,
  );
  final nextSong = _nextSong(
    queueItems: queue.items,
    playbackIndex: index,
    queueIndex: queueIndex,
    repeat: state.repeat,
    shuffled: state.queue.shuffled,
    shuffleEnabled: state.isShuffleEnabled,
  );
  final dualPlayers = getDualPlayerSongs(
    playerNum: state.playerNum,
    currentSong: currentSong,
    nextSong: nextSong,
    repeat: state.repeat,
  );

  return PlayerData(
    currentSong: currentSong,
    index: queueIndex,
    nextSong: nextSong,
    num: state.playerNum,
    player1: dualPlayers.player1,
    player2: dualPlayers.player2,
    previousSong: previousSong,
    queueLength: state.queue.defaultOrder.length,
    status: state.status,
  );
}

int mediaNextIndex({
  required int currentIndex,
  required int queueLength,
  required PlayerRepeat repeat,
}) {
  final isLastTrack = currentIndex == queueLength - 1;
  if (repeat == PlayerRepeat.all && isLastTrack) {
    return 0;
  }

  if (repeat == PlayerRepeat.none && isLastTrack) {
    return currentIndex;
  }

  return min(queueLength - 1, currentIndex + 1);
}

int mediaPreviousIndex({
  required int currentIndex,
  required int queueLength,
  required PlayerRepeat repeat,
}) {
  final isFirstTrack = currentIndex == 0;
  if (repeat == PlayerRepeat.all && isFirstTrack) {
    return queueLength - 1;
  }

  if (repeat == PlayerRepeat.none && isFirstTrack) {
    return currentIndex;
  }

  return max(0, currentIndex - 1);
}

PlayerRepeat toggleRepeat(PlayerRepeat repeat) => switch (repeat) {
  PlayerRepeat.none => PlayerRepeat.one,
  PlayerRepeat.one => PlayerRepeat.all,
  PlayerRepeat.all => PlayerRepeat.none,
};

QueueSong? _nextSong({
  required List<QueueSong> queueItems,
  required int playbackIndex,
  required int queueIndex,
  required PlayerRepeat repeat,
  required List<int> shuffled,
  required bool shuffleEnabled,
}) {
  if (shuffleEnabled && repeat != PlayerRepeat.one) {
    final nextShuffledIndex = playbackIndex + 1;
    if (nextShuffledIndex < shuffled.length) {
      return _itemAtOrNull(queueItems, shuffled[nextShuffledIndex]);
    }

    if (repeat == PlayerRepeat.all && shuffled.isNotEmpty) {
      return _itemAtOrNull(queueItems, shuffled.first);
    }

    return null;
  }

  return calculateNextSong(queueIndex, queueItems, repeat);
}

QueueSong? _previousSong({
  required List<QueueSong> queueItems,
  required int playbackIndex,
  required int queueIndex,
  required PlayerRepeat repeat,
  required List<int> shuffled,
  required bool shuffleEnabled,
}) {
  if (shuffleEnabled) {
    final previousShuffledIndex = playbackIndex - 1;
    if (previousShuffledIndex >= 0) {
      return _itemAtOrNull(queueItems, shuffled[previousShuffledIndex]);
    }

    if (repeat == PlayerRepeat.all && shuffled.isNotEmpty) {
      return _itemAtOrNull(queueItems, shuffled.last);
    }

    return null;
  }

  return queueIndex > 0 ? _itemAtOrNull(queueItems, queueIndex - 1) : null;
}

T? _itemAtOrNull<T>(List<T> items, int index) {
  if (index < 0 || index >= items.length) {
    return null;
  }

  return items[index];
}
