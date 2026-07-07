import 'package:json_annotation/json_annotation.dart';

/// Mirrors `Play` in feishin/src/shared/types/types.ts.
enum PlayMode {
  @JsonValue('index')
  byIndex,
  @JsonValue('last')
  last,
  @JsonValue('lastShuffle')
  lastShuffle,
  @JsonValue('next')
  next,
  @JsonValue('nextShuffle')
  nextShuffle,
  @JsonValue('now')
  now,
  @JsonValue('shuffle')
  shuffle,
}

/// Mirrors `PlayerRepeat` in feishin/src/shared/types/types.ts.
enum PlayerRepeat {
  @JsonValue('all')
  all,
  @JsonValue('none')
  none,
  @JsonValue('one')
  one,
}

/// Mirrors `PlayerShuffle` in feishin/src/shared/types/types.ts.
enum PlayerShuffle {
  @JsonValue('album')
  album,
  @JsonValue('none')
  none,
  @JsonValue('track')
  track,
}

/// Mirrors `PlayerStatus` in feishin/src/shared/types/types.ts.
enum PlayerStatus {
  @JsonValue('paused')
  paused,
  @JsonValue('playing')
  playing,
  @JsonValue('stopped')
  stopped,
}

/// Mirrors `PlayerStyle` in feishin/src/shared/types/types.ts.
enum PlayerStyle {
  @JsonValue('crossfade')
  crossfade,
  @JsonValue('gapless')
  gapless,
}
