import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'genre.freezed.dart';
part 'genre.g.dart';

/// Mirrors `Genre` in feishin/src/shared/types/domain-types.ts.
@freezed
abstract class Genre with _$Genre {
  const factory Genre({
    @JsonKey(name: '_itemType')
    @Default(LibraryItem.genre)
    LibraryItem itemType,
    @JsonKey(name: '_serverId') required String serverId,
    @JsonKey(name: '_serverType') required ServerType serverType,
    required int? albumCount,
    required String id,
    required String? imageId,
    required String? imageUrl,
    required String name,
    required int? songCount,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}
