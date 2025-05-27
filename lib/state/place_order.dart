import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/place_menu.dart';
import 'package:pay_pos/models/place_with_menu.dart';
import 'package:pay_pos/services/pay/places.dart';
import 'package:pay_pos/services/secure_storage/secure_storage.dart';
import 'package:pay_pos/services/sigauth.dart';
import 'package:pay_pos/utils/delay.dart';
import 'package:web3dart/web3dart.dart';

class PlaceOrderState with ChangeNotifier {
  final PlacesService placesService = PlacesService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  late final SignatureAuthService signatureAuthService;

  bool _mounted = true;
  String? _account;
  String? _slug;

  PlaceOrderState({
    required this.placeId,
  }) {
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
  }

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

      final connection = signatureAuthService.connect();
      final headers = connection.headers;

      final placeWithMenu =
          await placesService.getPlaceandMenu(placeId, headers);
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

      await delay(const Duration(seconds: 1));
      return fetchPlaceandMenu();
    }
  }
}
