import 'package:flutter/foundation.dart';
import 'package:pay_pos/services/preferences/preferences.dart';

class PinState with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  bool _isLoading = false;
  String? _errorMessage;

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

  bool validatePin(String pin) {
    if (pin.isEmpty) {
      _setError('PIN cannot be empty!');
      return false;
    }
    if (pin.length != 4) {
      _setError('PIN must be 4 digits!');
      return false;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _setError('PIN must contain only numbers!');
      return false;
    }
    return true;
  }

  Future<bool> createPin(String pin, String confirmPin) async {
    if (!validatePin(pin)) return false;
    if (!validatePin(confirmPin)) return false;

    if (pin != confirmPin) {
      _setError('PINs do not match!');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _preferencesService.savePin(pin);
      return true;
    } catch (e) {
      _setError('Failed to save PIN. Please try again!');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (!validatePin(pin)) return false;

    _setLoading(true);
    _setError(null);

    try {
      final isVerified = await _preferencesService.verifyPin(pin);
      if (!isVerified) {
        _setError('Incorrect PIN!');
      }
      return isVerified;
    } catch (e) {
      _setError('Failed to verify PIN. Please try again!');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }

  Future<bool> hasPin() async {
    final pin = await _preferencesService.getPin();
    return pin != null;
  }
} 