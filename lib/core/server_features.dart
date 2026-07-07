/// Server feature detection, ported from
/// feishin/src/shared/types/features-types.ts and the `getFeatures`/
/// `hasFeature` helpers in feishin/src/shared/api/utils.ts.
///
/// Features are stored on [ServerConfig.features] as a plain JSON map
/// (`featureName -> [versions]`), same shape the original app persists.
library;

import '../domain/server.dart';

/// Mirrors `ServerFeature` in feishin/src/shared/types/features-types.ts.
enum ServerFeature {
  albumYesNoRatingFilter('albumYesNoRatingFilter'),
  artistImageUpload('artistImageUpload'),
  bfr('bfr'),
  internetRadioImageUpload('internetRadioImageUpload'),
  lyricsMultipleStructured('lyricsMultipleStructured'),
  lyricsSingleStructured('lyricsSingleStructured'),
  musicFolderMultiselect('musicFolderMultiselect'),
  osFormPost('osFormPost'),
  osTranscodeDecision('osTranscodeDecision'),
  playlistImageUpload('playlistImageUpload'),
  playlistsSmart('playlistsSmart'),
  publicPlaylist('publicPlaylist'),
  reportPlayback('reportPlayback'),
  serverPlayQueue('serverPlayQueue'),
  sharingAlbumSong('sharingAlbumSong'),
  similarSongsMusicFolder('similarSongsMusicFolder'),
  tags('tags'),
  trackAlbumArtistSearch('trackAlbumArtistSearch'),
  trackYesNoRatingFilter('trackYesNoRatingFilter');

  const ServerFeature(this.key);

  /// JSON key, identical to the TS enum value.
  final String key;
}

typedef VersionInfo = List<(String, Map<ServerFeature, List<int>>)>;

bool hasFeature(ServerConfig? server, ServerFeature feature) {
  final versions = server?.features?[feature.key];
  return versions is List && versions.isNotEmpty;
}

bool hasFeatureWithVersion(
  ServerConfig? server,
  ServerFeature feature,
  int version,
) {
  final versions = server?.features?[feature.key];
  return versions is List && versions.contains(version);
}

/// Returns the available server features given the version string.
///
/// [versionInfo] must be in DECREASING version order — the first version
/// match automatically considers the rest matched (same contract as the TS
/// `getFeatures`).
Map<String, List<int>> getFeatures(VersionInfo versionInfo, String version) {
  final cleanVersion = _coerceSemver(version);
  final features = <String, List<int>>{};
  var matched = cleanVersion == null;

  for (final (minVersion, supportedFeatures) in versionInfo) {
    if (!matched) {
      matched = _semverGte(cleanVersion!, _coerceSemver(minVersion)!);
    }

    if (matched) {
      for (final entry in supportedFeatures.entries) {
        features.putIfAbsent(entry.key.key, () => []).addAll(entry.value);
      }
    }
  }

  return features;
}

final RegExp _semverPattern = RegExp(r'(\d+)(?:\.(\d+))?(?:\.(\d+))?');

/// Extracts `(major, minor, patch)` from a loose version string, mirroring
/// semver's `coerce` (e.g. `"0.55.0 (deadbeef)"` -> `(0, 55, 0)`).
(int, int, int)? _coerceSemver(String version) {
  final match = _semverPattern.firstMatch(version);
  if (match == null) {
    return null;
  }

  return (
    int.parse(match.group(1)!),
    int.tryParse(match.group(2) ?? '') ?? 0,
    int.tryParse(match.group(3) ?? '') ?? 0,
  );
}

bool _semverGte((int, int, int) a, (int, int, int) b) {
  if (a.$1 != b.$1) return a.$1 > b.$1;
  if (a.$2 != b.$2) return a.$2 > b.$2;
  return a.$3 >= b.$3;
}
