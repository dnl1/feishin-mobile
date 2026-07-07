/// Navidrome implementation of [MusicServerRepository], ported from
/// feishin/src/renderer/api/navidrome/navidrome-controller.ts (plus the
/// stream/image/download URL builders the original delegates to the
/// Subsonic controller).
library;

import '../../core/server_features.dart';
import '../../domain/domain.dart';
import 'navidrome_api.dart';
import 'navidrome_normalizer.dart';
import 'navidrome_types.dart';
import '../music_server_repository.dart';
import '../paginated.dart';
import '../queries.dart';

/// Mirrors `VERSION_INFO` in navidrome-controller.ts. Kept in decreasing
/// version order — required by [getFeatures].
final VersionInfo navidromeVersionInfo = [
  (
    '0.61.0',
    {
      ServerFeature.artistImageUpload: [1],
      ServerFeature.internetRadioImageUpload: [1],
      ServerFeature.playlistImageUpload: [1],
    },
  ),
  (
    '0.60.4',
    {
      ServerFeature.trackYesNoRatingFilter: [1],
    },
  ),
  (
    '0.57.0',
    {
      ServerFeature.serverPlayQueue: [2],
    },
  ),
  (
    '0.56.0',
    {
      ServerFeature.trackAlbumArtistSearch: [1],
    },
  ),
  (
    '0.55.0',
    {
      ServerFeature.bfr: [1],
      ServerFeature.tags: [1],
    },
  ),
  (
    '0.49.3',
    {
      ServerFeature.sharingAlbumSong: [1],
    },
  ),
  (
    '0.48.0',
    {
      ServerFeature.playlistsSmart: [1],
    },
  ),
];

class NavidromeRepository implements MusicServerRepository {
  NavidromeRepository({
    required this.server,
    required this._api,
    required this._subsonicCredential,
  });

  @override
  final ServerConfig server;

  final NavidromeApi _api;
  final String? Function() _subsonicCredential;

  /// Mirrors `NavidromeController.authenticate` + the feature-detection half
  /// of `getServerInfo`: logs in and stamps version/features so later calls
  /// can branch on server capabilities.
  static Future<(ServerAuthResult, ServerInfo?)> authenticate({
    required String url,
    required String username,
    required String password,
  }) async {
    final auth = await NavidromeApi.authenticate(
      url: url,
      username: username,
      password: password,
    );

    final result = ServerAuthResult(
      credentials: ServerCredentials(
        credential: auth.subsonicCredential,
        ndCredential: auth.ndToken,
      ),
      isAdmin: auth.isAdmin,
      userId: auth.userId,
      username: auth.username,
    );

    ServerInfo? info;
    try {
      var version = await NavidromeApi.ping(
        url: url,
        subsonicCredential: auth.subsonicCredential,
      );
      // Mirrors the pr-2709 workaround in `getServerInfo`.
      if (version.contains('pr-2709')) {
        version = '0.55.0';
      }

      info = ServerInfo(
        features: {
          ...getFeatures(navidromeVersionInfo, version),
          // Always-on Navidrome capabilities, same as `getServerInfo`.
          ServerFeature.publicPlaylist.key: [1],
          ServerFeature.albumYesNoRatingFilter.key: [1],
          ServerFeature.musicFolderMultiselect.key: [1],
        },
        version: version,
      );
    } on NavidromeApiException {
      // Feature detection is best-effort — login already succeeded.
    }

    return (result, info);
  }

  // --- Albums ---

  @override
  Future<PaginatedList<Album>> getAlbumList(AlbumListQuery query) async {
    final page = await _api.getAlbumList({
      '_end': query.startIndex + (query.limit ?? 0),
      '_order': ndSortOrderMap[query.sortOrder],
      '_sort': ndAlbumListSortMap[query.sortBy]?.value,
      '_start': query.startIndex,
      'artist_id': query.artistIds,
      'compilation': query.compilation,
      'genre_id': query.genreIds,
      'has_rating': query.hasRating,
      'library_id': query.musicFolderId,
      'name': query.searchTerm,
      'recently_played': query.isRecentlyPlayed,
      'starred': query.favorite,
      'year': query.maxYear ?? query.minYear,
      ..._excludeMissing(),
    });

    return PaginatedList(
      items: page.items.map((item) => NdNormalize.album(item, server)).toList(),
      startIndex: query.startIndex,
      totalRecordCount: page.totalCount,
    );
  }

  @override
  Future<int> getAlbumListCount(AlbumListQuery query) async {
    final page = await getAlbumList(query.copyWith(limit: 1, startIndex: 0));
    return page.totalRecordCount;
  }

  @override
  Future<Album> getAlbumDetail(String id) async {
    final album = await _api.getAlbumDetail(id);
    final songs = await _api.getSongList({
      '_end': 0,
      '_order': 'ASC',
      '_sort': NdSongListSort.album.value,
      '_start': 0,
      'album_id': [id],
      ..._excludeMissing(),
    });

    return NdNormalize.album(album, server, songs: songs.items);
  }

  // --- Artists ---

  @override
  Future<PaginatedList<AlbumArtist>> getAlbumArtistList(
    AlbumArtistListQuery query,
  ) => _artistList(
    query,
    // Mirrors the BFR branch of `getAlbumArtistList`: post-BFR the artist
    // endpoint needs `role=albumartist` to exclude non-album artists.
    role: hasFeature(server, ServerFeature.bfr) ? 'albumartist' : '',
  );

  @override
  Future<int> getAlbumArtistListCount(AlbumArtistListQuery query) async {
    final page = await getAlbumArtistList(
      query.copyWith(limit: 1, startIndex: 0),
    );
    return page.totalRecordCount;
  }

  @override
  Future<AlbumArtist> getAlbumArtistDetail(String id) async {
    final item = await _api.getAlbumArtistDetail(id);
    return NdNormalize.albumArtist(item, server);
  }

  @override
  Future<PaginatedList<AlbumArtist>> getArtistList(
    AlbumArtistListQuery query,
  ) => _artistList(query, role: query.role);

  Future<PaginatedList<AlbumArtist>> _artistList(
    AlbumArtistListQuery query, {
    String? role,
  }) async {
    final page = await _api.getAlbumArtistList({
      '_end': query.startIndex + (query.limit ?? 0),
      '_order': ndSortOrderMap[query.sortOrder],
      '_sort': ndAlbumArtistListSortMap[query.sortBy]?.value,
      '_start': query.startIndex,
      'library_id': query.musicFolderId,
      'name': query.searchTerm,
      'role': role,
      'starred': query.favorite,
      ..._excludeMissing(),
    });

    return PaginatedList(
      items: page.items
          .map((item) => NdNormalize.albumArtist(item, server))
          .toList(),
      startIndex: query.startIndex,
      totalRecordCount: page.totalCount,
    );
  }

  // --- Songs ---

  @override
  Future<PaginatedList<Song>> getSongList(SongListQuery query) async {
    // Mirrors `getArtistSongKey`: post-0.56 servers can search songs by any
    // credited artist, older ones only by album artist.
    final artistKey = hasFeature(server, ServerFeature.trackAlbumArtistSearch)
        ? 'artists_id'
        : 'album_artist_id';

    final page = await _api.getSongList({
      '_end': query.startIndex + (query.limit ?? -1),
      '_order': ndSortOrderMap[query.sortOrder],
      '_sort': ndSongListSortMap[query.sortBy]?.value,
      '_start': query.startIndex,
      'album_id': query.albumIds,
      'genre_id': query.genreIds,
      artistKey: query.artistIds ?? query.albumArtistIds,
      if (hasFeature(server, ServerFeature.trackYesNoRatingFilter) &&
          query.hasRating != null)
        'has_rating': query.hasRating,
      'library_id': query.musicFolderId,
      'starred': query.favorite,
      'title': query.searchTerm,
      'year': query.maxYear ?? query.minYear,
      ..._excludeMissing(),
    });

    return PaginatedList(
      items: page.items.map((item) => NdNormalize.song(item, server)).toList(),
      startIndex: query.startIndex,
      totalRecordCount: page.totalCount,
    );
  }

  @override
  Future<int> getSongListCount(SongListQuery query) async {
    final page = await getSongList(query.copyWith(limit: 1, startIndex: 0));
    return page.totalRecordCount;
  }

  @override
  Future<Song> getSongDetail(String id) async {
    final item = await _api.getSongDetail(id);
    return NdNormalize.song(item, server);
  }

  // --- Genres ---

  @override
  Future<PaginatedList<Genre>> getGenreList(GenreListQuery query) async {
    // Post-BFR genres are tags; the dedicated genre endpoint stops reporting
    // counts. Mirrors the feature branch in `getGenreList`.
    if (hasFeature(server, ServerFeature.bfr)) {
      final page = await _api.getTagList({
        '_end': query.startIndex + (query.limit ?? 0),
        '_order': ndSortOrderMap[query.sortOrder],
        '_sort': ndTagListSortMap[query.sortBy]?.value,
        '_start': query.startIndex,
        'library_id': query.musicFolderId,
        'tag_name': 'genre',
        'tag_value': query.searchTerm,
      });

      return PaginatedList(
        items: page.items
            .map(
              (tag) => NdNormalize.genre({
                'albumCount': tag['albumCount'],
                'id': tag['id'],
                'name': tag['tagValue'],
                'songCount': tag['songCount'],
              }, server),
            )
            .toList(),
        startIndex: query.startIndex,
        totalRecordCount: page.totalCount,
      );
    }

    final page = await _api.getGenreList({
      '_end': query.startIndex + (query.limit ?? 0),
      '_order': ndSortOrderMap[query.sortOrder],
      '_sort': ndGenreListSortMap[query.sortBy]?.value,
      '_start': query.startIndex,
      'library_id': query.musicFolderId,
      'name': query.searchTerm,
    });

    return PaginatedList(
      items: page.items.map((item) => NdNormalize.genre(item, server)).toList(),
      startIndex: query.startIndex,
      totalRecordCount: page.totalCount,
    );
  }

  // --- Playlists ---

  @override
  Future<PaginatedList<Playlist>> getPlaylistList(
    PlaylistListQuery query,
  ) async {
    final page = await _api.getPlaylistList({
      '_end': query.startIndex + (query.limit ?? 0),
      '_order': ndSortOrderMap[query.sortOrder],
      '_sort': ndPlaylistListSortMap[query.sortBy]?.value,
      '_start': query.startIndex,
      'q': query.searchTerm,
      'smart': query.excludeSmartPlaylists ? false : null,
    });

    return PaginatedList(
      items: page.items
          .map((item) => NdNormalize.playlist(item, server))
          .toList(),
      startIndex: query.startIndex,
      totalRecordCount: page.totalCount,
    );
  }

  @override
  Future<int> getPlaylistListCount(PlaylistListQuery query) async {
    final page = await getPlaylistList(query.copyWith(limit: 1, startIndex: 0));
    return page.totalRecordCount;
  }

  @override
  Future<Playlist> getPlaylistDetail(String id) async {
    final item = await _api.getPlaylistDetail(id);
    return NdNormalize.playlist(item, server);
  }

  @override
  Future<PaginatedList<Song>> getPlaylistSongList(String id) async {
    final page = await _api.getPlaylistSongList(id, {
      '_end': -1,
      '_order': 'ASC',
      '_sort': NdSongListSort.id.value,
      '_start': 0,
      ..._excludeMissing(),
    });

    return PaginatedList(
      items: page.items.map((item) => NdNormalize.song(item, server)).toList(),
      startIndex: 0,
      totalRecordCount: page.totalCount,
    );
  }

  @override
  Future<String> createPlaylist({
    required String name,
    String? comment,
    bool? public,
  }) => _api.createPlaylist({
    'name': name,
    'comment': ?comment,
    'public': ?public,
  });

  @override
  Future<void> deletePlaylist(String id) => _api.deletePlaylist(id);

  @override
  Future<void> addToPlaylist({
    required String playlistId,
    required List<String> songIds,
  }) => _api.addToPlaylist(playlistId, songIds);

  @override
  Future<void> removeFromPlaylist({
    required String playlistId,
    required List<String> playlistItemIds,
  }) => _api.removeFromPlaylist(playlistId, playlistItemIds);

  // --- Play queue ---

  @override
  Future<ServerPlayQueue> getPlayQueue() async {
    final item = await _api.getQueue();
    final queueItems = item['items'];
    final entries = queueItems is List
        ? queueItems
              .whereType<Map<String, dynamic>>()
              .map((song) => NdNormalize.song(song, server))
              .toList()
        : <Song>[];

    return ServerPlayQueue(
      changed: item['updatedAt'] as String?,
      changedBy: item['changedBy'] as String?,
      currentIndex: item['current'] is int ? item['current'] as int : 0,
      entry: entries,
      positionMs: item['position'] is int ? item['position'] as int : null,
      username: server.username,
    );
  }

  @override
  Future<void> savePlayQueue({
    required List<String> songIds,
    int? currentIndex,
    int? positionMs,
  }) =>
      _api.saveQueue(ids: songIds, current: currentIndex, position: positionMs);

  // --- Internet radio ---

  @override
  Future<List<InternetRadioStation>> getInternetRadioStations() async {
    final page = await _api.getRadioList({
      '_end': -1,
      '_order': 'ASC',
      '_sort': NdRadioListSort.name.value,
      '_start': 0,
    });

    return page.items.map(NdNormalize.internetRadioStation).toList();
  }

  // --- URL builders (Subsonic-compat endpoints, same as the original) ---

  @override
  String getStreamUrl(String id) =>
      '${server.url}/rest/stream.view?id=$id&v=1.13.0&c=Feishin'
      '&${_subsonicCredential() ?? ''}';

  @override
  String getDownloadUrl(String id) =>
      '${server.url}/rest/download.view?id=$id&v=1.13.0&c=Feishin'
      '&${_subsonicCredential() ?? ''}';

  @override
  String? getImageUrl(String id, {int? size}) {
    final credential = _subsonicCredential();
    if (credential == null) {
      return null;
    }

    // Last.fm placeholder image id, filtered out the same way as the
    // original `getSubsonicImageRequest`.
    if (id.contains('2a96cbd8b46e442fc41c2b86b821562f')) {
      return null;
    }

    return '${server.url}/rest/getCoverArt.view?id=$id&$credential'
        '&v=1.13.0&c=Feishin${size != null ? '&size=$size' : ''}';
  }

  /// Mirrors `excludeMissing` — post-BFR servers track missing files and
  /// list endpoints must filter them out.
  Map<String, dynamic> _excludeMissing() =>
      hasFeature(server, ServerFeature.bfr)
      ? const {'missing': false}
      : const {};
}
