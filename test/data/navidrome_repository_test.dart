import 'package:dio/dio.dart';
import 'package:feishin_mobile/data/navidrome/navidrome_api.dart';
import 'package:feishin_mobile/data/navidrome/navidrome_repository.dart';
import 'package:feishin_mobile/data/queries.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_http_adapter.dart';

Map<String, dynamic> ndSongJson(String id) => {
  'album': 'Album',
  'albumArtist': 'AA',
  'albumArtistId': 'aa-1',
  'albumId': 'al-1',
  'artist': 'A',
  'artistId': 'ar-1',
  'bitRate': 320,
  'bookmarkPosition': 0,
  'compilation': false,
  'createdAt': '2024-01-01T00:00:00Z',
  'discNumber': 1,
  'duration': 100,
  'fullText': '',
  'genre': '',
  'genres': null,
  'hasCoverArt': true,
  'id': id,
  'orderAlbumArtistName': '',
  'orderAlbumName': '',
  'orderArtistName': '',
  'orderTitle': '',
  'path': 'x.flac',
  'sampleRate': 44100,
  'size': 1,
  'sortAlbumArtistName': '',
  'sortArtistName': '',
  'starred': false,
  'suffix': 'flac',
  'title': 'Song $id',
  'trackNumber': 1,
  'updatedAt': '2024-01-01T00:00:00Z',
  'year': 2020,
};

(NavidromeRepository, FakeHttpAdapter) buildRepository(
  FakeHandler handler, {
  Map<String, dynamic>? features,
  String? credential = 'u=demo&s=abc&t=def',
}) {
  final adapter = FakeHttpAdapter(handler);
  final dio = NavidromeApi.defaultDio()..httpClientAdapter = adapter;

  final server = ServerConfig(
    features: features,
    id: 'srv-1',
    name: 'Test',
    type: ServerType.navidrome,
    url: 'https://music.example.com',
    userId: 'u1',
    username: 'demo',
  );

  final repository = NavidromeRepository(
    server: server,
    api: NavidromeApi(
      serverUrl: server.url,
      tokenProvider: () => 'tok',
      dio: dio,
    ),
    subsonicCredential: () => credential,
  );

  return (repository, adapter);
}

ResponseBody emptyList(RequestOptions options) => jsonResponse(
  [],
  headers: {
    'x-total-count': ['7'],
  },
);

void main() {
  group('getSongList', () {
    test('pre-BFR: album_artist_id key, no missing filter', () async {
      final (repository, adapter) = buildRepository(emptyList);

      await repository.getSongList(
        const SongListQuery(albumArtistIds: ['aa-1'], limit: 50),
      );

      final query = adapter.requests.single.uri.queryParametersAll;
      expect(query['album_artist_id'], ['aa-1']);
      expect(query.containsKey('artists_id'), isFalse);
      expect(query.containsKey('missing'), isFalse);
      expect(query['_sort'], ['title']);
      expect(query['_order'], ['ASC']);
      expect(query['_start'], ['0']);
      expect(query['_end'], ['50']);
    });

    test('post-BFR: artists_id key and missing=false', () async {
      final (repository, adapter) = buildRepository(
        emptyList,
        features: {
          'bfr': [1],
          'trackAlbumArtistSearch': [1],
        },
      );

      await repository.getSongList(
        const SongListQuery(albumArtistIds: ['aa-1']),
      );

      final query = adapter.requests.single.uri.queryParametersAll;
      expect(query['artists_id'], ['aa-1']);
      expect(query['missing'], ['false']);
      // No limit — mirrors `_end: startIndex + (limit || -1)`.
      expect(query['_end'], ['-1']);
    });

    test('count uses limit 1 and reads x-total-count', () async {
      final (repository, adapter) = buildRepository(emptyList);

      final count = await repository.getSongListCount(const SongListQuery());

      expect(count, 7);
      expect(adapter.requests.single.uri.queryParametersAll['_end'], ['1']);
    });
  });

  group('getGenreList', () {
    test('pre-BFR uses the genre endpoint', () async {
      final (repository, adapter) = buildRepository(
        (options) => jsonResponse(
          [
            {'id': 'g-1', 'name': 'Rock'},
          ],
          headers: {
            'x-total-count': ['1'],
          },
        ),
      );

      final page = await repository.getGenreList(const GenreListQuery());

      expect(adapter.requests.single.uri.path, '/api/genre');
      expect(page.items.single.name, 'Rock');
    });

    test('post-BFR uses the tag endpoint and maps tagValue', () async {
      final (repository, adapter) = buildRepository(
        (options) => jsonResponse(
          [
            {'albumCount': 3, 'id': 't-1', 'songCount': 30, 'tagValue': 'Jazz'},
          ],
          headers: {
            'x-total-count': ['1'],
          },
        ),
        features: {
          'bfr': [1],
        },
      );

      final page = await repository.getGenreList(const GenreListQuery());

      final request = adapter.requests.single;
      expect(request.uri.path, '/api/tag');
      expect(request.uri.queryParameters['tag_name'], 'genre');
      expect(page.items.single.name, 'Jazz');
      expect(page.items.single.albumCount, 3);
      expect(page.items.single.songCount, 30);
    });
  });

  group('getAlbumArtistList', () {
    test('post-BFR filters by role=albumartist', () async {
      final (repository, adapter) = buildRepository(
        emptyList,
        features: {
          'bfr': [1],
        },
      );

      await repository.getAlbumArtistList(const AlbumArtistListQuery());

      expect(
        adapter.requests.single.uri.queryParameters['role'],
        'albumartist',
      );
    });

    test('pre-BFR sends an empty role', () async {
      final (repository, adapter) = buildRepository(emptyList);

      await repository.getAlbumArtistList(const AlbumArtistListQuery());

      expect(adapter.requests.single.uri.queryParametersAll['role'], ['']);
    });
  });

  test('getAlbumDetail fetches the album and its songs', () async {
    final (repository, adapter) = buildRepository((options) {
      if (options.uri.path == '/api/album/al-1') {
        return jsonResponse({
          'albumArtist': 'AA',
          'albumArtistId': 'aa-1',
          'allArtistIds': '',
          'artist': 'A',
          'artistId': 'ar-1',
          'compilation': false,
          'createdAt': '2024-01-01T00:00:00Z',
          'fullText': '',
          'genre': '',
          'genres': null,
          'id': 'al-1',
          'libraryId': 1,
          'libraryName': 'Music',
          'libraryPath': '/music',
          'maxYear': 2020,
          'minYear': 2020,
          'name': 'Album',
          'orderAlbumArtistName': '',
          'orderAlbumName': '',
          'size': 1,
          'songCount': 2,
          'sortAlbumArtistName': '',
          'sortArtistName': '',
          'starred': false,
          'updatedAt': '2024-01-01T00:00:00Z',
        });
      }

      expect(options.uri.path, '/api/song');
      expect(options.uri.queryParametersAll['album_id'], ['al-1']);
      return jsonResponse([ndSongJson('s-1'), ndSongJson('s-2')]);
    });

    final album = await repository.getAlbumDetail('al-1');

    expect(adapter.requests, hasLength(2));
    expect(album.id, 'al-1');
    expect(album.songs!.map((s) => s.id), ['s-1', 's-2']);
  });

  test('getPlaylistSongList requests all tracks sorted by id', () async {
    final (repository, adapter) = buildRepository(
      (options) => jsonResponse(
        [
          {
            ...ndSongJson('s-1'),
            'id': 'item-1',
            'mediaFileId': 's-1',
            'playlistId': 'p-1',
          },
        ],
        headers: {
          'x-total-count': ['1'],
        },
      ),
    );

    final page = await repository.getPlaylistSongList('p-1');

    final request = adapter.requests.single;
    expect(request.uri.path, '/api/playlist/p-1/tracks');
    expect(request.uri.queryParametersAll['_end'], ['-1']);
    expect(request.uri.queryParametersAll['_sort'], ['id']);
    expect(page.items.single.id, 's-1');
    expect(page.items.single.playlistItemId, 'item-1');
  });

  group('URL builders', () {
    test('stream/download/image URLs embed the subsonic credential', () {
      final (repository, _) = buildRepository(emptyList);

      expect(
        repository.getStreamUrl('s-1'),
        'https://music.example.com/rest/stream.view'
        '?id=s-1&v=1.13.0&c=Feishin&u=demo&s=abc&t=def',
      );
      expect(
        repository.getDownloadUrl('s-1'),
        'https://music.example.com/rest/download.view'
        '?id=s-1&v=1.13.0&c=Feishin&u=demo&s=abc&t=def',
      );
      expect(
        repository.getImageUrl('al-1', size: 300),
        'https://music.example.com/rest/getCoverArt.view'
        '?id=al-1&u=demo&s=abc&t=def&v=1.13.0&c=Feishin&size=300',
      );
    });

    test('image URL is null without credential or for the placeholder', () {
      final (repository, _) = buildRepository(emptyList, credential: null);
      expect(repository.getImageUrl('al-1'), isNull);

      final (withCredential, _) = buildRepository(emptyList);
      expect(
        withCredential.getImageUrl('2a96cbd8b46e442fc41c2b86b821562f'),
        isNull,
      );
    });
  });
}
