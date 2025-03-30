import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String posIdKey = "posId";
  static const String privateKey = "privateKey";
  static const String pinCode = "pinCode";

  Future<String?> getPosId() async {
    final prefs = await SharedPreferences.getInstance();
    final posId = prefs.getString(posIdKey);

    return posId;
  }

  Future<void> setPosId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(posIdKey, id);
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
