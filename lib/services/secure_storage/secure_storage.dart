import 'package:flutter/foundation.dart';
import 'android.dart';
import 'ios.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  late final dynamic _storage;

  SecureStorageService._internal() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _storage = IOSSecureStorage();
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _storage = AndroidSecureStorage();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  Future<void> setPrivateKey(String privateKey) async {
    await _storage.setPrivateKey(privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.getPrivateKey();
  }

  Future<void> deletePrivateKey() async {
    await _storage.deletePrivateKey();
  }
} 