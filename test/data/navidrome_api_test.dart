import 'package:feishin_mobile/data/navidrome/navidrome_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_http_adapter.dart';

NavidromeApi buildApi(
  FakeHttpAdapter adapter, {
  String? Function()? tokenProvider,
  NdTokenRefreshed? onTokenRefreshed,
  NdReauthenticate? reauthenticate,
}) {
  final dio = NavidromeApi.defaultDio()..httpClientAdapter = adapter;
  return NavidromeApi(
    serverUrl: 'https://music.example.com',
    tokenProvider: tokenProvider ?? () => 'tok-1',
    onTokenRefreshed: onTokenRefreshed,
    reauthenticate: reauthenticate,
    dio: dio,
  );
}

void main() {
  test('list request: auth header, repeated params, x-total-count', () async {
    final adapter = FakeHttpAdapter(
      (options) => jsonResponse(
        [
          {'id': 'al-1'},
        ],
        headers: {
          'x-total-count': ['42'],
        },
      ),
    );
    final api = buildApi(adapter);

    final page = await api.getAlbumList({
      '_end': 10,
      '_order': 'ASC',
      '_sort': 'name',
      '_start': 0,
      'genre_id': ['g-1', 'g-2'],
      'name': null,
    });

    final request = adapter.requests.single;
    expect(request.uri.path, '/api/album');
    expect(request.headers['x-nd-authorization'], 'Bearer tok-1');
    expect(request.uri.queryParametersAll['genre_id'], ['g-1', 'g-2']);
    expect(request.uri.queryParametersAll['_start'], ['0']);
    // Nulls are omitted entirely, mirroring the axios `omitBy` behavior.
    expect(request.uri.queryParameters.containsKey('name'), isFalse);

    expect(page.items.single['id'], 'al-1');
    expect(page.totalCount, 42);
  });

  test('captures rotated token from the response header', () async {
    String? rotated;
    final adapter = FakeHttpAdapter(
      (options) => jsonResponse(
        {'id': 's-1'},
        headers: {
          'x-nd-authorization': ['tok-2'],
        },
      ),
    );
    final api = buildApi(adapter, onTokenRefreshed: (token) => rotated = token);

    await api.getSongDetail('s-1');

    expect(rotated, 'tok-2');
  });

  test('401 triggers a single re-auth shared by concurrent requests',
      () async {
    var token = 'expired';
    var reauthCalls = 0;

    final adapter = FakeHttpAdapter((options) {
      if (options.headers['x-nd-authorization'] == 'Bearer expired') {
        return jsonResponse('Unauthorized', status: 401);
      }
      return jsonResponse([], headers: {
        'x-total-count': ['0'],
      });
    });

    final api = buildApi(
      adapter,
      tokenProvider: () => token,
      reauthenticate: () async {
        reauthCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        token = 'fresh';
        return token;
      },
    );

    final results = await Future.wait([
      api.getAlbumList({'_start': 0}),
      api.getSongList({'_start': 0}),
    ]);

    expect(results, hasLength(2));
    expect(reauthCalls, 1);
    // 2 failed + 2 retried requests.
    expect(adapter.requests, hasLength(4));
    expect(
      adapter.requests.last.headers['x-nd-authorization'],
      'Bearer fresh',
    );
  });

  test('401 without possible re-auth surfaces the original error', () async {
    final adapter = FakeHttpAdapter(
      (options) => jsonResponse('Unauthorized', status: 401),
    );
    final api = buildApi(adapter, reauthenticate: () async => null);

    await expectLater(
      api.getAlbumList({'_start': 0}),
      throwsA(
        isA<NavidromeApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('authenticate builds the subsonic credential', () async {
    final adapter = FakeHttpAdapter((options) {
      expect(options.method, 'POST');
      expect(options.uri.toString(), 'https://music.example.com/auth/login');
      expect(options.data, {'password': 'pw', 'username': 'demo'});
      return jsonResponse({
        'id': 'u-1',
        'isAdmin': true,
        'name': 'Demo',
        'subsonicSalt': 'abc123',
        'subsonicToken': 'def456',
        'token': 'nd-token',
        'username': 'demo',
      });
    });
    final dio = NavidromeApi.defaultDio()..httpClientAdapter = adapter;

    final result = await NavidromeApi.authenticate(
      url: 'https://music.example.com/',
      username: 'demo',
      password: 'pw',
      dio: dio,
    );

    expect(result.ndToken, 'nd-token');
    expect(result.subsonicCredential, 'u=demo&s=abc123&t=def456');
    expect(result.userId, 'u-1');
    expect(result.isAdmin, isTrue);
  });

  test('ping extracts the server version', () async {
    final adapter = FakeHttpAdapter(
      (options) => jsonResponse({
        'subsonic-response': {
          'serverVersion': '0.55.0 (fc8f494f)',
          'status': 'ok',
          'type': 'navidrome',
          'version': '1.16.1',
        },
      }),
    );
    final dio = NavidromeApi.defaultDio()..httpClientAdapter = adapter;

    final version = await NavidromeApi.ping(
      url: 'https://music.example.com',
      subsonicCredential: 'u=demo&s=abc&t=def',
      dio: dio,
    );

    expect(version, '0.55.0 (fc8f494f)');
    expect(
      adapter.requests.single.uri.queryParameters['u'],
      'demo',
    );
  });

  test('server errors map to NavidromeApiException with the body message',
      () async {
    final adapter = FakeHttpAdapter(
      (options) => jsonResponse({'error': 'boom'}, status: 500),
    );
    final api = buildApi(adapter);

    await expectLater(
      api.getAlbumDetail('al-1'),
      throwsA(
        isA<NavidromeApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'boom'),
      ),
    );
  });
}
