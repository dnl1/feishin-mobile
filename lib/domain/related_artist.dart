import 'package:freezed_annotation/freezed_annotation.dart';

part 'related_artist.freezed.dart';
part 'related_artist.g.dart';

/// Mirrors `RelatedArtist` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class RelatedArtist with _$RelatedArtist {
  const factory RelatedArtist({
    required String id,
    required String? imageId,
    required String? imageUrl,
    required String name,
    required bool userFavorite,
    required int? userRating,
  }) = _RelatedArtist;

  factory RelatedArtist.fromJson(Map<String, dynamic> json) =>
      _$RelatedArtistFromJson(json);
}
