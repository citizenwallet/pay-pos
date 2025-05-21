import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IOSSecureStorage {
  static final IOSSecureStorage _instance = IOSSecureStorage._internal();
  factory IOSSecureStorage() => _instance;

  late final FlutterSecureStorage _storage;
  static const String _privateKeyKey = 'private_key';

  IOSSecureStorage._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
        synchronizable: false,
      ),
    );
  }

  Future<void> setPrivateKey(String privateKey) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: _privateKeyKey);
  }

  Future<void> deletePrivateKey() async {
    await _storage.delete(key: _privateKeyKey);
  }
} 