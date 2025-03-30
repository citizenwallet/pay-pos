import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/credentials.dart';
import 'package:pay_pos/services/pay/pos.dart';
import 'package:pay_pos/services/pay/localstorage.dart';
import 'package:web3dart/crypto.dart';

class OnboardingState with ChangeNotifier {
  String? posId;
  String? placeId;
  bool isActivated = false;
  final LocalStorageService _localStorage = LocalStorageService();
  EthPrivateKey? privateKey;

  Future<String> generatePosId() async {
    final random = Random.secure();
    final randomKey = EthPrivateKey.createRandom(random);
    privateKey = randomKey;

    return randomKey.address.hexEip55;
  }

  Future<bool> checkActivationId(String id) async {
    try {
      final posService = POSService(posId: id);
      final activatedPlaceId = await posService.checkIdActivation(id);
      placeId = activatedPlaceId;
      return activatedPlaceId.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking activation: $e');
      return false;
    }
  }

  Future<void> fetchPosId() async {
    try {
      posId = await generatePosId();
      isActivated = false;
    } catch (e) {
      posId = null;
      isActivated = false;
    }
    notifyListeners();
  }

  Future<void> checkActivation() async {
    final storedPosId = await _localStorage.getPosId();
    if (storedPosId != null) {
      isActivated = await checkActivationId(storedPosId);
      if (isActivated) {
        posId = storedPosId;
        notifyListeners();
        return;
      }
    }

    if (posId == null) return;

    isActivated = await checkActivationId(posId!);
    if (isActivated) {
      await _localStorage.setPosId(posId!);

      final hexString = bytesToHex(privateKey!.privateKey, include0x: false);
      await _localStorage.setPvtKey(hexString);
    }
    notifyListeners();
  }
}
