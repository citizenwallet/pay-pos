import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String posIdKey = "";

  Future<String?> getPosId() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(posIdKey);
  }

  Future<void> setPosId(String id) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(posIdKey, id);
  }

  Future<void> clearPosId() async {

    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(posIdKey);
  }
}
