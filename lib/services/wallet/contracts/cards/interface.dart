import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';

abstract class AbstractCardManagerContract {
  Future<void> init();

  EthereumAddress get address;

  Uint8List hashSerial(String serial);

  Future<Uint8List> getCardHash(String serial, {bool local = true});

  Future<EthereumAddress> getCardAddress(Uint8List serialHash);

  Future<Uint8List> createAccountInitCode(Uint8List hash);

  Uint8List createAccountCallData(Uint8List hash);

  Uint8List withdrawCallData(
      Uint8List hash, String token, String to, BigInt amount);
}
