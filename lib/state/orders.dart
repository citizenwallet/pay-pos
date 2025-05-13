import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/pay/orders.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/sigauth.dart';
import 'package:web3dart/web3dart.dart';

class OrdersState with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  final OrdersService ordersService;
  late final SignatureAuthService signatureAuthService;

  bool _mounted = true;
  bool _isPollingEnabled = true;

  OrdersState({required this.placeId})
      : ordersService = OrdersService(placeId: placeId);

  Future<void> _signatureAuth(String account) async {
    try {
      if (signatureAuthService != null) {
        return;
      }
    } catch (e) {}

    final privateKey = await _preferencesService.getPvtKey();
    if (privateKey == null || privateKey.isEmpty) {
      throw Exception("Private key is null or empty");
    }

    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = EthereumAddress.fromHex(account);

    signatureAuthService = SignatureAuthService(
      credentials: credentials,
      address: address,
    );

    safeNotifyListeners();
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
      final response = await ordersService.getOrders();

      orders = response.orders;

      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    }
  }

  Future<void> createOrder({
    required List<Map<String, dynamic>> items,
    required String description,
    required double total,
    required String account,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();

    try {
      await _signatureAuth(account);

      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      final response = await ordersService.createOrder(
        items: items,
        description: description,
        total: total,
        account: account,
        headers: headers,
      );

      orderId = response.orderId;
      loading = false;

      safeNotifyListeners();
    } catch (e) {
      loading = false;
      error = true;
      safeNotifyListeners();
    }
  }

  Future<void> deleteOrder({
    required String orderId,
    required String account,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();
    try {
      await _signatureAuth(account);

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
      final response = await ordersService.checkOrderStatus(orderId: orderId);

      orderStatus = response;

      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    }
  }
}
