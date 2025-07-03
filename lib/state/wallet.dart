import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/services/config/service.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class WalletState with ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final PreferencesService _preferencesService = PreferencesService();

  late Config _config;

  String _balance = '0';
  int _decimals = 6;
  double get doubleBalance =>
      double.tryParse(_preferencesService.balance ?? _balance) ?? 0.0;
  double get balance => doubleBalance / pow(10, _decimals);

  bool loading = false;
  bool error = false;

  List<TokenConfig> tokens = [];
  Map<String, TokenConfig> tokenConfigs = {};
  TokenConfig? primaryToken;
  TokenConfig? selectedToken;

  WalletState() {
    init();
  }

  Timer? _pollingTimer;
  bool _mounted = true;
  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> init() async {
    try {
      final config = await _configService.getLocalConfig();
      if (config == null) {
        throw Exception('Community not found in local asset');
      }

      await config.initContracts();

      _config = config;
      _decimals = config.getPrimaryToken().decimals;
      tokens = config.tokens.values.toList();
      tokenConfigs =
          config.tokens.values.fold<Map<String, TokenConfig>>({}, (map, token) {
        map[token.address] = token;
        return map;
      });

      primaryToken = config.getPrimaryToken();

      final tokenAddress = await _preferencesService.getTokenAddress();
      if (tokenAddress != null) {
        selectedToken =
            tokens.firstWhere((token) => token.address == tokenAddress);
      } else {
        selectedToken = tokens.first;
      }
    } catch (e, s) {
      debugPrint('error: $e');
      debugPrint('stack trace: $s');
    }
  }

  Future<void> startBalancePolling(EthereumAddress address) async {
    stopBalancePolling();

    _pollingTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) {
        updateBalance(address);
      },
    );
  }

  Future<void> stopBalancePolling() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> updateBalance(EthereumAddress address) async {
    _balance = await getBalance(_config, address);
    await _preferencesService.setBalance(_balance);
    safeNotifyListeners();
  }

  Future<void> setSelectedToken(TokenConfig token) async {
    selectedToken = token;
    await _preferencesService.setTokenAddress(token.address);
    safeNotifyListeners();
  }
}
