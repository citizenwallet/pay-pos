import 'dart:convert';
import 'dart:typed_data';
import 'package:pay_pos/utils/uint8.dart';
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
    final params = [
      'sigAuthAccount=${address.hexEip55}',
      'sigAuthExpiry=${expiry.toIso8601String()}',
      'sigAuthSignature=$signature',
    ];
    if (redirect != null) {
      params.add('sigAuthRedirect=${Uri.encodeComponent(redirect!)}');
    }
    return params.join('&');
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

// class SignatureAuthService {
//   final EthPrivateKey _credentials;
//   final EthereumAddress _address;
//   final String _redirect;
//   final Duration _validityDuration;

//   SignatureAuthService({
//     required EthPrivateKey credentials,
//     required EthereumAddress address,
//     String redirect = '',
//     Duration validityDuration = const Duration(days: 7),
//   })  : _credentials = credentials,
//         _address = credentials.address,
//         _redirect = redirect,
//         _validityDuration = validityDuration;

//   SignatureAuthConnection connect({DateTime? expiry}) {
//     print("connect");
//     final expiryDate = expiry ?? DateTime.now().add(_validityDuration);
//     print(expiryDate);
//     final message =
//         'Signature auth for ${_address.hexEip55} with expiry ${expiryDate.toIso8601String()} and redirect ${Uri.encodeComponent(_redirect)}';
//     print(message);
//     // Create the Ethereum personal sign message format
//     final prefix = '\x19Ethereum Signed Message:\n';
//     final messageLength = message.length.toString();
//     final prefixedMessage = prefix + messageLength + message;
//     print(prefixedMessage);
//     // Convert to bytes and sign
//     final messageBytes = Uint8List.fromList(utf8.encode(prefixedMessage));
//     print(messageBytes);
//     final signatureBytes =
//         _credentials.signPersonalMessageToUint8List(messageBytes);
//     print(signatureBytes);
//     final signatureHex = bytesToHex(signatureBytes, include0x: true);

//     return SignatureAuthConnection(
//       address: _address,
//       expiry: expiryDate,
//       signature: signatureHex,
//       redirect: _redirect.isNotEmpty ? _redirect : null,
//     );
//   }
// }

// class SignatureAuthService {
//   final EthPrivateKey _credentials;
//   final EthereumAddress _address;
//   final String _redirect;
//   final Duration _validityDuration;

//   SignatureAuthService({
//     required EthPrivateKey credentials,
//     required EthereumAddress address,
//     String redirect = '',
//     Duration validityDuration = const Duration(days: 7),
//   })  : _credentials = credentials,
//         _address = credentials.address,
//         _redirect = redirect,
//         _validityDuration = validityDuration;

//   SignatureAuthConnection connect({DateTime? expiry}) {
//     final expiryDate = expiry ?? DateTime.now().add(_validityDuration);

//     final message =
//         'Signature auth for ${_address.hexEip55} with expiry ${expiryDate.toIso8601String()} and redirect ${Uri.encodeComponent(_redirect)}';

//     // Hash the message using keccak256
//     final messageHash = keccak256(utf8.encode(message));

//     // Sign the hash
//     final signatureBytes = _credentials.signPersonalMessage(
//       Uint8List.fromList(messageHash),
//     );

//     // Convert the signature to hex format
//     final signatureHex = bytesToHex(signatureBytes as List<int>, include0x: true);

//     return SignatureAuthConnection(
//       address: _address,
//       expiry: expiryDate,
//       signature: signatureHex,
//       redirect: _redirect,
//     );
//   }
// }

class SignatureAuthService {
  final EthPrivateKey _credentials;
  final EthereumAddress _address;
  final String _redirect;
  final Duration _validityDuration;

  SignatureAuthService({
    required EthPrivateKey credentials,
    required EthereumAddress address,
    String redirect = '',
    Duration validityDuration = const Duration(days: 7),
  })  : _credentials = credentials,
        _address = credentials.address,
        _redirect = redirect,
        _validityDuration = validityDuration;

  SignatureAuthConnection connect({DateTime? expiry}) {
    final expiryDate = expiry ?? DateTime.now().add(_validityDuration);

    final message =
        'Signature auth for ${_address.hexEip55} with expiry ${expiryDate.toIso8601String()}${_redirect.isNotEmpty ? ' and redirect ${Uri.encodeComponent(_redirect)}' : ''}';
    print(message);

    final prefix = '\u0019Ethereum Signed Message:\n${message.length}';
    final prefixedMessage = utf8.encode(prefix + message);

    final messageHash = keccak256(
      Uint8List.fromList(prefixedMessage),
    );

    final signatureBytes = _credentials.signPersonalMessageToUint8List(
      messageHash,
    );

    final signatureHex = bytesToHex(signatureBytes, include0x: true);

    print(signatureHex);

    return SignatureAuthConnection(
      address: _address,
      expiry: expiryDate,
      signature: signatureHex,
      redirect: _redirect.isNotEmpty ? _redirect : null,
    );
  }
}
