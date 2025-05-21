import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pay_pos/utils/delay.dart';
import 'package:web3dart/credentials.dart';
import 'package:pay_pos/services/pay/pos.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/secure_storage/secure_storage.dart';
import 'package:web3dart/crypto.dart';

class OnboardingState with ChangeNotifier {
  String? posId;
  bool loading = false;

  final PreferencesService _preferencesService = PreferencesService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final POSService _posService = POSService();
  EthPrivateKey? _privateKey;

  Future<String> generatePosId() async {
    final random = Random.secure();
    final randomKey = EthPrivateKey.createRandom(random);
    _privateKey = randomKey;

    return randomKey.address.hexEip55;
  }

  Future<String?> getPosId() async {
    final storedPvtKey = await _secureStorageService.getPrivateKey();
    
    if (storedPvtKey == null) return null;

    _privateKey = EthPrivateKey.fromHex(storedPvtKey);
    return _privateKey?.address.hexEip55;
  }

  Future<String?> checkActivationId(String id) async {
    try {
      final activatedPlaceId = await _posService.checkIdActivation(id);

      await _preferencesService.setPlaceId(activatedPlaceId);

      return activatedPlaceId;
    } catch (e) {
      debugPrint('Error checking activation: $e');
      return null;
    }
  }

  Future<String?> loadPosId() async {
    try {
      loading = true;
      notifyListeners();

      final storedPosId = await getPosId();
      final storedPlaceId = await _preferencesService.getPlaceId();
      if (storedPosId != null && storedPlaceId != null) {
        return storedPlaceId;
      }

      posId = await generatePosId();
      loading = false;
    } catch (e) {
      posId = null;

      await delay(const Duration(seconds: 1));
      return loadPosId();
    }

    notifyListeners();

    return null;
  }

  Future<String?> checkActivation() async {
    final storedPosId = await getPosId();
    final storedPlaceId = await _preferencesService.getPlaceId();
    if (storedPosId != null && storedPlaceId != null) {
      return storedPlaceId;
    }

    if (posId != null && storedPlaceId != null) {
      return storedPlaceId;
    }

    final unactivatedPosId = _privateKey?.address.hexEip55;
    if (unactivatedPosId == null) return null;

    try {
      final activatedPlaceId =
          await _posService.checkIdActivation(unactivatedPosId);

      await _preferencesService.setPlaceId(activatedPlaceId);
      await _secureStorageService.setPrivateKey(
        bytesToHex(_privateKey!.privateKey, include0x: false)
      );

      return activatedPlaceId;
    } catch (e) {
      debugPrint('Error checking activation: $e');
      return null;
    }
  }
}
