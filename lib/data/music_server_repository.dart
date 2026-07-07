/// Server-agnostic data-layer interface, mirroring the role of
/// feishin/src/renderer/api/controller.ts. Only Navidrome implements it in
/// v1 — Jellyfin/Subsonic are added later as new implementations, without
/// touching callers (see PLAN.md, phase 1).
library;

import '../domain/domain.dart';
import 'paginated.dart';
import 'queries.dart';

/// Result of a successful login, mirroring `AuthenticationResponse`.
class ServerAuthResult {
  const ServerAuthResult({
    required this.credentials,
    required this.isAdmin,
    required this.userId,
    required this.username,
  });

  final ServerCredentials credentials;
  final bool isAdmin;
  final String userId;
  final String username;
}

/// Mirrors `ServerInfo` (version + feature flags detected from it).
class ServerInfo {
  const ServerInfo({required this.features, required this.version});

  final Map<String, List<int>> features;
  final String version;
}

abstract interface class MusicServerRepository {
  ServerConfig get server;

  // --- Albums ---
  Future<PaginatedList<Album>> getAlbumList(AlbumListQuery query);
  Future<int> getAlbumListCount(AlbumListQuery query);

  /// Album with its songs populated.
  Future<Album> getAlbumDetail(String id);

  // --- Artists ---
  Future<PaginatedList<AlbumArtist>> getAlbumArtistList(
    AlbumArtistListQuery query,
  );
  Future<int> getAlbumArtistListCount(AlbumArtistListQuery query);
  Future<AlbumArtist> getAlbumArtistDetail(String id);

  /// Role-filtered artist list (performers, composers, ...). Same shape as
  /// album artists — mirrors `getArtistList` in the original controller.
  Future<PaginatedList<AlbumArtist>> getArtistList(AlbumArtistListQuery query);

  // --- Songs ---
  Future<PaginatedList<Song>> getSongList(SongListQuery query);
  Future<int> getSongListCount(SongListQuery query);
  Future<Song> getSongDetail(String id);

  // --- Genres ---
  Future<PaginatedList<Genre>> getGenreList(GenreListQuery query);

  // --- Playlists ---
  Future<PaginatedList<Playlist>> getPlaylistList(PlaylistListQuery query);
  Future<int> getPlaylistListCount(PlaylistListQuery query);
  Future<Playlist> getPlaylistDetail(String id);
  Future<PaginatedList<Song>> getPlaylistSongList(String id);
  Future<String> createPlaylist({
    required String name,
    String? comment,
    bool? public,
  });
  Future<void> deletePlaylist(String id);
  Future<void> addToPlaylist({
    required String playlistId,
    required List<String> songIds,
  });
  Future<void> removeFromPlaylist({
    required String playlistId,
    required List<String> playlistItemIds,
  });

  // --- Internet radio ---
  Future<List<InternetRadioStation>> getInternetRadioStations();

  // --- URL builders (no request involved) ---
  String getStreamUrl(String id);
  String getDownloadUrl(String id);
  String? getImageUrl(String id, {int? size});
}
