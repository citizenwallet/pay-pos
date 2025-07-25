import 'dart:convert';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SignatureAuthConnection {
  final EthereumAddress address;
  final DateTime expiry;
  final String signature;
  final String? redirect;

  SignatureAuthConnection({
    required this.address,
    required this.expiry,
    required this.signature,
    this.redirect,
  });

  bool get isValid => expiry.isAfter(DateTime.now());

  String get queryParams {
    String params =
        'sigAuthAccount=${address.hexEip55}&sigAuthExpiry=${expiry.toIso8601String()}&sigAuthSignature=$signature';

    if (redirect != null) {
      params += '&sigAuthRedirect=${Uri.encodeComponent(redirect!)}';
    }

    return params;
  }

  Map<String, String> get headers => {
        'x-sigauth-account': address.hexEip55,
        'x-sigauth-expiry': expiry.toIso8601String(),
        'x-sigauth-signature': signature,
        if (redirect != null) 'x-sigauth-redirect': redirect!,
      };

  @override
  String toString() =>
      'SignatureAuthConnection(address: ${address.hexEip55}, expiry: $expiry, signature: $signature, redirect: $redirect)';
}

class SignatureAuthService {
  final EthPrivateKey _credentials;
  final EthereumAddress _address;
  final String? _redirect;

  SignatureAuthService({
    required EthPrivateKey credentials,
    required EthereumAddress address,
    String? redirect,
  })  : _credentials = credentials,
        _address = address,
        _redirect = redirect;

  EthereumAddress get address => _address;

  SignatureAuthConnection connect({DateTime? expiry}) {
    final expiryDate = expiry ?? DateTime.now().add(const Duration(days: 7));

    String message =
        'Signature auth for ${_address.hexEip55} with expiry ${expiryDate.toIso8601String()}';

    if (_redirect != null) {
      message += ' and redirect ${Uri.encodeComponent(_redirect)}';
    }

    final signature = bytesToHex(
      _credentials.signPersonalMessageToUint8List(
        keccak256(utf8.encode(message)),
      ),
      include0x: true,
    );

    return SignatureAuthConnection(
      address: _address,
      expiry: expiryDate,
      signature: signature,
      redirect: _redirect,
    );
  }
}
