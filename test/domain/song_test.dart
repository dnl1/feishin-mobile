import 'package:feishin_mobile/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song', () {
    test('round-trips through JSON', () {
      final song = Song(
        serverId: 'server-1',
        serverType: ServerType.navidrome,
        album: 'Test Album',
        albumArtistName: 'Test Artist',
        albumArtists: const [
          RelatedArtist(
            id: 'artist-1',
            imageId: null,
            imageUrl: null,
            name: 'Test Artist',
            userFavorite: false,
            userRating: null,
          ),
        ],
        albumId: 'album-1',
        artistName: 'Test Artist',
        artists: const [],
        bitDepth: 16,
        bitRate: 320,
        bpm: null,
        channels: 2,
        comment: null,
        compilation: false,
        container: 'flac',
        createdAt: '2026-01-01T00:00:00Z',
        discNumber: 1,
        discSubtitle: null,
        duration: 245,
        explicitStatus: null,
        gain: const GainInfo(track: -6.2, album: -6.5),
        genres: const [],
        id: 'song-1',
        imageId: null,
        imageUrl: null,
        lastPlayedAt: null,
        lyrics: null,
        mbzRecordingId: null,
        mbzTrackId: null,
        name: 'Test Song',
        participants: null,
        path: '/music/test-song.flac',
        peak: null,
        playCount: 3,
        releaseDate: '2026-01-01',
        releaseYear: 2026,
        sampleRate: 44100,
        size: 12345678,
        sortName: 'test song',
        tags: null,
        trackNumber: 1,
        trackSubtitle: null,
        updatedAt: '2026-01-01T00:00:00Z',
        userFavorite: true,
        userRating: 5,
      );

      final json = song.toJson();
      final decoded = Song.fromJson(json);

      expect(decoded, equals(song));
      expect(json['_itemType'], 'song');
      expect(json['_serverType'], 'navidrome');
    });
  });
}
