/// Server-agnostic list queries and sort enums, ported from the query types
/// in feishin/src/shared/types/domain-types.ts. Each backend maps these to
/// its own wire values (see `navidrome/navidrome_types.dart`), mirroring the
/// `*ListSortMap` pattern of the original app.
library;

import '../domain/enums.dart';

/// Mirrors `AlbumListSort`.
enum AlbumListSort {
  albumArtist,
  artist,
  communityRating,
  criticRating,
  duration,
  explicitStatus,
  favorited,
  id,
  name,
  playCount,
  random,
  rating,
  recentlyAdded,
  recentlyPlayed,
  releaseDate,
  songCount,
  sortName,
  year,
}

/// Mirrors `SongListSort`.
enum SongListSort {
  album,
  albumArtist,
  artist,
  bpm,
  channels,
  comment,
  duration,
  explicitStatus,
  favorited,
  genre,
  id,
  name,
  playCount,
  random,
  rating,
  recentlyAdded,
  recentlyPlayed,
  releaseDate,
  sortName,
  year,
}

/// Mirrors `AlbumArtistListSort` (also used by `ArtistListSort` queries —
/// the enums are identical in the original).
enum AlbumArtistListSort {
  album,
  albumCount,
  duration,
  favorited,
  name,
  playCount,
  random,
  rating,
  recentlyAdded,
  releaseDate,
  songCount,
}

/// Mirrors `GenreListSort`.
enum GenreListSort { albumCount, name, songCount }

/// Mirrors `PlaylistListSort`.
enum PlaylistListSort { duration, name, owner, public, songCount, updatedAt }

/// Mirrors `AlbumListQuery`.
class AlbumListQuery {
  const AlbumListQuery({
    this.artistIds,
    this.compilation,
    this.favorite,
    this.genreIds,
    this.hasRating,
    this.isRecentlyPlayed,
    this.limit,
    this.maxYear,
    this.minYear,
    this.musicFolderId,
    this.searchTerm,
    this.sortBy = AlbumListSort.name,
    this.sortOrder = SortOrder.asc,
    this.startIndex = 0,
  });

  final List<String>? artistIds;
  final bool? compilation;
  final bool? favorite;
  final List<String>? genreIds;
  final bool? hasRating;
  final bool? isRecentlyPlayed;
  final int? limit;
  final int? maxYear;
  final int? minYear;
  final List<String>? musicFolderId;
  final String? searchTerm;
  final AlbumListSort sortBy;
  final SortOrder sortOrder;
  final int startIndex;

  AlbumListQuery copyWith({int? limit, int? startIndex}) => AlbumListQuery(
    artistIds: artistIds,
    compilation: compilation,
    favorite: favorite,
    genreIds: genreIds,
    hasRating: hasRating,
    isRecentlyPlayed: isRecentlyPlayed,
    limit: limit ?? this.limit,
    maxYear: maxYear,
    minYear: minYear,
    musicFolderId: musicFolderId,
    searchTerm: searchTerm,
    sortBy: sortBy,
    sortOrder: sortOrder,
    startIndex: startIndex ?? this.startIndex,
  );
}

/// Mirrors `SongListQuery`.
class SongListQuery {
  const SongListQuery({
    this.albumArtistIds,
    this.albumIds,
    this.artistIds,
    this.favorite,
    this.genreIds,
    this.hasRating,
    this.limit,
    this.maxYear,
    this.minYear,
    this.musicFolderId,
    this.searchTerm,
    this.sortBy = SongListSort.name,
    this.sortOrder = SortOrder.asc,
    this.startIndex = 0,
  });

  final List<String>? albumArtistIds;
  final List<String>? albumIds;
  final List<String>? artistIds;
  final bool? favorite;
  final List<String>? genreIds;
  final bool? hasRating;
  final int? limit;
  final int? maxYear;
  final int? minYear;
  final List<String>? musicFolderId;
  final String? searchTerm;
  final SongListSort sortBy;
  final SortOrder sortOrder;
  final int startIndex;

  SongListQuery copyWith({int? limit, int? startIndex}) => SongListQuery(
    albumArtistIds: albumArtistIds,
    albumIds: albumIds,
    artistIds: artistIds,
    favorite: favorite,
    genreIds: genreIds,
    hasRating: hasRating,
    limit: limit ?? this.limit,
    maxYear: maxYear,
    minYear: minYear,
    musicFolderId: musicFolderId,
    searchTerm: searchTerm,
    sortBy: sortBy,
    sortOrder: sortOrder,
    startIndex: startIndex ?? this.startIndex,
  );
}

/// Mirrors `AlbumArtistListQuery` / `ArtistListQuery` ([role] is only used
/// by the artist-list variant).
class AlbumArtistListQuery {
  const AlbumArtistListQuery({
    this.favorite,
    this.limit,
    this.musicFolderId,
    this.role,
    this.searchTerm,
    this.sortBy = AlbumArtistListSort.name,
    this.sortOrder = SortOrder.asc,
    this.startIndex = 0,
  });

  final bool? favorite;
  final int? limit;
  final List<String>? musicFolderId;
  final String? role;
  final String? searchTerm;
  final AlbumArtistListSort sortBy;
  final SortOrder sortOrder;
  final int startIndex;

  AlbumArtistListQuery copyWith({int? limit, int? startIndex}) =>
      AlbumArtistListQuery(
        favorite: favorite,
        limit: limit ?? this.limit,
        musicFolderId: musicFolderId,
        role: role,
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortOrder: sortOrder,
        startIndex: startIndex ?? this.startIndex,
      );
}

/// Mirrors `GenreListQuery`.
class GenreListQuery {
  const GenreListQuery({
    this.limit,
    this.musicFolderId,
    this.searchTerm,
    this.sortBy = GenreListSort.name,
    this.sortOrder = SortOrder.asc,
    this.startIndex = 0,
  });

  final int? limit;
  final List<String>? musicFolderId;
  final String? searchTerm;
  final GenreListSort sortBy;
  final SortOrder sortOrder;
  final int startIndex;
}

/// Mirrors `PlaylistListQuery`.
class PlaylistListQuery {
  const PlaylistListQuery({
    this.excludeSmartPlaylists = false,
    this.limit,
    this.searchTerm,
    this.sortBy = PlaylistListSort.name,
    this.sortOrder = SortOrder.asc,
    this.startIndex = 0,
  });

  final bool excludeSmartPlaylists;
  final int? limit;
  final String? searchTerm;
  final PlaylistListSort sortBy;
  final SortOrder sortOrder;
  final int startIndex;

  PlaylistListQuery copyWith({int? limit, int? startIndex}) =>
      PlaylistListQuery(
        excludeSmartPlaylists: excludeSmartPlaylists,
        limit: limit ?? this.limit,
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortOrder: sortOrder,
        startIndex: startIndex ?? this.startIndex,
      );
}
