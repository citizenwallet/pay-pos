import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/pay/orders.dart';
import 'package:pay_pos/services/pay/places.dart';

class PlaceOrderState with ChangeNotifier {
  // instantiate services here
  final PlacesService placesService = PlacesService();

  // private variables here
  bool _mounted = true;
  String? _account;
  String? _slug;

  // constructor here
  PlaceOrderState({
    required this.placeId,
  });

  // getters
  String get account => _account ?? '';
  String get slug => _slug ?? '';

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

  Future<void> fetchPlaceandMenu() async {
    try {
      loading = true;
      error = false;
      safeNotifyListeners();

      final placeWithMenu = await placesService.getPlaceandMenu(placeId);
      place = placeWithMenu;
      _account = placeWithMenu.place.account;
      _slug = placeWithMenu.place.slug;

      placeMenu = PlaceMenu(menuItems: placeWithMenu.items);
      categoryKeys =
          placeMenu!.categories.map((category) => GlobalKey()).toList();

      // await ordersService.getOrders();

      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    } finally {
      loading = false;
      safeNotifyListeners();
    }
  }
}
