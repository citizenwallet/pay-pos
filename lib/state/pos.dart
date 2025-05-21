import 'package:flutter/cupertino.dart';
import 'package:pay_pos/services/pay/pos.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/secure_storage/secure_storage.dart';

class POSState with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final POSService posService = POSService();

  bool _mounted = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  POSState();

  void _setLoading(bool loading) {
    if (_mounted) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_mounted) {
      _errorMessage = error;
      notifyListeners();
    }
  }

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

  Future<void> updatePOS({
    required String posId,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await posService.updatePos(posId);

      await _preferencesService.clearPosId();
      await _preferencesService.clearPin();
      await _preferencesService.clearPlaceId();
      await _secureStorageService.deletePrivateKey();

      safeNotifyListeners();
    } catch (e) {
      _setError('Failed to update POS. Please try again!');
    } finally {
      _setLoading(false);
    }
  }
}
