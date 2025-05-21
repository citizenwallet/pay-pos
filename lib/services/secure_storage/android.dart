import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AndroidSecureStorage {
  static final AndroidSecureStorage _instance = AndroidSecureStorage._internal();
  factory AndroidSecureStorage() => _instance;

  late final FlutterSecureStorage _storage;
  static const String _privateKeyKey = 'private_key';

  AndroidSecureStorage._internal() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
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