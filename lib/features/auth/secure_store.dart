import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin abstraction over the platform keychain so the auth layer can be
/// tested with an in-memory fake.
abstract interface class SecureStore {
  Future<void> delete(String key);
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// iOS Keychain-backed store (Android Keystore when Android lands).
class KeychainSecureStore implements SecureStore {
  const KeychainSecureStore._(this._storage);

  factory KeychainSecureStore() => const KeychainSecureStore._(
    FlutterSecureStorage(
      // Credentials must be readable while the app streams in background
      // with the device locked.
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}
