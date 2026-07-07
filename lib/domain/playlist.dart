import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'genre.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

/// Mirrors `Playlist` in feishin/src/shared/types/domain-types.ts.
///
/// `rules` (smart playlist query builder) is kept as a raw JSON map for now
/// — it's ported properly alongside the query builder feature itself, not
/// as part of the base domain model.
@freezed
abstract class Playlist with _$Playlist {
  const factory Playlist({
    @JsonKey(name: '_itemType')
    @Default(LibraryItem.playlist)
    LibraryItem itemType,
    @JsonKey(name: '_serverId') required String serverId,
    @JsonKey(name: '_serverType') required ServerType serverType,
    required String? description,
    required num? duration,
    required List<Genre> genres,
    required String id,
    required String? imageId,
    required String? imageUrl,
    required String name,
    required String? owner,
    required String? ownerId,
    required bool? public,
    Map<String, dynamic>? rules,
    required num? size,
    required int? songCount,
    bool? sync,
    String? uploadedImage,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}
