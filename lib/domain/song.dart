import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'gain_info.dart';
import 'genre.dart';
import 'related_artist.dart';

part 'song.freezed.dart';
part 'song.g.dart';

/// Mirrors `Song` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class Song with _$Song {
  const factory Song({
    @JsonKey(name: '_itemType') @Default(LibraryItem.song) LibraryItem itemType,
    @JsonKey(name: '_serverId') required String serverId,
    @JsonKey(name: '_serverType') required ServerType serverType,
    required String? album,
    required String albumArtistName,
    required List<RelatedArtist> albumArtists,
    required String albumId,
    required String artistName,
    required List<RelatedArtist> artists,
    required int? bitDepth,
    required num bitRate,
    required num? bpm,
    required int? channels,
    required String? comment,
    required bool? compilation,
    required String? container,
    required String createdAt,
    required int discNumber,
    required String? discSubtitle,
    required num duration,
    required ExplicitStatus? explicitStatus,
    required GainInfo? gain,
    required List<Genre> genres,
    required String id,
    required String? imageId,
    required String? imageUrl,
    required String? lastPlayedAt,
    required String? lyrics,
    required String? mbzRecordingId,
    required String? mbzTrackId,
    required String name,
    required Map<String, List<RelatedArtist>>? participants,
    required String? path,
    required GainInfo? peak,
    required int playCount,
    String? playlistItemId,
    required String? releaseDate,
    required int? releaseYear,
    required int? sampleRate,
    required num size,
    required String sortName,
    required Map<String, List<String>>? tags,
    required int trackNumber,
    required String? trackSubtitle,
    required String updatedAt,
    required bool userFavorite,
    required int? userRating,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

/// Mirrors `QueueSong` in feishin/src/shared/types/domain-types.ts — a [Song]
/// tagged with the identity it holds inside a specific play queue instance
/// (the same underlying song can appear more than once in a queue).
@freezed
abstract class QueueSong with _$QueueSong {
  const factory QueueSong({
    required Song song,
    @JsonKey(name: '_contextPlaylistId') String? contextPlaylistId,
    @JsonKey(name: '_uniqueId') required String uniqueId,
  }) = _QueueSong;

  factory QueueSong.fromJson(Map<String, dynamic> json) =>
      _$QueueSongFromJson(json);
}
