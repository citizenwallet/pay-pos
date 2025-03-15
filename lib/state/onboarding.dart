import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/credentials.dart';

class OnboardingState with ChangeNotifier {
  String? posId;

  Future<String> generatePosId() async {
    final random = Random.secure();
    final randomKey = EthPrivateKey.createRandom(random);
    return randomKey.address.hexEip55;
  }


  Future<void> fetchPosId() async {
    try {
      posId = await generatePosId();
    } catch (e) {
      posId = null;
    }

    notifyListeners();
  }
}
