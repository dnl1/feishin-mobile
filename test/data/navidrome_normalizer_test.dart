import 'package:feishin_mobile/data/navidrome/navidrome_normalizer.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final server = ServerConfig(
  id: 'srv-1',
  name: 'Test',
  type: ServerType.navidrome,
  url: 'https://demo.navidrome.org',
  userId: 'u1',
  username: 'demo',
);

/// A representative `/api/song` item (fields per the zod schema in
/// navidrome-types.ts).
Map<String, dynamic> ndSong() => {
  'album': 'Album Name',
  'albumArtist': 'Album Artist',
  'albumArtistId': 'aa-1',
  'albumId': 'al-1',
  'artist': 'Artist Name',
  'artistId': 'ar-1',
  'bitRate': 320,
  'bookmarkPosition': 0,
  'bpm': 0,
  'channels': 2,
  'compilation': false,
  'createdAt': '2024-01-01T00:00:00Z',
  'discNumber': 1,
  'duration': 200.5,
  'fullText': ' song title',
  'genre': 'Rock',
  'genres': [
    {'id': 'g-1', 'name': 'Rock'},
  ],
  'hasCoverArt': true,
  'id': 's-1',
  'libraryPath': '/music',
  'orderAlbumArtistName': 'album artist',
  'orderAlbumName': 'album name',
  'orderArtistName': 'artist name',
  'orderTitle': 'song title',
  'path': 'Artist/Album/01.flac',
  'playCount': 3,
  'playDate': '2024-05-01T10:00:00Z',
  'rating': 4,
  'rgAlbumGain': -5.5,
  'rgAlbumPeak': 0.98,
  'rgTrackGain': -6.25,
  'rgTrackPeak': 0.99,
  'sampleRate': 44100,
  'size': 12345678,
  'sortAlbumArtistName': 'album artist',
  'sortArtistName': 'artist name',
  'starred': true,
  'starredAt': '2024-04-01T00:00:00Z',
  'suffix': 'flac',
  'title': 'Song Title',
  'trackNumber': 7,
  'updatedAt': '2024-02-01T00:00:00Z',
  'year': 2020,
};

Map<String, dynamic> ndAlbum() => {
  'albumArtist': 'Album Artist',
  'albumArtistId': 'aa-1',
  'allArtistIds': 'aa-1 ar-1',
  'artist': 'Artist Name',
  'artistId': 'ar-1',
  'compilation': false,
  'createdAt': '2024-01-01T00:00:00Z',
  'duration': 2400.5,
  'fullText': ' album name',
  'genre': 'Rock',
  'genres': [
    {'id': 'g-1', 'name': 'Rock'},
  ],
  'id': 'al-1',
  'libraryId': 1,
  'libraryName': 'Music',
  'libraryPath': '/music',
  'maxYear': 2021,
  'minYear': 1999,
  'name': 'Album Name',
  'orderAlbumArtistName': 'album artist',
  'orderAlbumName': 'album name',
  'playCount': 11,
  'rating': 5,
  'size': 987654321,
  'songCount': 12,
  'sortAlbumArtistName': 'album artist',
  'sortArtistName': 'artist name',
  'starred': false,
  'updatedAt': '2024-02-01T00:00:00Z',
};

void main() {
  group('NdNormalize.song', () {
    test('maps the full shape', () {
      final song = NdNormalize.song(ndSong(), server);

      expect(song.id, 's-1');
      expect(song.serverId, 'srv-1');
      expect(song.serverType, ServerType.navidrome);
      expect(song.name, 'Song Title');
      expect(song.album, 'Album Name');
      expect(song.albumId, 'al-1');
      expect(song.imageId, 's-1');
      expect(song.duration, 200.5 * 1000);
      expect(song.container, 'flac');
      expect(song.trackNumber, 7);
      expect(song.playCount, 3);
      expect(song.lastPlayedAt, '2024-05-01T10:00:00Z');
      expect(song.userFavorite, isTrue);
      expect(song.userRating, 4);
      expect(song.path, '/music/Artist/Album/01.flac');
      expect(song.sortName, 'song title');
      expect(song.gain, const GainInfo(album: -5.5, track: -6.25));
      expect(song.peak, const GainInfo(album: 0.98, track: 0.99));
      // TS `item.bpm ? item.bpm : null` — 0 collapses to null.
      expect(song.bpm, isNull);
      expect(song.channels, 2);
      expect(song.releaseYear, 2020);
      expect(song.releaseDate, '2020');
      expect(song.explicitStatus, isNull);
      expect(song.genres, hasLength(1));
      expect(song.genres.single.id, 'g-1');
      expect(song.genres.single.name, 'Rock');
      expect(song.albumArtists.single.id, 'aa-1');
      expect(song.albumArtists.single.name, 'Album Artist');
      expect(song.artists.single.id, 'ar-1');
      expect(song.participants, isNull);
      expect(song.playlistItemId, isNull);
    });

    test('playlist songs use mediaFileId and keep the playlist item id', () {
      final item = ndSong()
        ..['id'] = 'pl-item-9'
        ..['mediaFileId'] = 's-1'
        ..['playlistId'] = 'p-1';

      final song = NdNormalize.song(item, server);

      expect(song.id, 's-1');
      expect(song.imageId, 's-1');
      expect(song.playlistItemId, 'pl-item-9');
    });

    test('never-played Navidrome sentinel date becomes null', () {
      final item = ndSong()..['playDate'] = '0001-01-01T00:00:00Z';
      expect(NdNormalize.song(item, server).lastPlayedAt, isNull);
    });

    test('explicit status flags', () {
      expect(
        NdNormalize.song(
          ndSong()..['explicitStatus'] = 'e',
          server,
        ).explicitStatus,
        ExplicitStatus.explicit,
      );
      expect(
        NdNormalize.song(
          ndSong()..['explicitStatus'] = 'c',
          server,
        ).explicitStatus,
        ExplicitStatus.clean,
      );
    });

    test('song releaseDate takes precedence over year', () {
      final item = ndSong()..['releaseDate'] = '2019-11-22';
      final song = NdNormalize.song(item, server);
      expect(song.releaseDate, '2019-11-22');
      expect(song.releaseYear, 2019);
    });

    test('gain is null when both values are 0 (TS truthiness)', () {
      final item = ndSong()
        ..['rgAlbumGain'] = 0
        ..['rgTrackGain'] = 0;
      expect(NdNormalize.song(item, server).gain, isNull);
    });

    test('participants map roles and subRoles', () {
      final item = ndSong()
        ..['participants'] = {
          'albumartist': [
            {'id': 'aa-9', 'name': 'AA Nine'},
          ],
          'artist': [
            {'id': 'ar-9', 'name': 'Artist Nine'},
          ],
          'remixer': [
            {'id': 'rx-1', 'name': 'Remixer One'},
          ],
          'composer': [
            {'id': 'c-1', 'name': 'Composer One'},
            {'id': 'c-2', 'name': 'Composer Two', 'subRole': 'additional'},
          ],
        };

      final song = NdNormalize.song(item, server);

      expect(song.albumArtists.single.id, 'aa-9');
      // Remixers are appended to artists (deduplicated by id).
      expect(song.artists.map((a) => a.id), ['ar-9', 'rx-1']);
      expect(song.participants, isNotNull);
      expect(song.participants!.keys, [
        'remixer',
        'composer',
        'composer (additional)',
      ]);
      expect(song.participants!['composer']!.single.id, 'c-1');
      expect(song.participants!['composer (additional)']!.single.id, 'c-2');
    });

    test('subtitle tag becomes trackSubtitle', () {
      final item = ndSong()
        ..['tags'] = {
          'subtitle': ['Live', 'Remastered'],
        };
      final song = NdNormalize.song(item, server);
      expect(song.trackSubtitle, 'Live · Remastered');
      expect(song.tags, {
        'subtitle': ['Live', 'Remastered'],
      });
    });
  });

  group('NdNormalize.album', () {
    test('maps the full shape with minYear fallback dates', () {
      final album = NdNormalize.album(ndAlbum(), server);

      expect(album.id, 'al-1');
      expect(album.serverId, 'srv-1');
      expect(album.name, 'Album Name');
      expect(album.albumArtistName, 'Album Artist');
      expect(album.duration, 2400.5 * 1000);
      expect(album.songCount, 12);
      expect(album.playCount, 11);
      expect(album.userRating, 5);
      expect(album.userFavorite, isFalse);
      // No releaseDate/date fields — falls back to minYear.
      expect(album.releaseDate, '1999');
      expect(album.releaseYear, 1999);
      expect(album.originalDate, '1999');
      expect(album.originalYear, 1999);
      expect(album.imageId, 'al-1');
      expect(album.sortName, 'album name');
      expect(album.songs, isNull);
    });

    test('prefers releaseDate/originalDate fields when present', () {
      final item = ndAlbum()
        ..['releaseDate'] = '2001-05-10'
        ..['originalDate'] = '2000-01-01'
        ..['minOriginalYear'] = 1970;

      final album = NdNormalize.album(item, server);

      expect(album.releaseDate, '2001-05-10');
      expect(album.releaseYear, 2001);
      expect(album.originalDate, '2000-01-01');
      expect(album.originalYear, 2000);
    });

    test('coverArtId wins over id for the image', () {
      final item = ndAlbum()..['coverArtId'] = 'cover-9';
      expect(NdNormalize.album(item, server).imageId, 'cover-9');
    });

    test('extracts record label / release type / version from tags', () {
      final item = ndAlbum()
        ..['tags'] = {
          'albumversion': ['Deluxe', 'Edition'],
          'genre': ['Rock'],
          'media': ['CD'],
          'recordlabel': ['Label A'],
          'releasetype': ['album'],
        };

      final album = NdNormalize.album(item, server);

      expect(album.recordLabels, ['Label A']);
      expect(album.releaseTypes, ['album']);
      expect(album.version, 'Deluxe · Edition');
      // genre + extracted tags are stripped from the remaining tag map.
      expect(album.tags, {
        'media': ['CD'],
      });
    });

    test('normalizes nested songs when provided', () {
      final album = NdNormalize.album(ndAlbum(), server, songs: [ndSong()]);
      expect(album.songs, hasLength(1));
      expect(album.songs!.single.id, 's-1');
    });
  });

  group('NdNormalize.albumArtist', () {
    Map<String, dynamic> ndArtist() => {
      'albumCount': 4,
      'biography': '',
      'externalInfoUpdatedAt': '2024-03-01T00:00:00Z',
      'externalUrl': '',
      'fullText': ' artist',
      'genres': [
        {'id': 'g-1', 'name': 'Rock'},
      ],
      'id': 'aa-1',
      'mbzArtistId': 'mbz-1',
      'name': 'Album Artist',
      'orderArtistName': 'album artist',
      'playCount': 42,
      'rating': 3,
      'size': 1,
      'songCount': 50,
      'starred': true,
      'starredAt': '2024-01-01T00:00:00Z',
    };

    test('uses flat counts when stats are absent', () {
      final artist = NdNormalize.albumArtist(ndArtist(), server);

      expect(artist.albumCount, 4);
      expect(artist.songCount, 50);
      expect(artist.mbz, 'mbz-1');
      expect(artist.biography, isNull);
      expect(artist.userFavorite, isTrue);
      expect(artist.userRating, 3);
      expect(artist.imageId, 'aa-1');
      expect(artist.similarArtists, isEmpty);
    });

    test('takes the max across albumartist/artist stats', () {
      final item = ndArtist()
        ..['stats'] = {
          'albumartist': {'albumCount': 10, 'size': 1, 'songCount': 120},
          'artist': {'albumCount': 12, 'size': 1, 'songCount': 100},
        };

      final artist = NdNormalize.albumArtist(item, server);

      expect(artist.albumCount, 12);
      expect(artist.songCount, 120);
    });

    test('uploaded image busts the cache with updatedAt', () {
      final item = ndArtist()
        ..['uploadedImage'] = 'img'
        ..['updatedAt'] = '2024-06-01T00:00:00Z';

      expect(
        NdNormalize.albumArtist(item, server).imageId,
        'aa-1&_=2024-06-01T00:00:00Z',
      );
    });
  });

  group('NdNormalize.playlist', () {
    test('maps the full shape', () {
      final playlist = NdNormalize.playlist({
        'comment': 'My favorites',
        'createdAt': '2024-01-01T00:00:00Z',
        'duration': 3600.5,
        'evaluatedAt': '2024-01-02T00:00:00Z',
        'id': 'p-1',
        'name': 'Favorites',
        'ownerId': 'u1',
        'ownerName': 'demo',
        'path': '',
        'public': true,
        'rules': {'limit': 100},
        'size': 1000,
        'songCount': 25,
        'sync': false,
        'updatedAt': '2024-02-01T00:00:00Z',
      }, server);

      expect(playlist.id, 'p-1');
      expect(playlist.description, 'My favorites');
      expect(playlist.duration, 3600.5 * 1000);
      expect(playlist.owner, 'demo');
      expect(playlist.ownerId, 'u1');
      expect(playlist.public, isTrue);
      expect(playlist.rules, {'limit': 100});
      expect(playlist.songCount, 25);
      expect(playlist.sync, isFalse);
      expect(playlist.imageId, 'p-1');
    });
  });

  group('NdNormalize.genre / user / internetRadioStation', () {
    test('genre keeps counts when present', () {
      final genre = NdNormalize.genre({
        'albumCount': 5,
        'id': 'g-1',
        'name': 'Rock',
        'songCount': 50,
      }, server);

      expect(genre.albumCount, 5);
      expect(genre.songCount, 50);
      expect(genre.name, 'Rock');
    });

    test('user maps userName and collapses empty email', () {
      final user = NdNormalize.user({
        'createdAt': '2024-01-01T00:00:00Z',
        'email': '',
        'id': 'u-1',
        'isAdmin': true,
        'lastAccessAt': '2024-06-01T00:00:00Z',
        'lastLoginAt': '2024-06-01T00:00:00Z',
        'name': 'Demo',
        'updatedAt': '2024-02-01T00:00:00Z',
        'userName': 'demo',
      });

      expect(user.name, 'demo');
      expect(user.email, isNull);
      expect(user.isAdmin, isTrue);
    });

    test('radio station blanks out whitespace-only homepage', () {
      final station = NdNormalize.internetRadioStation({
        'createdAt': '2024-01-01T00:00:00Z',
        'homePageUrl': '   ',
        'id': 'r-1',
        'name': 'Radio',
        'streamUrl': 'https://stream.example.com',
        'updatedAt': '2024-02-01T00:00:00Z',
      });

      expect(station.homepageUrl, isNull);
      expect(station.streamUrl, 'https://stream.example.com');
      expect(station.imageId, 'r-1');
    });
  });
}
