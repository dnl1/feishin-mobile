/// Dio client for the Navidrome native REST API (`{server}/api/...`),
/// ported from feishin/src/renderer/api/navidrome/navidrome-api.ts.
///
/// Also carries the two Subsonic-compat calls the Navidrome controller needs
/// outside of URL builders: `ping` (server version) — the rest of the
/// Subsonic surface arrives with later phases (favorites, scrobble, lyrics).
library;

import 'package:dio/dio.dart';

/// Result of `POST /auth/login`, mirroring the `authenticate` response +
/// the credential strings the original controller derives from it.
class NdAuthResult {
  const NdAuthResult({
    required this.isAdmin,
    required this.ndToken,
    required this.subsonicCredential,
    required this.userId,
    required this.username,
  });

  final bool isAdmin;

  /// Bearer token for the native API (`x-nd-authorization`).
  final String ndToken;

  /// `u=<user>&s=<salt>&t=<token>` query fragment for `/rest/*` endpoints.
  final String subsonicCredential;
  final String userId;
  final String username;
}

/// One page of a Navidrome list endpoint: raw JSON items plus the
/// `x-total-count` header.
class NdPage {
  const NdPage({required this.items, required this.totalCount});

  final List<Map<String, dynamic>> items;
  final int totalCount;
}

class NavidromeApiException implements Exception {
  const NavidromeApiException({this.statusCode, required this.message});

  final String message;
  final int? statusCode;

  bool get isNetworkError => statusCode == null;

  @override
  String toString() =>
      'NavidromeApiException(${statusCode ?? 'network'}): $message';
}

/// Called when the server rotates the bearer token via the
/// `x-nd-authorization` response header.
typedef NdTokenRefreshed = void Function(String token);

/// Called on 401. Should re-authenticate (e.g. with a stored password) and
/// return the new bearer token, or null when re-auth is not possible — in
/// which case the original 401 is surfaced.
typedef NdReauthenticate = Future<String?> Function();

class NavidromeApi {
  NavidromeApi({
    required this.serverUrl,
    required this._tokenProvider,
    this.onTokenRefreshed,
    this.reauthenticate,
    Dio? dio,
  }) : _dio = dio ?? defaultDio();

  /// Server base URL without trailing slash (native API lives at `/api`).
  final String serverUrl;

  final Dio _dio;
  Future<String?>? _pendingReauth;
  final String? Function() _tokenProvider;

  final NdTokenRefreshed? onTokenRefreshed;
  final NdReauthenticate? reauthenticate;

  static Dio defaultDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      listFormat: ListFormat.multi,
    ),
  );

  /// `POST {url}/auth/login` — mirrors `NavidromeController.authenticate`.
  static Future<NdAuthResult> authenticate({
    required String url,
    required String username,
    required String password,
    Dio? dio,
  }) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    final Response<dynamic> res;
    try {
      res = await (dio ?? defaultDio()).post<dynamic>(
        '$cleanUrl/auth/login',
        data: {'password': password, 'username': username},
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const NavidromeApiException(message: 'Unexpected login response');
    }

    return NdAuthResult(
      isAdmin: data['isAdmin'] == true,
      ndToken: data['token'] as String,
      subsonicCredential:
          'u=${Uri.encodeQueryComponent(data['username'] as String? ?? username)}'
          '&s=${data['subsonicSalt']}&t=${data['subsonicToken']}',
      userId: data['id'] as String,
      username: data['username'] as String? ?? username,
    );
  }

  /// `GET {url}/rest/ping.view` — returns the server version string.
  /// Mirrors the `ssApiClient(...).ping()` half of
  /// `NavidromeController.getServerInfo`.
  static Future<String> ping({
    required String url,
    required String subsonicCredential,
    Dio? dio,
  }) async {
    final Response<dynamic> res;
    try {
      res = await (dio ?? defaultDio()).get<dynamic>(
        '$url/rest/ping.view?$subsonicCredential&v=1.13.0&c=Feishin&f=json',
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }

    final body = res.data;
    final subsonicResponse = body is Map<String, dynamic>
        ? body['subsonic-response']
        : null;
    final version = subsonicResponse is Map<String, dynamic>
        ? subsonicResponse['serverVersion']
        : null;

    if (version is! String) {
      throw const NavidromeApiException(message: 'Unexpected ping response');
    }

    return version;
  }

  // --- Album ---

  Future<NdPage> getAlbumList(Map<String, dynamic> query) =>
      _getList('album', query);

  Future<Map<String, dynamic>> getAlbumDetail(String id) => _getOne('album/$id');

  // --- Album artist ---

  Future<NdPage> getAlbumArtistList(Map<String, dynamic> query) =>
      _getList('artist', query);

  Future<Map<String, dynamic>> getAlbumArtistDetail(String id) =>
      _getOne('artist/$id');

  // --- Song ---

  Future<NdPage> getSongList(Map<String, dynamic> query) =>
      _getList('song', query);

  Future<Map<String, dynamic>> getSongDetail(String id) => _getOne('song/$id');

  // --- Genre / tag ---

  Future<NdPage> getGenreList(Map<String, dynamic> query) =>
      _getList('genre', query);

  Future<NdPage> getTagList(Map<String, dynamic> query) =>
      _getList('tag', query);

  // --- Playlist ---

  Future<NdPage> getPlaylistList(Map<String, dynamic> query) =>
      _getList('playlist', query);

  Future<Map<String, dynamic>> getPlaylistDetail(String id) =>
      _getOne('playlist/$id');

  Future<NdPage> getPlaylistSongList(String id, Map<String, dynamic> query) =>
      _getList('playlist/$id/tracks', query);

  /// Returns the created playlist id.
  Future<String> createPlaylist(Map<String, dynamic> body) async {
    final res = await _request<dynamic>('playlist', 'POST', data: body);
    return (res.data as Map<String, dynamic>)['id'] as String;
  }

  Future<void> updatePlaylist(String id, Map<String, dynamic> body) =>
      _request<dynamic>('playlist/$id', 'PUT', data: body);

  Future<void> deletePlaylist(String id) =>
      _request<dynamic>('playlist/$id', 'DELETE');

  Future<void> addToPlaylist(String id, List<String> songIds) => _request<
    dynamic
  >('playlist/$id/tracks', 'POST', data: {'ids': songIds});

  Future<void> removeFromPlaylist(String id, List<String> songIds) =>
      _request<dynamic>(
        'playlist/$id/tracks',
        'DELETE',
        query: {'id': songIds},
      );

  Future<void> movePlaylistItem({
    required String playlistId,
    required String trackNumber,
    required String insertBefore,
  }) => _request<dynamic>(
    'playlist/$playlistId/tracks/$trackNumber',
    'PUT',
    data: {'insert_before': insertBefore},
  );

  // --- Internet radio ---

  Future<NdPage> getRadioList(Map<String, dynamic> query) =>
      _getList('radio', query);

  Future<void> createRadioStation(Map<String, dynamic> body) =>
      _request<dynamic>('radio', 'POST', data: body);

  Future<void> updateRadioStation(String id, Map<String, dynamic> body) =>
      _request<dynamic>('radio/$id', 'PUT', data: body);

  Future<void> deleteRadioStation(String id) =>
      _request<dynamic>('radio/$id', 'DELETE');

  // --- User ---

  Future<NdPage> getUserList(Map<String, dynamic> query) =>
      _getList('user', query);

  // --- Play queue ---

  Future<Map<String, dynamic>> getQueue() => _getOne('queue');

  Future<void> saveQueue({
    List<String>? ids,
    int? current,
    int? position,
  }) => _request<dynamic>(
    'queue',
    'POST',
    data: {'ids': ?ids, 'current': ?current, 'position': ?position},
  );

  // --- Sharing ---

  /// Returns the created share id.
  Future<String> shareItem(Map<String, dynamic> body) async {
    final res = await _request<dynamic>('share', 'POST', data: body);
    return (res.data as Map<String, dynamic>)['id'] as String;
  }

  // --- Internals ---

  Future<NdPage> _getList(String path, Map<String, dynamic> query) async {
    final res = await _request<dynamic>(path, 'GET', query: query);
    final data = res.data;

    return NdPage(
      items: data is List
          ? data.whereType<Map<String, dynamic>>().toList()
          : const [],
      totalCount: int.tryParse(res.headers.value('x-total-count') ?? '') ?? 0,
    );
  }

  Future<Map<String, dynamic>> _getOne(String path) async {
    final res = await _request<dynamic>(path, 'GET');
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw NavidromeApiException(message: 'Unexpected response for $path');
    }
    return data;
  }

  Future<Response<T>> _request<T>(
    String path,
    String method, {
    Object? data,
    Map<String, dynamic>? query,
    bool isRetry = false,
  }) async {
    final token = _tokenProvider();

    try {
      final res = await _dio.request<T>(
        '$serverUrl/api/$path',
        data: data,
        queryParameters: query == null ? null : _omitNulls(query),
        options: Options(
          method: method,
          headers: {if (token != null) 'x-nd-authorization': 'Bearer $token'},
        ),
      );
      _captureRotatedToken(res);
      return res;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && !isRetry && reauthenticate != null) {
        final newToken = await _reauthOnce();
        if (newToken != null) {
          return _request<T>(
            path,
            method,
            data: data,
            query: query,
            isRetry: true,
          );
        }
      }

      throw _toApiException(e);
    }
  }

  /// Serializes concurrent 401s into a single re-authentication, mirroring
  /// the `shouldDelay`/`waitForResult` dance in the original interceptor.
  Future<String?> _reauthOnce() {
    final pending = _pendingReauth;
    if (pending != null) {
      return pending;
    }

    final future = reauthenticate!().whenComplete(() => _pendingReauth = null);
    _pendingReauth = future;
    return future;
  }

  void _captureRotatedToken(Response<dynamic> res) {
    final rotated = res.headers.value('x-nd-authorization');
    if (rotated != null && rotated.isNotEmpty) {
      onTokenRefreshed?.call(rotated);
    }
  }

  static Map<String, dynamic> _omitNulls(Map<String, dynamic> query) =>
      Map.fromEntries(query.entries.where((e) => e.value != null));

  static NavidromeApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String message = e.message ?? 'Request failed';
    if (data is Map<String, dynamic> && data['error'] is String) {
      message = data['error'] as String;
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    return NavidromeApiException(statusCode: status, message: message);
  }
}
