import 'package:flutter/cupertino.dart';
import 'package:pay_pos/services/pay/pos.dart';

class POSState with ChangeNotifier {
  final POSService posService;
  final String posId;

  bool _mounted = true;

  POSState({
    required this.posId,
  }) : posService = POSService(
          posId: posId,
        );

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
