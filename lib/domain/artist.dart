import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'genre.dart';
import 'related_artist.dart';

part 'artist.freezed.dart';
part 'artist.g.dart';

/// Mirrors `Artist` (`Omit&lt;AlbumArtist, '_itemType'&gt; &amp; { _itemType:
/// LibraryItem.ARTIST }`) in feishin/src/shared/types/domain-types.ts.
///
/// Kept as its own type rather than reusing [AlbumArtist] because the two
/// come from distinct API shapes server-side (album-artist rollup vs. plain
/// artist row) even though the fields happen to line up today.
@freezed
abstract class Artist with _$Artist {
  const factory Artist({
    @JsonKey(name: '_itemType')
    @Default(LibraryItem.artist)
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
  }) = _Artist;

  factory Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);
}
