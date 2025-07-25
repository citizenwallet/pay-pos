import 'dart:convert';

import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/services/indexer/signed_request.dart';
import 'package:pay_pos/services/session/session.dart';
import 'package:pay_pos/services/wallet/contracts/erc20.dart';
import 'package:pay_pos/services/wallet/contracts/profile.dart';
import 'package:pay_pos/services/wallet/models/json_rpc.dart';
import 'package:pay_pos/services/wallet/models/paymaster_data.dart';
import 'package:pay_pos/services/wallet/models/userop.dart';
import 'package:pay_pos/services/wallet/utils.dart';
import 'package:pay_pos/utils/delay.dart';
import 'package:pay_pos/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// given a tx hash, waits for the tx to be mined
Future<bool> waitForTxSuccess(
  Config config,
  String txHash, {
  int retryCount = 0,
  int maxRetries = 20,
}) async {
  if (retryCount >= maxRetries) {
    return false;
  }

  final ethClient = config.ethClient;

  final receipt = await ethClient.getTransactionReceipt(txHash);
  if (receipt?.status != true) {
    // there is either no receipt or the tx is still not confirmed

    // increment the retry count
    final nextRetryCount = retryCount + 1;

    // wait for a bit before retrying
    await delay(Duration(milliseconds: 250 * (nextRetryCount)));

    // retry
    return waitForTxSuccess(
      config,
      txHash,
      retryCount: nextRetryCount,
      maxRetries: maxRetries,
    );
  }

  return true;
}

/// construct transfer call data
Uint8List tokenTransferCallData(
  Config config,
  EthereumAddress from,
  String to,
  BigInt amount, {
  BigInt? tokenId,
}) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.transferCallData(to, amount);
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract
        .transferCallData(from.hexEip55, to, tokenId ?? BigInt.zero, amount);
  }

  return Uint8List.fromList([]);
}

String transferEventStringSignature(Config config) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.transferEventStringSignature;
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract.transferEventStringSignature;
  }

  return '';
}

String transferEventSignature(Config config) {
  if (config.getPrimaryToken().standard == 'erc20') {
    return config.token20Contract.transferEventSignature;
  } else if (config.getPrimaryToken().standard == 'erc1155') {
    return config.token1155Contract.transferEventSignature;
  }

  return '';
}

/// retrieves the current balance of the address
Future<String> getBalance(
  Config config,
  EthereumAddress addr, {
  String? tokenAddress,
  int? chainId,
  BigInt? tokenId,
}) async {
  try {
    final tokenStandard = tokenAddress != null
        ? config.getToken(tokenAddress, chainId: chainId).standard
        : config.getPrimaryToken().standard;

    BigInt balance = BigInt.zero;
    switch (tokenStandard) {
      case 'erc20':
        final tokenContract = tokenAddress != null
            ? await config.getTokenContract(tokenAddress, chainId: chainId)
            : config.token20Contract;

        balance = await tokenContract.getBalance(addr.hexEip55).timeout(
              const Duration(seconds: 4),
            );

        break;
      case 'erc1155':
        final tokenContract = tokenAddress != null
            ? await config.getToken1155Contract(tokenAddress, chainId: chainId)
            : config.token1155Contract;

        balance = await tokenContract
            .getBalance(addr.hexEip55, tokenId ?? BigInt.zero)
            .timeout(
              const Duration(seconds: 4),
            );
        break;
    }

    return balance.toString();
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return '0';
}

/// get profile data
Future<ProfileV1?> getProfile(Config config, String addr) async {
  try {
    final url = await config.profileContract.getURL(addr);

    final profileData = await config.ipfsService.get(url: '/$url');

    final profile = ProfileV1.fromJson(profileData);

    profile.parseIPFSImageURLs(config.ipfs.url);

    return profile;
  } catch (exception) {
    //
  }

  return null;
}

/// get profile data by username
Future<ProfileV1?> getProfileByUsername(Config config, String username) async {
  try {
    final url = await config.profileContract.getURLFromUsername(username);

    final profileData = await config.ipfsService.get(url: '/$url');

    final profile = ProfileV1.fromJson(profileData);

    profile.parseIPFSImageURLs(config.ipfs.url);

    return profile;
  } catch (exception) {
    //
  }

  return null;
}

/// profileExists checks whether there is a profile for this username
Future<bool> profileExists(Config config, String username) async {
  try {
    final url = await config.profileContract.getURLFromUsername(username);

    return url != '';
  } catch (exception) {
    //
  }

  return false;
}

/// get profile data
Future<ProfileV1?> getProfileFromUrl(Config config, String url) async {
  try {
    final profileData = await config.ipfsService.get(url: '/$url');

    final profile = ProfileV1.fromJson(profileData);

    profile.parseIPFSImageURLs(config.ipfs.url);

    return profile;
  } catch (exception) {
    //
  }

  return null;
}

/// set profile data
Future<String?> setProfile(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  ProfileRequest profile, {
  required List<int> image,
  required String fileType,
}) async {
  try {
    final url =
        '/v1/profiles/${config.profileContract.addr}/${account.hexEip55}';

    final json = jsonEncode(
      profile.toJson(),
    );

    final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    final resp = await config.engineIPFSService.filePut(
      url: url,
      file: image,
      fileType: fileType,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    final String profileUrl = resp['object']['ipfs_url'];

    final calldata = config.profileContract
        .setCallData(account.hexEip55, profile.username, profileUrl);

    final (_, userop) = await prepareUserop(
      config,
      account,
      credentials,
      [config.profileContract.addr],
      [calldata],
    );

    final txHash = await submitUserop(config, userop);
    if (txHash == null) {
      throw Exception('profile update failed');
    }

    final success = await waitForTxSuccess(config, txHash);
    if (!success) {
      throw Exception('transaction failed');
    }

    return profileUrl;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return null;
}

/// update profile data
Future<String?> updateProfile(Config config, EthereumAddress account,
    EthPrivateKey credentials, ProfileV1 profile) async {
  try {
    final url =
        '/v1/profiles/${config.profileContract.addr}/${account.hexEip55}';

    final json = jsonEncode(
      profile.toJson(),
    );

    final body = SignedRequest(convertBytesToUint8List(utf8.encode(json)));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    final resp = await config.engineIPFSService.patch(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    final String profileUrl = resp['object']['ipfs_url'];

    final calldata = config.profileContract
        .setCallData(account.hexEip55, profile.username, profileUrl);

    final (_, userop) = await prepareUserop(
      config,
      account,
      credentials,
      [config.profileContract.addr],
      [calldata],
    );

    final txHash = await submitUserop(config, userop);
    if (txHash == null) {
      throw Exception('profile update failed');
    }

    final success = await waitForTxSuccess(config, txHash);
    if (!success) {
      throw Exception('transaction failed');
    }

    return profileUrl;
  } catch (_) {}

  return null;
}

/// set profile data
Future<bool> deleteCurrentProfile(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
) async {
  try {
    final url =
        '/v1/profiles/${config.profileContract.addr}/${account.hexEip55}';

    final encoded = jsonEncode(
      {
        'account': account.hexEip55,
        'date': DateTime.now().toUtc().toIso8601String(),
      },
    );

    final body = SignedRequest(convertStringToUint8List(encoded));

    final sig = await compute(
        generateSignature, (jsonEncode(body.toJson()), credentials));

    await config.engineIPFSService.delete(
      url: url,
      headers: {
        'X-Signature': sig,
        'X-Address': account.hexEip55,
      },
      body: body.toJson(),
    );

    return true;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// check if an account exists
Future<bool> accountExists(
  Config config,
  EthereumAddress account,
) async {
  try {
    final url = '/v1/accounts/${account.hexEip55}/exists';

    await config.engine.get(
      url: url,
    );

    return true;
  } catch (_) {}

  return false;
}

/// create an account
Future<bool> createAccount(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
) async {
  try {
    final exists = await accountExists(config, account);
    if (exists) {
      return true;
    }

    final simpleAccount = await config.getSimpleAccount(account.hexEip55);

    Uint8List calldata = simpleAccount.transferOwnershipCallData(
      credentials.address.hexEip55,
    );
    if (config.getPaymasterType() == 'cw-safe') {
      calldata = config.communityModuleContract.getChainIdCallData();
    }

    final (_, userop) = await prepareUserop(
      config,
      account,
      credentials,
      [account.hexEip55],
      [calldata],
    );

    final txHash = await submitUserop(
      config,
      userop,
    );
    if (txHash == null) {
      throw Exception('failed to submit user op');
    }

    final success = await waitForTxSuccess(config, txHash);
    if (!success) {
      throw Exception('transaction failed');
    }

    return true;
  } catch (e, s) {
    debugPrint('error: $e');
    debugPrint('stack trace: $s');
  }

  return false;
}

/// makes a jsonrpc request from this wallet
Future<SUJSONRPCResponse> requestPaymaster(
  Config config,
  SUJSONRPCRequest body, {
  bool legacy = false,
}) async {
  final rawResponse = await config.engineRPC.post(
    body: body,
  );

  final response = SUJSONRPCResponse.fromJson(rawResponse);

  if (response.error != null) {
    throw Exception(response.error!.message);
  }

  return response;
}

/// return paymaster data for constructing a user op
Future<(PaymasterData?, Exception?)> getPaymasterData(
  Config config,
  UserOp userop,
  String eaddr,
  String ptype, {
  bool legacy = false,
}) async {
  final body = SUJSONRPCRequest(
    method: 'pm_sponsorUserOperation',
    params: [
      userop.toJson(),
      eaddr,
      {'type': ptype},
    ],
  );

  try {
    final response = await requestPaymaster(config, body, legacy: legacy);

    return (PaymasterData.fromJson(response.result), null);
  } catch (exception) {
    final strerr = exception.toString();

    if (strerr.contains(gasFeeErrorMessage)) {
      return (null, NetworkCongestedException());
    }

    if (strerr.contains(invalidBalanceErrorMessage)) {
      return (null, NetworkInvalidBalanceException());
    }
  }

  return (null, NetworkUnknownException());
}

/// return paymaster data for constructing a user op
Future<(List<PaymasterData>, Exception?)> getPaymasterOOData(
  Config config,
  UserOp userop,
  String eaddr,
  String ptype, {
  bool legacy = false,
  int count = 1,
}) async {
  final body = SUJSONRPCRequest(
    method: 'pm_ooSponsorUserOperation',
    params: [
      userop.toJson(),
      eaddr,
      {'type': ptype},
      count,
    ],
  );

  try {
    final response = await requestPaymaster(config, body, legacy: legacy);

    final List<dynamic> data = response.result;
    if (data.isEmpty) {
      throw Exception('empty paymaster data');
    }

    if (data.length != count) {
      throw Exception('invalid paymaster data');
    }

    return (data.map((item) => PaymasterData.fromJson(item)).toList(), null);
  } catch (exception) {
    final strerr = exception.toString();

    if (strerr.contains(gasFeeErrorMessage)) {
      return (<PaymasterData>[], NetworkCongestedException());
    }

    if (strerr.contains(invalidBalanceErrorMessage)) {
      return (<PaymasterData>[], NetworkInvalidBalanceException());
    }
  }

  return (<PaymasterData>[], NetworkUnknownException());
}

/// prepare a userop for with calldata
Future<(String, UserOp)> prepareUserop(
  Config config,
  EthereumAddress account,
  EthPrivateKey credentials,
  List<String> dest,
  List<Uint8List> calldata, {
  BigInt? customNonce,
  bool deploy = true,
}) async {
  try {
    // instantiate user op with default values
    final userop = UserOp.defaultUserOp();

    // use the account hex as the sender
    userop.sender = account.hexEip55;

    // determine the appropriate nonce
    BigInt nonce = customNonce ?? await config.getNonce(account.hexEip55);

    final paymasterType = config.getPaymasterType();

    // if it's the first user op from this account, we need to deploy the account contract
    if (nonce == BigInt.zero && deploy) {
      bool exists = false;
      if (paymasterType == 'payg') {
        // solves edge case with legacy account migration
        exists = await accountExists(config, account);
      }

      if (!exists) {
        final accountFactory = config.accountFactoryContract;

        // construct the init code to deploy the account
        userop.initCode = await accountFactory.createAccountInitCode(
          credentials.address.hexEip55,
          BigInt.zero,
        );
      } else {
        // try again in case the account was created in the meantime
        nonce = customNonce ??
            await config.entryPointContract.getNonce(account.hexEip55);
      }
    }

    userop.nonce = nonce;

    // set the appropriate call data for the transfer
    // we need to call account.execute which will call token.transfer
    switch (paymasterType) {
      case 'payg':
      case 'cw':
        {
          final simpleAccount = await config.getSimpleAccount(account.hexEip55);

          userop.callData = dest.length > 1 && calldata.length > 1
              ? simpleAccount.executeBatchCallData(
                  dest,
                  calldata,
                )
              : simpleAccount.executeCallData(
                  dest[0],
                  BigInt.zero,
                  calldata[0],
                );
          break;
        }
      case 'cw-safe':
        {
          final safeAccount = await config.getSafeAccount(account.hexEip55);
          userop.callData = safeAccount.executeCallData(
            dest[0],
            BigInt.zero,
            calldata[0],
          );
          break;
        }
    }

    // submit the user op to the paymaster in order to receive information to complete the user op
    List<PaymasterData> paymasterOOData = [];
    Exception? paymasterErr;
    final useAccountNonce =
        (nonce == BigInt.zero || paymasterType == 'payg') && deploy;

    if (useAccountNonce) {
      // if it's the first user op, we should use a normal paymaster signature
      PaymasterData? paymasterData;
      (paymasterData, paymasterErr) = await getPaymasterData(
        config,
        userop,
        config.entryPointContract.addr,
        paymasterType,
      );

      if (paymasterData != null) {
        paymasterOOData.add(paymasterData);
      }
    } else {
      // if it's not the first user op, we should use an out of order paymaster signature
      (paymasterOOData, paymasterErr) = await getPaymasterOOData(
        config,
        userop,
        config.entryPointContract.addr,
        paymasterType,
      );
    }

    if (paymasterErr != null) {
      throw paymasterErr;
    }

    if (paymasterOOData.isEmpty) {
      throw Exception('unable to get paymaster data');
    }

    final paymasterData = paymasterOOData.first;
    if (!useAccountNonce) {
      // use the nonce received from the paymaster
      userop.nonce = paymasterData.nonce;
    }

    // add the received data to the user op
    userop.paymasterAndData = paymasterData.paymasterAndData;
    userop.preVerificationGas = paymasterData.preVerificationGas;
    userop.verificationGasLimit = paymasterData.verificationGasLimit;
    userop.callGasLimit = paymasterData.callGasLimit;

    // get the hash of the user op
    final hash = await config.entryPointContract.getUserOpHash(userop);

    // now we can sign the user op
    userop.generateSignature(credentials, hash);

    return (bytesToHex(hash, include0x: true), userop);
  } catch (_) {
    rethrow;
  }
}

/// submit a user op
Future<String?> submitUserop(
  Config config,
  UserOp userop, {
  Map<String, dynamic>? data,
  TransferData? extraData,
}) async {
  final entryPoint = config.entryPointContract;

  final params = [userop.toJson(), entryPoint.addr];
  if (data != null) {
    params.add(data);
  }
  if (data != null && extraData != null) {
    params.add(extraData.toJson());
  }

  final body = SUJSONRPCRequest(
    method: 'eth_sendUserOperation',
    params: params,
  );

  try {
    final response = await requestBundler(config, body);

    return response.result as String;
  } catch (exception, s) {
    debugPrint('error: $exception');
    debugPrint('stack trace: $s');

    final strerr = exception.toString();

    if (strerr.contains(gasFeeErrorMessage)) {
      throw NetworkCongestedException();
    }

    if (strerr.contains(invalidBalanceErrorMessage)) {
      throw NetworkInvalidBalanceException();
    }
  }

  throw NetworkUnknownException();
}

/// makes a jsonrpc request from this wallet
Future<SUJSONRPCResponse> requestBundler(
    Config config, SUJSONRPCRequest body) async {
  final rawResponse = await config.engineRPC.post(
    body: body,
  );

  debugPrint('rawResponse: ${rawResponse.toString()}');

  final response = SUJSONRPCResponse.fromJson(rawResponse);

  if (response.error != null) {
    debugPrint('error: ${response.error!.message}');
    throw Exception(response.error!.message);
  }

  return response;
}

Future<EthereumAddress> getTwoFAAddress(
  Config config,
  String source,
  String type,
) async {
  final provider = EthereumAddress.fromHex(
      config.getPrimarySessionManager().providerAddress);
  final salt = generateSessionSalt(source, type);
  return await config.twoFAFactoryContract.getAddress(provider, salt);
}

Future<Uint8List> getSerialHash(Config config, String serial,
    {bool local = true}) async {
  if (config.cardManagerContract == null) {
    throw Exception('Card manager not initialized');
  }

  return config.cardManagerContract!.hashSerial(serial);
}

Future<EthereumAddress> getCardAddress(Config config, Uint8List hash) async {
  if (config.cardManagerContract == null) {
    throw Exception('Card manager not initialized');
  }
  return config.cardManagerContract!.getCardAddress(hash);
}
