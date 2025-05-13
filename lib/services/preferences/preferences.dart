import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _preferences;

  Future init(SharedPreferences pref) async {
    _preferences = pref;
  }

  Future clear() async {
    await _preferences.clear();
  }

  // saved balance
  Future setBalance(String value) async {
    await _preferences.setString('balance', value);
  }

  String? get balance => _preferences.getString('balance');

  static const String posIdKey = "posId";
  static const String privateKey = "privateKey";
  static const String pinCode = "pinCode";
  static const String placeIdKey = "placeId";

  Future<void> setPlaceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(placeIdKey, id);
  }

  Future<String?> getPlaceId() async {
    final prefs = await SharedPreferences.getInstance();
    final placeId = prefs.getString(placeIdKey);

    return placeId;
  }

  Future<void> clearPosId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(posIdKey);
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pinCode, pin);
  }

  Future<String?> getPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(pinCode);

    return pin;
  }

  Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await getPin();
    return savedPin == enteredPin;
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pinCode);
  }

  Future<String?> getPvtKey() async {
    final prefs = await SharedPreferences.getInstance();
    final pvtkey = prefs.getString(privateKey);

    return pvtkey;
  }

  Future<void> setPvtKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(privateKey, key);
  }

  Future<void> clearPvtKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(privateKey);
  }
}
