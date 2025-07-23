import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/models/pos_total.dart';
import 'package:pay_pos/services/audio/audio.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/services/config/service.dart';
import 'package:pay_pos/services/nfc/default.dart';
import 'package:pay_pos/services/nfc/service.dart';
import 'package:pay_pos/services/pay/orders.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/secure_storage/secure_storage.dart';
import 'package:pay_pos/services/sigauth.dart';
import 'package:pay_pos/services/wallet/wallet.dart';
import 'package:pay_pos/utils/currency.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';

class InsufficientBalanceException implements Exception {
  final String message = 'insufficient balance';

  InsufficientBalanceException();
}

class OrdersState with ChangeNotifier {
  final AudioService _audioService = AudioService();
  final PreferencesService _preferencesService = PreferencesService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final NFCService _nfcService = DefaultNFCService();
  final OrdersService ordersService;
  late final SignatureAuthService signatureAuthService;

  final ConfigService _configService = ConfigService();
  late Config _config;

  bool _mounted = true;
  bool _isPollingEnabled = true;
  Timer? _pollingTimer;

  OrdersState({required this.placeId})
      : ordersService = OrdersService(placeId: placeId) {
    init();
  }

  void init() async {
    final privateKey = await _secureStorageService.getPrivateKey();
    if (privateKey == null || privateKey.isEmpty) {
      throw Exception("Private key is null or empty");
    }

    final credentials = EthPrivateKey.fromHex(privateKey);

    signatureAuthService = SignatureAuthService(
      credentials: credentials,
      address: credentials.address,
    );

    isNfcAvailable = await _nfcService.isAvailable();
    print('isNfcAvailable: $isNfcAvailable');
    safeNotifyListeners();

    final config = await _configService.getLocalConfig();
    if (config == null) {
      print('Community not found in local asset');
      throw Exception('Community not found in local asset');
    }

    await config.initContracts();

    _config = config;
  }

  bool get isPollingEnabled => _isPollingEnabled;
  set isPollingEnabled(bool value) {
    _isPollingEnabled = value;
    safeNotifyListeners();
  }

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

  bool isNfcAvailable = false;
  bool nfcReading = false;
  String? nfcSerial;

  String placeId;
  PlaceWithMenu? place;
  PlaceMenu? placeMenu;
  List<GlobalKey<State<StatefulWidget>>> categoryKeys = [];
  List<Order> orders = [];
  PosTotal posTotal = PosTotal.zero();
  int? orderId;
  String orderStatus = "";

  bool loading = true;
  bool error = false;

  Future<void> fetchOrders() async {
    if (!_isPollingEnabled) return;

    try {
      final connection = signatureAuthService.connect();
      final headers = connection.headers;
      final response = await ordersService.getOrders(headers: headers);

      orders = response.orders;

      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    }
  }

  Future<void> fetchPosTotal(String tokenAddress) async {
    final connection = signatureAuthService.connect();
    final headers = connection.headers;
    final response = await ordersService.getPosTotal(
      signatureAuthService.address.hexEip55,
      tokenAddress,
      headers: headers,
    );
    posTotal = response;

    safeNotifyListeners();
  }

  Future<void> startPosTotalPolling(String tokenAddress) async {
    stopPosTotalPolling();

    _pollingTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) {
        fetchPosTotal(tokenAddress);
      },
    );
  }

  Future<void> stopPosTotalPolling() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> openPayClient(String placeId, double total) async {
    final scheme = dotenv.env['VIVA_PAY_CLIENT_SCHEME'];

    final appBundleId = dotenv.env['APP_BUNDLE_ID'];

    final action = 'sale';

    final appScheme = dotenv.env['APP_SCHEME'];

    final int totalInCents = (total * 100).round();
    if (totalInCents <= 0) {
      throw Exception('Total amount must be greater than 0');
    }

    final request =
        '$scheme?appId=$appBundleId&action=$action&amount=$totalInCents&callback=${appScheme}payclient/$placeId';

    return launchUrl(Uri.parse(request), mode: LaunchMode.externalApplication);
  }

  Future<int?> createOrder({
    required List<Map<String, dynamic>> items,
    required String description,
    required double total,
    String? tokenAddress,
    Function(Exception)? onError,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();

    try {
      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      final pk = await _secureStorageService.getPrivateKey();
      if (pk == null || pk.isEmpty) {
        throw Exception("Private key is null or empty");
      }
      final address = EthPrivateKey.fromHex(pk).address;

      final response = await ordersService.createOrder(
        items: items,
        description: description,
        total: total,
        posId: address.hexEip55,
        headers: headers,
        tokenAddress: tokenAddress,
      );

      orderId = response.orderId;

      if (isNfcAvailable) {
        nfcReading = true;
        _nfcService.readSerialNumber().then((serial) async {
          nfcReading = false;
          nfcSerial = serial;
          safeNotifyListeners();

          final hashedSerial = await getSerialHash(_config, serial);

          final cardAddress = await getCardAddress(_config, hashedSerial);

          final cardBalance = await getBalance(_config, cardAddress,
              tokenAddress: tokenAddress);

          final token = _config.getToken(tokenAddress);

          final adjustedBalance = formatCurrency(cardBalance, token.decimals);

          final doubleBalance = double.tryParse(adjustedBalance) ?? 0.0;

          if (doubleBalance < total) {
            loading = false;
            orderStatus = 'insufficient_balance';
            safeNotifyListeners();

            onError?.call(InsufficientBalanceException());
            deleteOrder(orderId: orderId.toString());
            return;
          }

          loading = false;

          await ordersService.createCardOrder(
            serial: serial,
            orderId: orderId.toString(),
            headers: headers,
          );

          safeNotifyListeners();
        });
      }

      safeNotifyListeners();

      return orderId;
    } catch (e, s) {
      loading = true;
      orderStatus = 'pending';
      error = true;
      safeNotifyListeners();

      return null;
    }
  }

  Future<void> deleteOrder({
    required String orderId,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();
    try {
      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      await ordersService.deleteOrder(
        orderId: orderId,
        headers: headers,
      );

      loading = false;

      safeNotifyListeners();
    } catch (e) {
      loading = false;
      error = true;
      safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> checkOrderStatus({required Function() onSuccess}) async {
    try {
      if (orderId == null) {
        return;
      }

      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      final response = await ordersService.checkOrderStatus(
        orderId: orderId.toString(),
        headers: headers,
      );

      orderStatus = response;

      if (orderStatus == 'paid' && isNfcAvailable) {
        _nfcService.stop();
        nfcReading = false;
        nfcSerial = null;
      }

      if (orderStatus == 'paid') {
        _audioService.txNotification();
        onSuccess();
        loading = false;
        safeNotifyListeners();
        return;
      }

      safeNotifyListeners();
    } catch (e, s) {
      print(e);
      print(s);
      error = true;
      safeNotifyListeners();
    }
  }

  Future<void> refundOrder({
    required String orderId,
    required String account,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();

    try {
      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      final response = await ordersService.refundOrder(
        orderId: orderId,
        headers: headers,
      );

      loading = false;
      safeNotifyListeners();
    } catch (e, s) {
      loading = false;
      error = true;
      safeNotifyListeners();
    }
  }

  void clearOrder() {
    orderId = null;
    orderStatus = '';
    loading = false;
    error = false;
    safeNotifyListeners();
  }
}
