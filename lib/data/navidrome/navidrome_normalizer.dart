/// Navidrome JSON → domain model, ported 1:1 from
/// feishin/src/shared/api/navidrome/navidrome-normalize.ts.
///
/// Works directly on decoded JSON maps (the zod schemas in the original are
/// structurally the raw JSON), so there is no intermediate DTO layer.
library;

import '../../core/partial_iso_date.dart';
import '../../domain/domain.dart';

class NdNormalize {
  const NdNormalize._();

  static Song song(Map<String, dynamic> item, ServerConfig? server) {
    // Dynamically determine the id field based on whether or not the item is
    // a playlist song.
    final String id;
    String? playlistItemId;
    if (item.containsKey('mediaFileId')) {
      id = item['mediaFileId'] as String;
      playlistItemId = _string(item['id']);
    } else {
      id = item['id'] as String;
    }

    final fromSongRelease = parsePartialIsoDate(_string(item['releaseDate']));
    final songApiYear = coerceYear(_num(item['year']));
    final releaseYear = fromSongRelease.year > 0
        ? fromSongRelease.year
        : songApiYear > 0
        ? songApiYear
        : null;
    final releaseDate =
        fromSongRelease.date ?? (songApiYear > 0 ? '$songApiYear' : null);

    final artists = _getArtists(item, includeRemixers: true);
    final tags = _stringListMap(item['tags']);
    final subtitle = tags?['subtitle'];
    final rgAlbumGain = _num(item['rgAlbumGain']);
    final rgTrackGain = _num(item['rgTrackGain']);
    final rgAlbumPeak = _num(item['rgAlbumPeak']);
    final rgTrackPeak = _num(item['rgTrackPeak']);
    final path = _string(item['path']);

    return Song(
      album: _string(item['album']),
      albumArtistName: _string(item['albumArtist']) ?? '',
      albumArtists: artists.albumArtists,
      albumId: _string(item['albumId']) ?? '',
      artistName: _string(item['artist']) ?? '',
      artists: artists.artists,
      bitDepth: _truthyInt(item['bitDepth']),
      bitRate: _num(item['bitRate']) ?? 0,
      bpm: _truthyNum(item['bpm']),
      channels: _truthyInt(item['channels']),
      comment: _truthyString(item['comment']),
      compilation: item['compilation'] as bool?,
      container: _string(item['suffix']),
      createdAt: _string(item['createdAt']) ?? '',
      discNumber: _int(item['discNumber']) ?? 0,
      discSubtitle: _truthyString(item['discSubtitle']),
      duration: (_num(item['duration']) ?? 0) * 1000,
      explicitStatus: _explicitStatus(item['explicitStatus']),
      gain: _isTruthy(rgAlbumGain) || _isTruthy(rgTrackGain)
          ? GainInfo(
              album: rgAlbumGain?.toDouble(),
              track: rgTrackGain?.toDouble(),
            )
          : null,
      genres: _genres(item['genres'], server),
      id: id,
      imageId: id,
      imageUrl: null,
      lastPlayedAt: _playDate(item),
      lyrics: _truthyString(item['lyrics']),
      mbzRecordingId: _truthyString(item['mbzReleaseTrackId']),
      mbzTrackId: _truthyString(item['mbzReleaseTrackId']),
      name: _string(item['title']) ?? '',
      participants: artists.participants,
      path: path != null && path.isNotEmpty
          ? '${_string(item['libraryPath']) ?? ''}/$path'
          : null,
      peak: _isTruthy(rgAlbumPeak) || _isTruthy(rgTrackPeak)
          ? GainInfo(
              album: rgAlbumPeak?.toDouble(),
              track: rgTrackPeak?.toDouble(),
            )
          : null,
      playCount: _int(item['playCount']) ?? 0,
      playlistItemId: playlistItemId,
      releaseDate: releaseDate,
      releaseYear: releaseYear,
      sampleRate: _truthyInt(item['sampleRate']),
      serverId: server?.id ?? 'unknown',
      serverType: ServerType.navidrome,
      size: _num(item['size']) ?? 0,
      sortName: _string(item['orderTitle']) ?? '',
      tags: tags,
      trackNumber: _int(item['trackNumber']) ?? 0,
      trackSubtitle: subtitle != null && subtitle.isNotEmpty
          ? subtitle.join(' · ')
          : null,
      updatedAt: _string(item['updatedAt']) ?? '',
      userFavorite: item['starred'] == true,
      userRating: _truthyInt(item['rating']),
    );
  }

  static Album album(
    Map<String, dynamic> item,
    ServerConfig? server, {
    List<Map<String, dynamic>>? songs,
  }) {
    final releaseDate = _releaseDate(item);
    final originalDate = _originalDate(item);
    final parsedTags = _parseAlbumTags(item);
    final artists = _getArtists(item, includeRemixers: false);
    final duration = _num(item['duration']);

    return Album(
      albumArtistName: _string(item['albumArtist']) ?? '',
      albumArtists: artists.albumArtists,
      artists: artists.artists,
      comment: _truthyString(item['comment']),
      createdAt: _string(item['createdAt']) ?? '',
      duration: duration != null ? duration * 1000 : null,
      explicitStatus: _explicitStatus(item['explicitStatus']),
      genres: _genres(item['genres'], server),
      id: item['id'] as String,
      imageId: _truthyString(item['coverArtId']) ?? _string(item['id']),
      imageUrl: null,
      isCompilation: item['compilation'] as bool?,
      lastPlayedAt: _playDate(item),
      mbzId: _truthyString(item['mbzAlbumId']),
      mbzReleaseGroupId: _truthyString(item['mbzReleaseGroupId']),
      name: _string(item['name']) ?? '',
      originalDate: originalDate.date,
      originalYear: originalDate.year,
      participants: artists.participants,
      playCount: _int(item['playCount']) ?? 0,
      recordLabels: parsedTags.recordLabels,
      releaseDate: releaseDate.date,
      releaseType: _truthyString(item['mbzAlbumType']),
      releaseTypes: parsedTags.releaseTypes,
      releaseYear: releaseDate.year > 0 ? releaseDate.year : null,
      serverId: server?.id ?? 'unknown',
      serverType: ServerType.navidrome,
      size: _num(item['size']),
      songCount: _int(item['songCount']),
      songs: songs?.map((s) => song(s, server)).toList(),
      sortName: _string(item['orderAlbumName']) ?? '',
      tags: parsedTags.tags,
      updatedAt: _string(item['updatedAt']) ?? '',
      userFavorite: item['starred'] == true,
      userRating: _truthyInt(item['rating']),
      version: parsedTags.version,
    );
  }

  static AlbumArtist albumArtist(
    Map<String, dynamic> item,
    ServerConfig? server, {
    List<Map<String, dynamic>>? similarArtists,
  }) {
    int albumCount;
    int songCount;

    final stats = item['stats'];
    if (stats is Map<String, dynamic>) {
      final albumArtistStats = _map(stats['albumartist']);
      final artistStats = _map(stats['artist']);
      albumCount = _maxInt(
        _int(albumArtistStats?['albumCount']),
        _int(artistStats?['albumCount']),
      );
      songCount = _maxInt(
        _int(albumArtistStats?['songCount']),
        _int(artistStats?['songCount']),
      );
    } else {
      albumCount = _int(item['albumCount']) ?? 0;
      songCount = _int(item['songCount']) ?? 0;
    }

    final imageId = _imageIdWithCacheBust(
      item['id'] as String,
      _string(item['uploadedImage']),
      _string(item['updatedAt']) ?? _string(item['externalInfoUpdatedAt']),
    );

    return AlbumArtist(
      albumCount: albumCount,
      biography: _truthyString(item['biography']),
      duration: null,
      genres: _genres(item['genres'], server),
      id: item['id'] as String,
      imageId: imageId,
      imageUrl: null,
      lastPlayedAt: _playDate(item),
      mbz: _truthyString(item['mbzArtistId']),
      name: _string(item['name']) ?? '',
      playCount: _int(item['playCount']) ?? 0,
      serverId: server?.id ?? 'unknown',
      serverType: ServerType.navidrome,
      similarArtists:
          similarArtists
              ?.map(
                (artist) => RelatedArtist(
                  id: artist['id'] as String,
                  imageId: artist['id'] as String,
                  imageUrl: null,
                  name: _string(artist['name']) ?? '',
                  userFavorite: _isTruthy(artist['starred']),
                  userRating: _int(artist['userRating']),
                ),
              )
              .toList() ??
          const [],
      songCount: songCount,
      uploadedImage: _string(item['uploadedImage']),
      userFavorite: item['starred'] == true,
      userRating: _truthyInt(item['rating']),
    );
  }

  static Playlist playlist(Map<String, dynamic> item, ServerConfig? server) {
    final imageId = _imageIdWithCacheBust(
      item['id'] as String,
      _string(item['uploadedImage']),
      _string(item['updatedAt']),
    );

    return Playlist(
      description: _string(item['comment']),
      duration: (_num(item['duration']) ?? 0) * 1000,
      genres: const [],
      id: item['id'] as String,
      imageId: imageId,
      imageUrl: null,
      name: _string(item['name']) ?? '',
      owner: _string(item['ownerName']),
      ownerId: _string(item['ownerId']),
      public: item['public'] as bool?,
      rules: _map(item['rules']),
      serverId: server?.id ?? 'unknown',
      serverType: ServerType.navidrome,
      size: _num(item['size']),
      songCount: _int(item['songCount']),
      sync: item['sync'] as bool?,
      uploadedImage: _string(item['uploadedImage']),
    );
  }

  static Genre genre(Map<String, dynamic> item, ServerConfig? server) {
    return Genre(
      albumCount: _int(item['albumCount']),
      id: item['id'] as String,
      imageId: null,
      imageUrl: null,
      name: _string(item['name']) ?? '',
      serverId: server?.id ?? 'unknown',
      serverType: ServerType.navidrome,
      songCount: _int(item['songCount']),
    );
  }

  static User user(Map<String, dynamic> item) {
    return User(
      createdAt: _string(item['createdAt']),
      email: _truthyString(item['email']),
      id: item['id'] as String,
      isAdmin: item['isAdmin'] as bool?,
      lastLoginAt: _string(item['lastLoginAt']),
      name: _string(item['userName']) ?? '',
      updatedAt: _string(item['updatedAt']),
    );
  }

  static InternetRadioStation internetRadioStation(Map<String, dynamic> item) {
    final homePageUrl = _string(item['homePageUrl']);
    final imageId = _imageIdWithCacheBust(
      item['id'] as String,
      _string(item['uploadedImage']),
      _string(item['updatedAt']),
    );

    return InternetRadioStation(
      homepageUrl: homePageUrl != null && homePageUrl.trim().isNotEmpty
          ? homePageUrl
          : null,
      id: item['id'] as String,
      imageId: imageId,
      imageUrl: null,
      name: _string(item['name']) ?? '',
      streamUrl: _string(item['streamUrl']) ?? '',
      uploadedImage: _truthyString(item['uploadedImage']),
    );
  }

  // --- Internals, mirroring the top-level helpers in the TS file ---

  /// Mirrors `navidromeImageIdWithCacheBust`.
  static String _imageIdWithCacheBust(
    String id,
    String? uploadedImage,
    String? updatedAt,
  ) => uploadedImage == null || uploadedImage.isEmpty
      ? id
      : '$id&_=${updatedAt ?? ''}';

  /// Mirrors `normalizePlayDate` (Navidrome uses `0001-01-01...` as "never").
  static String? _playDate(Map<String, dynamic> item) {
    final playDate = _string(item['playDate']);
    return playDate == null || playDate.isEmpty || playDate.contains('0001-')
        ? null
        : playDate;
  }

  /// Mirrors `normalizeNavidromeReleaseDate`.
  static PartialIsoDate _releaseDate(Map<String, dynamic> item) {
    final fromRelease = parsePartialIsoDate(_string(item['releaseDate']));
    if (fromRelease.date != null) {
      return fromRelease;
    }

    final fromDateField = parsePartialIsoDate(_string(item['date']));
    if (fromDateField.date != null) {
      return fromDateField;
    }

    final y = coerceYear(_num(item['minYear']));
    if (y > 0) {
      return (date: '$y', year: y);
    }

    return (date: null, year: 0);
  }

  /// Mirrors `normalizeNavidromeOriginalDate`.
  static PartialIsoDate _originalDate(Map<String, dynamic> item) {
    final fromOriginal = parsePartialIsoDate(_string(item['originalDate']));
    if (fromOriginal.date != null) {
      return fromOriginal;
    }

    final fromRelease = parsePartialIsoDate(_string(item['releaseDate']));
    if (fromRelease.date != null) {
      return fromRelease;
    }

    final fromDateField = parsePartialIsoDate(_string(item['date']));
    if (fromDateField.date != null) {
      return fromDateField;
    }

    final y = coerceYear(_num(item['minOriginalYear']) ?? _num(item['minYear']));
    if (y > 0) {
      return (date: '$y', year: y);
    }

    return (date: null, year: 0);
  }

  /// Mirrors `getArtists` — resolves album artists, artists, and the
  /// participants map (with `role (subRole)` grouping) from either the
  /// post-BFR `participants` object or the legacy flat fields.
  static ({
    List<RelatedArtist> albumArtists,
    List<RelatedArtist> artists,
    Map<String, List<RelatedArtist>>? participants,
  })
  _getArtists(Map<String, dynamic> item, {required bool includeRemixers}) {
    List<RelatedArtist>? albumArtists;
    List<RelatedArtist>? artists;
    List<RelatedArtist>? remixers;
    Map<String, List<RelatedArtist>>? participants;

    final rawParticipants = item['participants'];
    if (rawParticipants is Map<String, dynamic>) {
      participants = {};
      for (final entry in rawParticipants.entries) {
        final role = entry.key;
        final list = (entry.value as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();

        if (role == 'albumartist' || role == 'artist' || role == 'remixer') {
          final roleList = list
              .map(
                (artist) => RelatedArtist(
                  id: artist['id'] as String,
                  imageId: null,
                  imageUrl: null,
                  name: _string(artist['name']) ?? '',
                  userFavorite: false,
                  userRating: null,
                ),
              )
              .toList();

          if (role == 'albumartist') {
            albumArtists = roleList;
          } else if (role == 'remixer' && includeRemixers) {
            remixers = roleList;
            participants['remixer'] = roleList;
          } else {
            artists = roleList;
          }
        } else {
          final subRoles = <String?, List<RelatedArtist>>{};

          for (final artist in list) {
            final related = RelatedArtist(
              id: artist['id'] as String,
              imageId: null,
              imageUrl: null,
              name: _string(artist['name']) ?? '',
              userFavorite: false,
              userRating: null,
            );

            subRoles.putIfAbsent(_string(artist['subRole']), () => []).add(
              related,
            );
          }

          for (final subRoleEntry in subRoles.entries) {
            final subRole = subRoleEntry.key;
            if (subRole != null) {
              participants['$role ($subRole)'] = subRoleEntry.value;
            } else {
              participants[role] = subRoleEntry.value;
            }
          }
        }
      }
    }

    albumArtists ??= [
      RelatedArtist(
        id: _string(item['albumArtistId']) ?? '',
        imageId: null,
        imageUrl: null,
        name: _string(item['albumArtist']) ?? '',
        userFavorite: false,
        userRating: null,
      ),
    ];

    artists ??= [
      RelatedArtist(
        id: _string(item['artistId']) ?? '',
        imageId: null,
        imageUrl: null,
        name: _string(item['artist']) ?? '',
        userFavorite: false,
        userRating: null,
      ),
    ];

    if (remixers != null && remixers.isNotEmpty && includeRemixers) {
      final existingIds = artists.map((artist) => artist.id).toSet();
      for (final remixer in remixers) {
        if (!existingIds.contains(remixer.id)) {
          artists.add(remixer);
        }
      }
    }

    return (
      albumArtists: albumArtists,
      artists: artists,
      participants: participants,
    );
  }

  /// Mirrors `parseAlbumTags` — extracts record labels, release types, and
  /// version from the album tag map, and strips those (plus genre) from the
  /// remaining tags.
  static ({
    List<String> recordLabels,
    List<String> releaseTypes,
    Map<String, List<String>>? tags,
    String? version,
  })
  _parseAlbumTags(Map<String, dynamic> item) {
    final tags = _stringListMap(item['tags']);
    if (tags == null) {
      return (
        recordLabels: const [],
        releaseTypes: const [],
        tags: null,
        version: null,
      );
    }

    // We get the genre from elsewhere. We don't need genre twice.
    tags.remove('genre');

    final recordLabels = tags.remove('recordlabel') ?? const <String>[];
    final releaseTypes = tags.remove('releasetype') ?? const <String>[];
    final version = tags.remove('albumversion')?.join(' · ');

    return (
      recordLabels: recordLabels,
      releaseTypes: releaseTypes,
      tags: tags,
      version: version,
    );
  }

  static List<Genre> _genres(dynamic raw, ServerConfig? server) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (g) => Genre(
            albumCount: null,
            id: g['id'] as String,
            imageId: null,
            imageUrl: null,
            name: _string(g['name']) ?? '',
            serverId: server?.id ?? 'unknown',
            serverType: ServerType.navidrome,
            songCount: null,
          ),
        )
        .toList();
  }

  static ExplicitStatus? _explicitStatus(dynamic value) => switch (value) {
    'e' => ExplicitStatus.explicit,
    'c' => ExplicitStatus.clean,
    _ => null,
  };

  // JSON reading helpers. The `_truthy*` variants mirror the TS `x || null`
  // idiom (0 and '' collapse to null).

  static String? _string(dynamic v) => v is String ? v : null;

  static String? _truthyString(dynamic v) =>
      v is String && v.isNotEmpty ? v : null;

  static num? _num(dynamic v) => v is num ? v : null;

  static int? _int(dynamic v) => v is num ? v.toInt() : null;

  static num? _truthyNum(dynamic v) => v is num && v != 0 ? v : null;

  static int? _truthyInt(dynamic v) => v is num && v != 0 ? v.toInt() : null;

  static bool _isTruthy(dynamic v) {
    if (v == null || v == false) return false;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty;
    return true;
  }

  static Map<String, dynamic>? _map(dynamic v) =>
      v is Map<String, dynamic> ? v : null;

  static Map<String, List<String>>? _stringListMap(dynamic v) {
    if (v is! Map<String, dynamic>) {
      return null;
    }

    return v.map(
      (key, value) => MapEntry(
        key,
        value is List ? value.whereType<String>().toList() : <String>[],
      ),
    );
  }

  static int _maxInt(int? a, int? b) {
    final left = a ?? 0;
    final right = b ?? 0;
    return left > right ? left : right;
  }
}
