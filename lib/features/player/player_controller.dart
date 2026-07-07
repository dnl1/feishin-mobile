import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/music_server_repository.dart';
import '../../data/repository_provider.dart';
import '../../domain/domain.dart';
import 'player_types.dart';
import 'queue.dart' as player_queue;

typedef UniqueIdGenerator = String Function();

final uniqueIdGeneratorProvider = Provider<UniqueIdGenerator>(
  (_) => _generateUniqueId,
);

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

class PlayerState {
  const PlayerState({
    required this.index,
    required this.muted,
    required this.pauseOnNextSongEnd,
    required this.playerNum,
    required this.repeat,
    required this.shuffle,
    required this.speed,
    required this.status,
    required this.volume,
    required this.queue,
  });

  factory PlayerState.initial() => PlayerState(
    index: -1,
    muted: false,
    pauseOnNextSongEnd: false,
    playerNum: 1,
    repeat: PlayerRepeat.none,
    shuffle: PlayerShuffle.none,
    speed: 1,
    status: PlayerStatus.paused,
    volume: 30,
    queue: player_queue.QueueData.empty(),
  );

  final int index;
  final bool muted;
  final bool pauseOnNextSongEnd;
  final int playerNum;
  final PlayerRepeat repeat;
  final PlayerShuffle shuffle;
  final double speed;
  final PlayerStatus status;
  final int volume;
  final player_queue.QueueData queue;

  bool get isShuffleEnabled =>
      shuffle == PlayerShuffle.track && queue.shuffled.isNotEmpty;

  PlayerState copyWith({
    int? index,
    bool? muted,
    bool? pauseOnNextSongEnd,
    int? playerNum,
    PlayerRepeat? repeat,
    PlayerShuffle? shuffle,
    double? speed,
    PlayerStatus? status,
    int? volume,
    player_queue.QueueData? queue,
  }) => PlayerState(
    index: index ?? this.index,
    muted: muted ?? this.muted,
    pauseOnNextSongEnd: pauseOnNextSongEnd ?? this.pauseOnNextSongEnd,
    playerNum: playerNum ?? this.playerNum,
    repeat: repeat ?? this.repeat,
    shuffle: shuffle ?? this.shuffle,
    speed: speed ?? this.speed,
    status: status ?? this.status,
    volume: volume ?? this.volume,
    queue: queue ?? this.queue,
  );

  player_queue.PlayerQueueSnapshot get snapshot =>
      player_queue.PlayerQueueSnapshot(
        index: index,
        playerNum: playerNum,
        repeat: repeat,
        shuffle: shuffle,
        status: status,
        queue: queue,
      );
}

class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() => PlayerState.initial();

  player_queue.QueueOrder getQueueOrder() =>
      player_queue.getQueueOrder(state.queue);

  QueueSong? getCurrentSong() {
    final queue = getQueueOrder();
    var queueIndex = state.index;
    if (state.isShuffleEnabled) {
      queueIndex = player_queue.mapShuffledToQueueIndex(
        state.index,
        state.queue.shuffled,
      );
    }
    return _itemAtOrNull(queue.items, queueIndex);
  }

  player_queue.PlayerData getPlayerData() =>
      player_queue.getPlayerData(state.snapshot);

  void setQueue(List<Song> songs, {int index = 0}) {
    final queueSongs = songs.map(_toQueueSong).toList();
    final uniqueIds = queueSongs.map((song) => song.uniqueId).toList();

    state = state.copyWith(
      index: songs.isEmpty ? -1 : index.clamp(0, songs.length - 1).toInt(),
      playerNum: 1,
      status: songs.isEmpty ? PlayerStatus.paused : PlayerStatus.playing,
      queue: player_queue.QueueData(
        defaultOrder: uniqueIds,
        shuffled: state.shuffle == PlayerShuffle.track
            ? player_queue.generateShuffledIndexes(uniqueIds.length)
            : const [],
        songs: {for (final song in queueSongs) song.uniqueId: song},
      ),
    );
  }

  void addToQueueByType(
    List<Song> songs,
    PlayMode playMode, {
    String? playSongId,
  }) {
    if (songs.isEmpty) {
      return;
    }

    final queueSongs = songs.map(_toQueueSong).toList();
    final targetUniqueId = playSongId == null
        ? null
        : queueSongs
              .where((song) => song.song.id == playSongId)
              .firstOrNull
              ?.uniqueId;

    switch (playMode) {
      case PlayMode.byIndex:
        return;
      case PlayMode.last:
        _append(queueSongs, shuffleIncoming: false);
      case PlayMode.lastShuffle:
        _append(queueSongs, shuffleIncoming: true);
      case PlayMode.next:
        _insertNext(queueSongs, shuffleIncoming: false);
      case PlayMode.nextShuffle:
        _insertNext(queueSongs, shuffleIncoming: true);
      case PlayMode.now:
        _replaceQueue(queueSongs, targetUniqueId: targetUniqueId);
      case PlayMode.shuffle:
        _replaceQueue(
          player_queue.shuffleInPlace([...queueSongs]),
          alwaysGenerateShuffled: true,
          targetUniqueId: targetUniqueId,
        );
    }

    if (targetUniqueId != null) {
      mediaPlay(targetUniqueId);
    }
  }

  void clearQueue() {
    state = state.copyWith(
      index: -1,
      queue: player_queue.QueueData.empty(),
      status: PlayerStatus.paused,
    );
  }

  void clearSelected(List<QueueSong> items) {
    final uniqueIds = items.map((item) => item.uniqueId).toSet();
    final indexesToRemove = <int>{};
    for (var index = 0; index < state.queue.defaultOrder.length; index++) {
      if (uniqueIds.contains(state.queue.defaultOrder[index])) {
        indexesToRemove.add(index);
      }
    }

    final defaultOrder = state.queue.defaultOrder
        .where((id) => !uniqueIds.contains(id))
        .toList();
    final shuffled = state.isShuffleEnabled
        ? [
            for (final index in state.queue.shuffled)
              if (!indexesToRemove.contains(index))
                index -
                    indexesToRemove.where((removed) => removed < index).length,
          ]
        : <int>[];
    final songs = {
      for (final id in defaultOrder)
        if (state.queue.songs[id] != null) id: state.queue.songs[id]!,
    };
    final newState = state.copyWith(
      queue: player_queue.QueueData(
        defaultOrder: defaultOrder,
        shuffled: shuffled,
        songs: songs,
      ),
    );

    state = _keepCurrentSongIndex(newState, defaultOrder);
  }

  void moveSelectedTo(List<QueueSong> items, String uniqueId, QueueEdge edge) {
    final itemUniqueIds = items.map((item) => item.uniqueId).toList();
    final targetIndex = state.queue.defaultOrder.indexOf(uniqueId);
    final insertIndex = max(
      0,
      edge == QueueEdge.top ? targetIndex : targetIndex + 1,
    );
    final idsBefore = state.queue.defaultOrder
        .sublist(0, insertIndex)
        .where((id) => !itemUniqueIds.contains(id));
    final idsAfter = state.queue.defaultOrder
        .sublist(insertIndex)
        .where((id) => !itemUniqueIds.contains(id));

    _replaceDefaultOrder([
      ...idsBefore,
      ...itemUniqueIds,
      ...idsAfter,
    ], additionalSongs: items);
  }

  void moveSelectedToBottom(List<QueueSong> items) {
    final itemUniqueIds = items.map((item) => item.uniqueId).toList();
    final filtered = state.queue.defaultOrder.where(
      (id) => !itemUniqueIds.contains(id),
    );

    _replaceDefaultOrder([
      ...filtered,
      ...itemUniqueIds,
    ], additionalSongs: items);
  }

  void moveSelectedToNext(List<QueueSong> items) {
    final itemUniqueIds = items.map((item) => item.uniqueId).toList();
    var movedBeforeCurrent = 0;
    final filtered = <String>[];

    for (var index = 0; index < state.queue.defaultOrder.length; index++) {
      final id = state.queue.defaultOrder[index];
      final shouldMove = itemUniqueIds.contains(id);
      if (shouldMove && index < state.index) {
        movedBeforeCurrent++;
      }
      if (!shouldMove) {
        filtered.add(id);
      }
    }

    final insertIndex = max(
      0,
      state.index + 1 - movedBeforeCurrent,
    ).clamp(0, filtered.length).toInt();
    _replaceDefaultOrder([
      ...filtered.sublist(0, insertIndex),
      ...itemUniqueIds,
      ...filtered.sublist(insertIndex),
    ], additionalSongs: items);
  }

  void moveSelectedToTop(List<QueueSong> items) {
    final itemUniqueIds = items.map((item) => item.uniqueId).toList();
    final filtered = state.queue.defaultOrder.where(
      (id) => !itemUniqueIds.contains(id),
    );

    _replaceDefaultOrder([
      ...itemUniqueIds,
      ...filtered,
    ], additionalSongs: items);
  }

  Future<ServerPlayQueue> restoreQueueFromServer() async {
    final repository = await _readRepository();
    final queue = await repository.getPlayQueue();
    setQueue(queue.entry, index: queue.currentIndex);
    return queue;
  }

  Future<void> saveQueueToServer({int positionMs = 0}) async {
    final repository = await _readRepository();
    final queue = getQueueOrder();

    if (queue.items.any((item) => item.song.serverId != repository.server.id)) {
      throw StateError('Cannot save a queue with songs from multiple servers');
    }

    await repository.savePlayQueue(
      songIds: queue.items.map((item) => item.song.id).toList(),
      currentIndex: queue.items.isEmpty ? null : state.index,
      positionMs: positionMs,
    );
  }

  void mediaPlay([String? uniqueId]) {
    if (uniqueId == null) {
      state = state.copyWith(status: PlayerStatus.playing);
      return;
    }

    final queue = getQueueOrder();
    final queueIndex = queue.items.indexWhere(
      (song) => song.uniqueId == uniqueId,
    );
    if (queueIndex == -1) {
      return;
    }

    final playbackIndex = state.isShuffleEnabled
        ? player_queue.findShuffledPositionForQueueIndex(
                queueIndex,
                state.queue.shuffled,
              ) ??
              queueIndex
        : queueIndex;

    state = state.copyWith(index: playbackIndex, status: PlayerStatus.playing);
  }

  void mediaPlayByIndex(int index) {
    final queue = getQueueOrder();
    if (index < 0 || index >= queue.items.length) {
      state = state.copyWith(status: PlayerStatus.paused);
      return;
    }

    final playbackIndex = state.isShuffleEnabled
        ? player_queue.findShuffledPositionForQueueIndex(
                index,
                state.queue.shuffled,
              ) ??
              index
        : index;

    state = state.copyWith(index: playbackIndex, status: PlayerStatus.playing);
  }

  void mediaPause() => state = state.copyWith(status: PlayerStatus.paused);

  void mediaTogglePlayPause() {
    state = state.copyWith(
      status: state.status == PlayerStatus.playing
          ? PlayerStatus.paused
          : PlayerStatus.playing,
    );
  }

  void mediaStop() => state = state.copyWith(status: PlayerStatus.stopped);

  player_queue.PlayerData mediaAutoNext() {
    final playbackLength = state.isShuffleEnabled
        ? state.queue.shuffled.length
        : getQueueOrder().items.length;
    final next = player_queue.calculateNextIndex(
      currentIndex: state.index,
      queueLength: playbackLength,
      repeat: state.repeat,
    );
    final repeatOneSameTrack =
        state.repeat == PlayerRepeat.one && next.nextIndex == state.index;
    final newStatus = next.shouldPause || state.pauseOnNextSongEnd
        ? PlayerStatus.paused
        : PlayerStatus.playing;
    final shouldSwapPlayer =
        !repeatOneSameTrack && newStatus != PlayerStatus.paused;

    state = state.copyWith(
      index: next.nextIndex,
      playerNum: shouldSwapPlayer ? _otherPlayerNum(state.playerNum) : null,
      status: newStatus,
      pauseOnNextSongEnd: false,
    );

    return getPlayerData();
  }

  void mediaNext() {
    final queueLength = state.isShuffleEnabled
        ? state.queue.shuffled.length
        : getQueueOrder().items.length;
    state = state.copyWith(
      index: player_queue.mediaNextIndex(
        currentIndex: state.index,
        queueLength: queueLength,
        repeat: state.repeat,
      ),
      playerNum: 1,
    );
  }

  void mediaPrevious({double currentTimestamp = 0}) {
    if (currentTimestamp > 10) {
      return;
    }

    final queueLength = state.isShuffleEnabled
        ? state.queue.shuffled.length
        : getQueueOrder().items.length;
    state = state.copyWith(
      index: player_queue.mediaPreviousIndex(
        currentIndex: state.index,
        queueLength: queueLength,
        repeat: state.repeat,
      ),
      playerNum: 1,
    );
  }

  void setPauseOnNextSongEnd(bool value) {
    state = state.copyWith(pauseOnNextSongEnd: value);
  }

  void setRepeat(PlayerRepeat repeat) {
    state = state.copyWith(repeat: repeat);
  }

  void toggleRepeat() {
    state = state.copyWith(repeat: player_queue.toggleRepeat(state.repeat));
  }

  void setShuffle(PlayerShuffle shuffle) {
    final wasShuffled = state.shuffle == PlayerShuffle.track;
    final willBeShuffled = shuffle == PlayerShuffle.track;
    final currentIndex = state.index;

    if (willBeShuffled) {
      final shuffled = player_queue.generateShuffledIndexes(
        state.queue.defaultOrder.length,
      );
      final shuffledPosition =
          currentIndex >= 0 && currentIndex < state.queue.defaultOrder.length
          ? player_queue.findShuffledPositionForQueueIndex(
              currentIndex,
              shuffled,
            )
          : null;
      state = state.copyWith(
        index: shuffledPosition ?? currentIndex,
        shuffle: shuffle,
        queue: state.queue.copyWith(shuffled: shuffled),
      );
      return;
    }

    final queuePosition =
        wasShuffled &&
            currentIndex >= 0 &&
            currentIndex < state.queue.shuffled.length
        ? state.queue.shuffled[currentIndex]
        : currentIndex;

    state = state.copyWith(
      index: queuePosition,
      shuffle: shuffle,
      queue: state.queue.copyWith(shuffled: const []),
    );
  }

  void toggleShuffle() {
    if (state.shuffle == PlayerShuffle.track) {
      setShuffle(PlayerShuffle.none);
      return;
    }

    final currentIndex = state.index;
    final length = state.queue.defaultOrder.length;
    if (length > 0 && currentIndex >= 0 && currentIndex < length) {
      final remainingIndexes = List<int>.generate(
        length,
        (index) => index,
      ).where((index) => index != currentIndex).toList();
      final shuffled = [
        currentIndex,
        ...player_queue.shuffleInPlace(remainingIndexes),
      ];
      state = state.copyWith(
        index: 0,
        shuffle: PlayerShuffle.track,
        queue: state.queue.copyWith(shuffled: shuffled),
      );
      return;
    }

    setShuffle(PlayerShuffle.track);
  }

  void shuffleQueue() {
    if (state.shuffle == PlayerShuffle.track) {
      state = state.copyWith(
        queue: state.queue.copyWith(
          shuffled: player_queue.generateShuffledIndexes(
            state.queue.defaultOrder.length,
          ),
        ),
      );
    }
  }

  void setVolume(int volume) {
    state = state.copyWith(volume: volume.clamp(0, 100).toInt());
  }

  void increaseVolume(int value) => setVolume(state.volume + value);

  void decreaseVolume(int value) => setVolume(state.volume - value);

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed.clamp(0.5, 2).toDouble());
  }

  void mediaToggleMute() {
    state = state.copyWith(muted: !state.muted);
  }

  QueueSong _toQueueSong(Song song) =>
      QueueSong(song: song, uniqueId: ref.read(uniqueIdGeneratorProvider)());

  Future<MusicServerRepository> _readRepository() async {
    final repository = await ref.read(musicServerRepositoryProvider.future);
    if (repository == null) {
      throw StateError('Nenhum servidor selecionado');
    }
    return repository;
  }

  void _append(List<QueueSong> queueSongs, {required bool shuffleIncoming}) {
    final incoming = shuffleIncoming
        ? player_queue.shuffleInPlace([...queueSongs])
        : queueSongs;
    final newIds = incoming.map((song) => song.uniqueId).toList();
    final oldQueueLength = state.queue.defaultOrder.length;
    final shuffled = state.isShuffleEnabled
        ? [
            ...state.queue.shuffled,
            ...player_queue.shuffleInPlace(
              List<int>.generate(
                newIds.length,
                (index) => oldQueueLength + index,
              ),
            ),
          ]
        : state.queue.shuffled;

    state = state.copyWith(
      queue: player_queue.QueueData(
        defaultOrder: [...state.queue.defaultOrder, ...newIds],
        shuffled: shuffled,
        songs: {
          ...state.queue.songs,
          for (final song in incoming) song.uniqueId: song,
        },
      ),
    );
  }

  void _insertNext(
    List<QueueSong> queueSongs, {
    required bool shuffleIncoming,
  }) {
    final incoming = shuffleIncoming
        ? player_queue.shuffleInPlace([...queueSongs])
        : queueSongs;
    final newIds = incoming.map((song) => song.uniqueId).toList();
    final currentShuffledIndex = state.index;
    final hasCurrentShuffledIndex =
        currentShuffledIndex >= 0 &&
        currentShuffledIndex < state.queue.shuffled.length;
    final insertPosition = state.isShuffleEnabled && hasCurrentShuffledIndex
        ? state.queue.shuffled[currentShuffledIndex] + 1
        : state.index + 1;
    final safeInsertPosition = insertPosition
        .clamp(0, state.queue.defaultOrder.length)
        .toInt();
    final defaultOrder = [
      ...state.queue.defaultOrder.sublist(0, safeInsertPosition),
      ...newIds,
      ...state.queue.defaultOrder.sublist(safeInsertPosition),
    ];

    final adjustedShuffled = state.isShuffleEnabled
        ? player_queue.adjustShuffledIndexesForInsertion(
            shuffled: state.queue.shuffled,
            insertPosition: safeInsertPosition,
            insertCount: newIds.length,
          )
        : <int>[];
    final shuffled = state.isShuffleEnabled
        ? [
            ...adjustedShuffled.sublist(0, currentShuffledIndex + 1),
            ...player_queue.shuffleInPlace(
              List<int>.generate(
                newIds.length,
                (index) => safeInsertPosition + index,
              ),
            ),
            ...adjustedShuffled.sublist(currentShuffledIndex + 1),
          ]
        : state.queue.shuffled;

    state = state.copyWith(
      queue: player_queue.QueueData(
        defaultOrder: defaultOrder,
        shuffled: shuffled,
        songs: {
          ...state.queue.songs,
          for (final song in incoming) song.uniqueId: song,
        },
      ),
    );
  }

  void _replaceQueue(
    List<QueueSong> queueSongs, {
    String? targetUniqueId,
    bool alwaysGenerateShuffled = false,
  }) {
    final uniqueIds = queueSongs.map((song) => song.uniqueId).toList();
    final shouldShuffle =
        alwaysGenerateShuffled || state.shuffle == PlayerShuffle.track;
    final targetIndex = targetUniqueId == null
        ? -1
        : uniqueIds.indexWhere((id) => id == targetUniqueId);
    final shuffled = shouldShuffle
        ? targetIndex == -1
              ? player_queue.generateShuffledIndexes(uniqueIds.length)
              : [
                  targetIndex,
                  ...player_queue.shuffleInPlace(
                    List<int>.generate(
                      uniqueIds.length,
                      (index) => index,
                    ).where((index) => index != targetIndex).toList(),
                  ),
                ]
        : <int>[];

    state = state.copyWith(
      index: queueSongs.isEmpty ? -1 : 0,
      playerNum: 1,
      status: queueSongs.isEmpty ? PlayerStatus.paused : PlayerStatus.playing,
      queue: player_queue.QueueData(
        defaultOrder: uniqueIds,
        shuffled: shuffled,
        songs: {for (final song in queueSongs) song.uniqueId: song},
      ),
    );
  }

  PlayerState _keepCurrentSongIndex(
    PlayerState newState,
    List<String> newDefaultOrder,
  ) {
    final currentTrack = getCurrentSong();
    if (currentTrack == null) {
      return newState.copyWith(index: newDefaultOrder.isEmpty ? -1 : 0);
    }

    final index = newDefaultOrder.indexOf(currentTrack.uniqueId);
    if (index == -1) {
      return newState.copyWith(index: newDefaultOrder.isEmpty ? -1 : 0);
    }

    final playbackIndex = newState.isShuffleEnabled
        ? player_queue.findShuffledPositionForQueueIndex(
                index,
                newState.queue.shuffled,
              ) ??
              index
        : index;
    return newState.copyWith(index: playbackIndex);
  }

  void _replaceDefaultOrder(
    List<String> defaultOrder, {
    required List<QueueSong> additionalSongs,
  }) {
    final songs = {
      ...state.queue.songs,
      for (final song in additionalSongs) song.uniqueId: song,
    };
    final newState = state.copyWith(
      queue: state.queue.copyWith(defaultOrder: defaultOrder, songs: songs),
    );

    state = _keepCurrentSongIndex(newState, defaultOrder);
  }
}

enum QueueEdge { bottom, top }

T? _itemAtOrNull<T>(List<T> items, int index) {
  if (index < 0 || index >= items.length) {
    return null;
  }
  return items[index];
}

int _otherPlayerNum(int playerNum) => playerNum == 1 ? 2 : 1;

String _generateUniqueId() {
  final random = Random.secure();
  return List.generate(21, (_) => random.nextInt(16).toRadixString(16)).join();
}
