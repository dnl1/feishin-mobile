import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'genre.dart';
import 'related_artist.dart';

part 'album_artist.freezed.dart';
part 'album_artist.g.dart';

/// Mirrors `AlbumArtist` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class AlbumArtist with _$AlbumArtist {
  const factory AlbumArtist({
    @JsonKey(name: '_itemType')
    @Default(LibraryItem.albumArtist)
    LibraryItem itemType,
    @JsonKey(name: '_serverId') required String serverId,
    @JsonKey(name: '_serverType') required ServerType serverType,
    required int? albumCount,
    required String? biography,
    required num? duration,
    required List<Genre> genres,
    required String id,
    required String? imageId,
    required String? imageUrl,
    required String? lastPlayedAt,
    required String? mbz,
    required String name,
    required int? playCount,
    required List<RelatedArtist>? similarArtists,
    required int? songCount,
    String? uploadedImage,
    required bool userFavorite,
    required int? userRating,
  }) = _AlbumArtist;

  factory AlbumArtist.fromJson(Map<String, dynamic> json) =>
      _$AlbumArtistFromJson(json);
}
