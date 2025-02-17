import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/pay/orders.dart';
import 'package:pay_pos/services/pay/places.dart';

class OrdersWithPlaceState with ChangeNotifier {
  // instantiate services here
  final PlacesService placesService = PlacesService();
  final OrdersService ordersService;

  // private variables here
  bool _mounted = true;

  // constructor here
  OrdersWithPlaceState({
    required this.slug,
    required this.myAddress,
  }) : ordersService = OrdersService(account: myAddress);

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
  String slug;
  PlaceWithMenu? place;
  PlaceMenu? placeMenu;
  List<GlobalKey<State<StatefulWidget>>> categoryKeys = [];
  String myAddress;
  List<Order> orders = [];
  int total = 0;
  // state methods here
  bool loading = false;
  bool error = false;

  Future<void> fetchPlaceAndMenu() async {
    try {
      loading = true;
      error = false;
      safeNotifyListeners();

      final placeWithMenu = await placesService.getPlaceAndMenu(slug);
      place = placeWithMenu;

      placeMenu = PlaceMenu(menuItems: placeWithMenu.items);
      categoryKeys =
          placeMenu!.categories.map((category) => GlobalKey()).toList();

      await _fetchOrders(placeWithMenu.place.id);

      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    } finally {
      loading = false;
      safeNotifyListeners();
    }
  }

  Future<void> _fetchOrders(int placeId) async {
    try {
      debugPrint('fetchOrders, placeId: ${place?.place.id}');
      final response = await ordersService.getOrders(placeId: place?.place.id);

      orders = response.orders;
      total = response.total;
      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    }
  }
}
