import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'genre.dart';
import 'related_artist.dart';
import 'song.dart';

part 'album.freezed.dart';
part 'album.g.dart';

/// Mirrors `Album` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class Album with _$Album {
  const factory Album({
    @JsonKey(name: '_itemType')
    @Default(LibraryItem.album)
    LibraryItem itemType,
    @JsonKey(name: '_serverId') required String serverId,
    @JsonKey(name: '_serverType') required ServerType serverType,
    required String albumArtistName,
    required List<RelatedArtist> albumArtists,
    required List<RelatedArtist> artists,
    required String? comment,
    required String createdAt,
    required num? duration,
    required ExplicitStatus? explicitStatus,
    required List<Genre> genres,
    required String id,
    required String? imageId,
    required String? imageUrl,
    required bool? isCompilation,
    required String? lastPlayedAt,
    required String? mbzId,
    required String? mbzReleaseGroupId,
    required String name,
    required String? originalDate,
    required int originalYear,
    required Map<String, List<RelatedArtist>>? participants,
    required int? playCount,
    required List<String> recordLabels,
    required String? releaseDate,
    required String? releaseType,
    required List<String> releaseTypes,
    required int? releaseYear,
    required num? size,
    required int? songCount,
    List<Song>? songs,
    required String sortName,
    required Map<String, List<String>>? tags,
    required String updatedAt,
    required bool userFavorite,
    required int? userRating,
    required String? version,
  }) = _Album;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
}
