/// Navidrome wire-level sort values and the domain→Navidrome sort maps,
/// ported from feishin/src/shared/api/navidrome/navidrome-types.ts and the
/// `*ListSortMap.navidrome` entries in
/// feishin/src/shared/types/domain-types.ts.
library;

import '../../domain/enums.dart';
import '../queries.dart';

/// Mirrors `NDAlbumArtistListSort`.
enum NdAlbumArtistListSort {
  albumCount('albumCount'),
  favorited('starred_at'),
  name('name'),
  playCount('playCount'),
  rating('rating'),
  songCount('songCount');

  const NdAlbumArtistListSort(this.value);
  final String value;
}

/// Mirrors `NDAlbumListSort`.
enum NdAlbumListSort {
  albumArtist('album_artist'),
  artist('artist'),
  duration('duration'),
  explicitStatus('explicitStatus'),
  name('name'),
  playCount('play_count'),
  playDate('play_date'),
  random('random'),
  rating('rating'),
  recentlyAdded('recently_added'),
  songCount('songCount'),
  starred('starred_at'),
  year('max_year');

  const NdAlbumListSort(this.value);
  final String value;
}

/// Mirrors `NDGenreListSort`.
enum NdGenreListSort {
  albumCount('albumCount'),
  name('name'),
  songCount('songCount');

  const NdGenreListSort(this.value);
  final String value;
}

/// Mirrors `NDPlaylistListSort`.
enum NdPlaylistListSort {
  duration('duration'),
  name('name'),
  owner('owner_name'),
  public('public'),
  songCount('songCount'),
  updatedAt('updatedAt');

  const NdPlaylistListSort(this.value);
  final String value;
}

/// Mirrors `NDSongListSort`.
enum NdSongListSort {
  album('album'),
  albumArtist('order_album_artist_name'),
  artist('artist'),
  bpm('bpm'),
  channels('channels'),
  comment('comment'),
  duration('duration'),
  explicitStatus('explicitStatus'),
  favorited('starred_at'),
  genre('genre'),
  id('id'),
  playCount('playCount'),
  playDate('playDate'),
  random('random'),
  rating('rating'),
  recentlyAdded('createdAt'),
  title('title'),
  track('track'),
  year('year');

  const NdSongListSort(this.value);
  final String value;
}

/// Mirrors `NDTagListSort`.
enum NdTagListSort {
  albumCount('albumCount'),
  songCount('songCount'),
  tagValue('tagValue');

  const NdTagListSort(this.value);
  final String value;
}

/// Mirrors `NDRadioListSort`.
enum NdRadioListSort {
  name('name');

  const NdRadioListSort(this.value);
  final String value;
}

/// Mirrors `sortOrderMap.navidrome`.
const Map<SortOrder, String> ndSortOrderMap = {
  SortOrder.asc: 'ASC',
  SortOrder.desc: 'DESC',
};

/// Mirrors `albumListSortMap.navidrome`.
const Map<AlbumListSort, NdAlbumListSort?> ndAlbumListSortMap = {
  AlbumListSort.albumArtist: NdAlbumListSort.albumArtist,
  AlbumListSort.artist: NdAlbumListSort.artist,
  AlbumListSort.communityRating: null,
  AlbumListSort.criticRating: null,
  AlbumListSort.duration: NdAlbumListSort.duration,
  AlbumListSort.explicitStatus: NdAlbumListSort.explicitStatus,
  AlbumListSort.favorited: NdAlbumListSort.starred,
  AlbumListSort.id: null,
  AlbumListSort.name: NdAlbumListSort.name,
  AlbumListSort.playCount: NdAlbumListSort.playCount,
  AlbumListSort.random: NdAlbumListSort.random,
  AlbumListSort.rating: NdAlbumListSort.rating,
  AlbumListSort.recentlyAdded: NdAlbumListSort.recentlyAdded,
  AlbumListSort.recentlyPlayed: NdAlbumListSort.playDate,
  // Recent versions of Navidrome support release date, but fallback to year
  // for now (same note as the original map).
  AlbumListSort.releaseDate: NdAlbumListSort.year,
  AlbumListSort.songCount: NdAlbumListSort.songCount,
  AlbumListSort.sortName: NdAlbumListSort.name,
  AlbumListSort.year: NdAlbumListSort.year,
};

/// Mirrors `songListSortMap.navidrome`.
const Map<SongListSort, NdSongListSort?> ndSongListSortMap = {
  SongListSort.album: NdSongListSort.album,
  SongListSort.albumArtist: NdSongListSort.albumArtist,
  SongListSort.artist: NdSongListSort.artist,
  SongListSort.bpm: NdSongListSort.bpm,
  SongListSort.channels: NdSongListSort.channels,
  SongListSort.comment: NdSongListSort.comment,
  SongListSort.duration: NdSongListSort.duration,
  SongListSort.explicitStatus: NdSongListSort.explicitStatus,
  SongListSort.favorited: NdSongListSort.favorited,
  SongListSort.genre: NdSongListSort.genre,
  SongListSort.id: NdSongListSort.id,
  SongListSort.name: NdSongListSort.title,
  SongListSort.playCount: NdSongListSort.playCount,
  SongListSort.random: NdSongListSort.random,
  SongListSort.rating: NdSongListSort.rating,
  SongListSort.recentlyAdded: NdSongListSort.recentlyAdded,
  SongListSort.recentlyPlayed: NdSongListSort.playDate,
  SongListSort.releaseDate: null,
  SongListSort.sortName: NdSongListSort.title,
  SongListSort.year: NdSongListSort.year,
};

/// Mirrors `albumArtistListSortMap.navidrome`.
const Map<AlbumArtistListSort, NdAlbumArtistListSort?>
ndAlbumArtistListSortMap = {
  AlbumArtistListSort.album: null,
  AlbumArtistListSort.albumCount: NdAlbumArtistListSort.albumCount,
  AlbumArtistListSort.duration: null,
  AlbumArtistListSort.favorited: NdAlbumArtistListSort.favorited,
  AlbumArtistListSort.name: NdAlbumArtistListSort.name,
  AlbumArtistListSort.playCount: NdAlbumArtistListSort.playCount,
  AlbumArtistListSort.random: null,
  AlbumArtistListSort.rating: NdAlbumArtistListSort.rating,
  AlbumArtistListSort.recentlyAdded: null,
  AlbumArtistListSort.releaseDate: null,
  AlbumArtistListSort.songCount: NdAlbumArtistListSort.songCount,
};

/// Mirrors `genreListSortMap.navidrome` (every entry maps to `name` in the
/// original — the ND genre endpoint only sorts by name).
const Map<GenreListSort, NdGenreListSort> ndGenreListSortMap = {
  GenreListSort.albumCount: NdGenreListSort.name,
  GenreListSort.name: NdGenreListSort.name,
  GenreListSort.songCount: NdGenreListSort.name,
};

/// Mirrors `tagListSortMap.navidrome` (used for the BFR genre-as-tag list).
const Map<GenreListSort, NdTagListSort> ndTagListSortMap = {
  GenreListSort.albumCount: NdTagListSort.albumCount,
  GenreListSort.name: NdTagListSort.tagValue,
  GenreListSort.songCount: NdTagListSort.songCount,
};

/// Mirrors `playlistListSortMap.navidrome`.
const Map<PlaylistListSort, NdPlaylistListSort> ndPlaylistListSortMap = {
  PlaylistListSort.duration: NdPlaylistListSort.duration,
  PlaylistListSort.name: NdPlaylistListSort.name,
  PlaylistListSort.owner: NdPlaylistListSort.owner,
  PlaylistListSort.public: NdPlaylistListSort.public,
  PlaylistListSort.songCount: NdPlaylistListSort.songCount,
  PlaylistListSort.updatedAt: NdPlaylistListSort.updatedAt,
};
