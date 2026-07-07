import 'package:json_annotation/json_annotation.dart';

/// Mirrors `LibraryItem` in feishin/src/shared/types/domain-types.ts.
enum LibraryItem {
  @JsonValue('album')
  album,
  @JsonValue('albumArtist')
  albumArtist,
  @JsonValue('artist')
  artist,
  @JsonValue('folder')
  folder,
  @JsonValue('genre')
  genre,
  @JsonValue('playlist')
  playlist,
  @JsonValue('playlistSong')
  playlistSong,
  @JsonValue('queueSong')
  queueSong,
  @JsonValue('radioStation')
  radioStation,
  @JsonValue('song')
  song,
}

/// Mirrors `ServerType` in feishin/src/shared/types/domain-types.ts.
///
/// v1 only implements [navidrome] (see plan phase 1); jellyfin/subsonic are
/// kept here so the domain model and `MusicServerRepository` interface don't
/// need to change shape when those servers are added later.
enum ServerType {
  @JsonValue('jellyfin')
  jellyfin,
  @JsonValue('navidrome')
  navidrome,
  @JsonValue('subsonic')
  subsonic,
}

/// Mirrors `SortOrder` in feishin/src/shared/types/domain-types.ts.
enum SortOrder {
  @JsonValue('ASC')
  asc,
  @JsonValue('DESC')
  desc,
}

/// Mirrors `ExplicitStatus` in feishin/src/shared/types/domain-types.ts.
enum ExplicitStatus {
  @JsonValue('CLEAN')
  clean,
  @JsonValue('EXPLICIT')
  explicit,
}
