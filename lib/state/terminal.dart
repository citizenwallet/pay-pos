import 'package:flutter/foundation.dart';
import 'package:pay_pos/services/preferences/preferences.dart';
import 'package:pay_pos/services/secure_storage/secure_storage.dart';
import 'package:pay_pos/state/pos.dart';
import 'package:web3dart/credentials.dart';

class TerminalState with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final POSState _posState;
  bool _isLoading = false;
  String? _errorMessage;

  TerminalState(this._posState);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> deactivateTerminal() async {
    _setLoading(true);
    _setError(null);

    try {
      final pk = await _secureStorageService.getPrivateKey();
      if (pk != null) {
        final posId = EthPrivateKey.fromHex(pk).address.hexEip55;
        await _posState.updatePOS(posId: posId);
      }

      await _preferencesService.clearPosId();
      await _preferencesService.clearPin();
      await _secureStorageService.deletePrivateKey();
      await _preferencesService.clearPlaceId();

      return true;
    } catch (e) {
      _setError('Failed to deactivate terminal. Please try again!');
      return false;
    } finally {
      _setLoading(false);
    }
  }
} 