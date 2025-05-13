import 'package:flutter/cupertino.dart';
import 'package:pay_pos/services/pay/pos.dart';

class POSState with ChangeNotifier {
  final POSService posService = POSService();

  bool _mounted = true;

  POSState();

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

  bool loading = false;
  bool error = false;

  Future<void> updatePOS({
    required String posId,
  }) async {
    loading = true;
    error = false;
    safeNotifyListeners();
    try {
      final response = await posService.updatePos(posId);

      safeNotifyListeners();
    } catch (e) {
      error = true;
      safeNotifyListeners();
    }
  }
}
