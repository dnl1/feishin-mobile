import 'package:feishin_mobile/core/server_features.dart';
import 'package:feishin_mobile/data/navidrome/navidrome_repository.dart';
import 'package:feishin_mobile/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

ServerConfig _server(Map<String, dynamic>? features) => ServerConfig(
  features: features,
  id: 's1',
  name: 'Test',
  type: ServerType.navidrome,
  url: 'https://demo.navidrome.org',
  userId: 'u1',
  username: 'demo',
);

void main() {
  group('getFeatures (navidromeVersionInfo)', () {
    test('0.55.x gets BFR/tags plus everything below', () {
      final features = getFeatures(navidromeVersionInfo, '0.55.2');

      expect(features[ServerFeature.bfr.key], [1]);
      expect(features[ServerFeature.tags.key], [1]);
      expect(features[ServerFeature.sharingAlbumSong.key], [1]);
      expect(features[ServerFeature.playlistsSmart.key], [1]);
      expect(features.containsKey(ServerFeature.serverPlayQueue.key), isFalse);
      expect(
        features.containsKey(ServerFeature.trackAlbumArtistSearch.key),
        isFalse,
      );
    });

    test('0.61.0 gets every feature', () {
      final features = getFeatures(navidromeVersionInfo, '0.61.0');

      expect(features[ServerFeature.artistImageUpload.key], [1]);
      expect(features[ServerFeature.serverPlayQueue.key], [2]);
      expect(features[ServerFeature.bfr.key], [1]);
    });

    test('0.47.0 gets nothing', () {
      expect(getFeatures(navidromeVersionInfo, '0.47.0'), isEmpty);
    });

    test('handles version strings with suffixes', () {
      final features = getFeatures(navidromeVersionInfo, '0.56.1 (fc8f494f)');
      expect(features[ServerFeature.trackAlbumArtistSearch.key], [1]);
    });

    test('uncoercible version enables everything (same as TS)', () {
      final features = getFeatures(navidromeVersionInfo, 'garbage');
      expect(features[ServerFeature.artistImageUpload.key], [1]);
      expect(features[ServerFeature.playlistsSmart.key], [1]);
    });
  });

  group('hasFeature', () {
    test('works with JSON round-tripped feature lists', () {
      // jsonDecode produces List<dynamic>, not List<int> — the check must
      // still work on the decoded shape.
      final server = _server({
        'bfr': <dynamic>[1],
        'tags': <dynamic>[],
      });

      expect(hasFeature(server, ServerFeature.bfr), isTrue);
      expect(hasFeature(server, ServerFeature.tags), isFalse);
      expect(hasFeature(server, ServerFeature.serverPlayQueue), isFalse);
      expect(hasFeature(_server(null), ServerFeature.bfr), isFalse);
    });

    test('hasFeatureWithVersion matches exact versions', () {
      final server = _server({
        'serverPlayQueue': <dynamic>[2],
      });

      expect(
        hasFeatureWithVersion(server, ServerFeature.serverPlayQueue, 2),
        isTrue,
      );
      expect(
        hasFeatureWithVersion(server, ServerFeature.serverPlayQueue, 1),
        isFalse,
      );
    });
  });
}
