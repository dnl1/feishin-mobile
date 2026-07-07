import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/music_server_repository.dart';
import '../../data/paginated.dart';
import '../../data/queries.dart';
import '../../data/repository_provider.dart';
import '../../domain/domain.dart';
import 'paged_list.dart';

/// Provider-family keys — records so equality comes for free.
typedef AlbumsArg = ({
  String? artistId,
  String? genreId,
  AlbumListSort sortBy,
  SortOrder sortOrder,
});

typedef SongsArg = ({
  String? albumArtistId,
  String? genreId,
  SongListSort sortBy,
  SortOrder sortOrder,
});

typedef ArtistsArg = ({AlbumArtistListSort sortBy, SortOrder sortOrder});

typedef GenresArg = ({GenreListSort sortBy, SortOrder sortOrder});

typedef PlaylistsArg = ({PlaylistListSort sortBy, SortOrder sortOrder});

class AlbumListController extends PagedListController<Album> {
  AlbumListController(this.arg);

  final AlbumsArg arg;

  @override
  Future<PaginatedList<Album>> fetchPage(int startIndex, int limit) =>
      repository.getAlbumList(
        AlbumListQuery(
          artistIds: arg.artistId != null ? [arg.artistId!] : null,
          genreIds: arg.genreId != null ? [arg.genreId!] : null,
          limit: limit,
          sortBy: arg.sortBy,
          sortOrder: arg.sortOrder,
          startIndex: startIndex,
        ),
      );
}

final albumListControllerProvider =
    AsyncNotifierProvider.family<
      AlbumListController,
      PagedListState<Album>,
      AlbumsArg
    >(AlbumListController.new);

class SongListController extends PagedListController<Song> {
  SongListController(this.arg);

  final SongsArg arg;

  @override
  Future<PaginatedList<Song>> fetchPage(int startIndex, int limit) =>
      repository.getSongList(
        SongListQuery(
          albumArtistIds: arg.albumArtistId != null
              ? [arg.albumArtistId!]
              : null,
          genreIds: arg.genreId != null ? [arg.genreId!] : null,
          limit: limit,
          sortBy: arg.sortBy,
          sortOrder: arg.sortOrder,
          startIndex: startIndex,
        ),
      );
}

final songListControllerProvider =
    AsyncNotifierProvider.family<
      SongListController,
      PagedListState<Song>,
      SongsArg
    >(SongListController.new);

class ArtistListController extends PagedListController<AlbumArtist> {
  ArtistListController(this.arg);

  final ArtistsArg arg;

  @override
  Future<PaginatedList<AlbumArtist>> fetchPage(int startIndex, int limit) =>
      repository.getAlbumArtistList(
        AlbumArtistListQuery(
          limit: limit,
          sortBy: arg.sortBy,
          sortOrder: arg.sortOrder,
          startIndex: startIndex,
        ),
      );
}

final artistListControllerProvider =
    AsyncNotifierProvider.family<
      ArtistListController,
      PagedListState<AlbumArtist>,
      ArtistsArg
    >(ArtistListController.new);

class GenreListController extends PagedListController<Genre> {
  GenreListController(this.arg);

  final GenresArg arg;

  @override
  Future<PaginatedList<Genre>> fetchPage(int startIndex, int limit) =>
      repository.getGenreList(
        GenreListQuery(
          limit: limit,
          sortBy: arg.sortBy,
          sortOrder: arg.sortOrder,
          startIndex: startIndex,
        ),
      );
}

final genreListControllerProvider =
    AsyncNotifierProvider.family<
      GenreListController,
      PagedListState<Genre>,
      GenresArg
    >(GenreListController.new);

class PlaylistListController extends PagedListController<Playlist> {
  PlaylistListController(this.arg);

  final PlaylistsArg arg;

  @override
  Future<PaginatedList<Playlist>> fetchPage(int startIndex, int limit) =>
      repository.getPlaylistList(
        PlaylistListQuery(
          limit: limit,
          sortBy: arg.sortBy,
          sortOrder: arg.sortOrder,
          startIndex: startIndex,
        ),
      );
}

final playlistListControllerProvider =
    AsyncNotifierProvider.family<
      PlaylistListController,
      PagedListState<Playlist>,
      PlaylistsArg
    >(PlaylistListController.new);

// --- Details ---

Future<T> _withRepository<T>(
  Ref ref,
  Future<T> Function(MusicServerRepository repository) run,
) async {
  final repository = await ref.watch(musicServerRepositoryProvider.future);
  if (repository == null) {
    throw StateError('Nenhum servidor selecionado');
  }
  return run(repository);
}

/// Album with songs (mirrors `getAlbumDetail`: album + song list).
final albumDetailProvider = FutureProvider.family<Album, String>(
  (ref, id) => _withRepository(ref, (repo) => repo.getAlbumDetail(id)),
);

final artistDetailProvider = FutureProvider.family<AlbumArtist, String>(
  (ref, id) => _withRepository(ref, (repo) => repo.getAlbumArtistDetail(id)),
);

final playlistDetailProvider = FutureProvider.family<Playlist, String>(
  (ref, id) => _withRepository(ref, (repo) => repo.getPlaylistDetail(id)),
);

/// All songs of a playlist (the ND endpoint returns the full list).
final playlistSongsProvider = FutureProvider.family<List<Song>, String>((
  ref,
  id,
) async {
  final page = await _withRepository(
    ref,
    (repo) => repo.getPlaylistSongList(id),
  );
  return page.items;
});

final radioStationsProvider = FutureProvider<List<InternetRadioStation>>(
  (ref) => _withRepository(ref, (repo) => repo.getInternetRadioStations()),
);

/// Cover-art URL for the current server (null when unavailable).
final imageUrlProvider =
    Provider.family<String?, ({String? imageId, int size})>((ref, arg) {
      final repository = ref.watch(musicServerRepositoryProvider).value;
      final imageId = arg.imageId;
      if (repository == null || imageId == null) {
        return null;
      }
      return repository.getImageUrl(imageId, size: arg.size);
    });
