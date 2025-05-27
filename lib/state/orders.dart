import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/services/config/service.dart';
import 'package:pay_pos/services/nfc/default.dart';
import 'package:pay_pos/services/nfc/service.dart';
import 'package:pay_pos/services/pay/orders.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/secure_storage/secure_storage.dart';
import 'package:pay_pos/services/sigauth.dart';
import 'package:pay_pos/services/wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class OrdersState with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final NFCService _nfcService = DefaultNFCService();
  final OrdersService ordersService;
  late final SignatureAuthService signatureAuthService;

  final ConfigService _configService = ConfigService();
  late Config _config;

  bool _mounted = true;
  bool _isPollingEnabled = true;

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
  int total = 0;
  int orderId = 0;
  String orderStatus = "";

  bool loading = false;
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

  Future<int?> createOrder({
    required List<Map<String, dynamic>> items,
    required String description,
    required double total,
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
      );

      orderId = response.orderId;
      loading = false;

      if (isNfcAvailable) {
        nfcReading = true;
        _nfcService.readSerialNumber().then((serial) async {
          nfcReading = false;
          nfcSerial = serial;
          safeNotifyListeners();

          await ordersService.createCardOrder(
            serial: serial,
            orderId: orderId.toString(),
            headers: headers,
          );

          loading = false;

          safeNotifyListeners();
        });
      }

      safeNotifyListeners();

      return orderId;
    } catch (e, s) {
      loading = false;
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

  Future<void> checkOrderStatus({
    required String orderId,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();
    try {
      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      final response = await ordersService.checkOrderStatus(
        orderId: orderId,
        headers: headers,
      );

      orderStatus = response;

      if (orderStatus == 'paid' && isNfcAvailable) {
        _nfcService.stop();
        nfcReading = false;
        nfcSerial = null;
      }

      safeNotifyListeners();
    } catch (e) {
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
}
