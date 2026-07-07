import 'dart:math';

import 'package:feishin_mobile/data/music_server_repository.dart';
import 'package:feishin_mobile/data/paginated.dart';
import 'package:feishin_mobile/data/queries.dart';
import 'package:feishin_mobile/domain/domain.dart';

Album makeAlbum(String id, {String? name}) => Album(
  albumArtistName: 'Artista Teste',
  albumArtists: const [],
  artists: const [],
  comment: null,
  createdAt: '2024-01-01T00:00:00Z',
  duration: 180000,
  explicitStatus: null,
  genres: const [],
  id: id,
  imageId: null,
  imageUrl: null,
  isCompilation: false,
  lastPlayedAt: null,
  mbzId: null,
  mbzReleaseGroupId: null,
  name: name ?? 'Álbum $id',
  originalDate: null,
  originalYear: 0,
  participants: null,
  playCount: 0,
  recordLabels: const [],
  releaseDate: null,
  releaseType: null,
  releaseTypes: const [],
  releaseYear: 2020,
  serverId: 'srv-1',
  serverType: ServerType.navidrome,
  size: 0,
  songCount: 10,
  sortName: '',
  tags: null,
  updatedAt: '2024-01-01T00:00:00Z',
  userFavorite: false,
  userRating: null,
  version: null,
);

Song makeSong(String id, {String? name, int trackNumber = 1}) => Song(
  album: 'Álbum',
  albumArtistName: 'Artista Teste',
  albumArtists: const [],
  albumId: 'al-1',
  artistName: 'Artista Teste',
  artists: const [],
  bitDepth: null,
  bitRate: 320,
  bpm: null,
  channels: 2,
  comment: null,
  compilation: false,
  container: 'flac',
  createdAt: '2024-01-01T00:00:00Z',
  discNumber: 1,
  discSubtitle: null,
  duration: 200000,
  explicitStatus: null,
  gain: null,
  genres: const [],
  id: id,
  imageId: null,
  imageUrl: null,
  lastPlayedAt: null,
  lyrics: null,
  mbzRecordingId: null,
  mbzTrackId: null,
  name: name ?? 'Música $id',
  participants: null,
  path: null,
  peak: null,
  playCount: 0,
  releaseDate: null,
  releaseYear: 2020,
  sampleRate: 44100,
  serverId: 'srv-1',
  serverType: ServerType.navidrome,
  size: 1,
  sortName: '',
  tags: null,
  trackNumber: trackNumber,
  trackSubtitle: null,
  updatedAt: '2024-01-01T00:00:00Z',
  userFavorite: false,
  userRating: null,
);

/// In-memory [MusicServerRepository] covering what the phase-2 screens use;
/// everything else hits [noSuchMethod].
class FakeRepository implements MusicServerRepository {
  FakeRepository({List<Album>? albums}) : albums = albums ?? [];

  final List<Album> albums;
  int albumListCalls = 0;

  /// When set, the next [getAlbumList] call throws once.
  bool failNextAlbumList = false;

  @override
  ServerConfig get server => ServerConfig(
    id: 'srv-1',
    name: 'Fake',
    type: ServerType.navidrome,
    url: 'https://fake.example.com',
    userId: 'u1',
    username: 'demo',
  );

  @override
  Future<PaginatedList<Album>> getAlbumList(AlbumListQuery query) async {
    albumListCalls++;
    if (failNextAlbumList) {
      failNextAlbumList = false;
      throw Exception('falha simulada');
    }

    final start = min(query.startIndex, albums.length);
    final end = query.limit == null
        ? albums.length
        : min(start + query.limit!, albums.length);

    return PaginatedList(
      items: albums.sublist(start, end),
      startIndex: start,
      totalRecordCount: albums.length,
    );
  }

  @override
  Future<Album> getAlbumDetail(String id) async {
    final album = albums.firstWhere((a) => a.id == id);
    return album.copyWith(
      songs: [makeSong('s-1', trackNumber: 1), makeSong('s-2', trackNumber: 2)],
    );
  }

  @override
  String? getImageUrl(String id, {int? size}) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}
