import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/pay/orders.dart';
import 'package:pay_pos/services/pay/places.dart';

class OrdersState with ChangeNotifier {
  // instantiate services here
  final OrdersService ordersService;

  // private variables here
  bool _mounted = true;

  // constructor here
  OrdersState({
    // required this.slug,
    required this.placeId,
  }) : ordersService = OrdersService(placeId: placeId);

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

  // state variables here
  String placeId;
  PlaceWithMenu? place;
  PlaceMenu? placeMenu;
  List<GlobalKey<State<StatefulWidget>>> categoryKeys = [];
  List<Order> orders = [];
  int total = 0;
  // state methods here
  bool loading = false;
  bool error = false;


  Future<void> fetchOrders() async {
    try {
      debugPrint('fetchOrders');
      final response = await ordersService.getOrders();

      orders = response.orders;

      // total = response.total;
      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    }
  }
}
