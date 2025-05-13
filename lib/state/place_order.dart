import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/pay/places.dart';
import 'package:web3dart/web3dart.dart';

class PlaceOrderState with ChangeNotifier {
  final PlacesService placesService = PlacesService();

  bool _mounted = true;
  String? _account;
  String? _slug;

  PlaceOrderState({
    required this.placeId,
  });

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

  Future<EthereumAddress?> fetchPlaceandMenu() async {
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

      safeNotifyListeners();

      loading = false;
      safeNotifyListeners();
      return EthereumAddress.fromHex(_account!);
    } catch (e) {
      error = true;
      loading = false;
      safeNotifyListeners();
    }

    return null;
  }
}
