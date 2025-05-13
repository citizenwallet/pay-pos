import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/user.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/services/config/service.dart';
import 'package:pay_pos/services/pay/profile.dart';
import 'package:pay_pos/services/photos/photos.dart';
import 'package:pay_pos/services/wallet/contracts/profile.dart';

class ProfileState with ChangeNotifier {
  final PhotosService _photosService = PhotosService();
  late ProfileService myProfileService;
  User? userProfile;

  final ConfigService _configService = ConfigService();
  late Config _config;

  bool _pauseProfileCreation = false;
  final String account;

  ProfileState({
    required this.account,
  }) {
    myProfileService = ProfileService(account: account);
  }

  Future<void> init() async {
    final config = await _configService.getLocalConfig();
    if (config == null) {
      throw Exception('Community not found in local asset');
    }

    await config.initContracts();

    _config = config;
  }

  bool _mounted = true;
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
  ProfileV1 profile = ProfileV1();

  Future<void> loadProfile() async {
    loading = true;
    error = false;
    safeNotifyListeners();

    try {
      final profile = await myProfileService.getProfile();
      debugPrint('profile: $profile');
      userProfile = profile;

      safeNotifyListeners();
    } catch (e, s) {
      debugPrint('Error getting profile of with user: $e');
      debugPrint('Stack trace: $s');
      error = true;
      safeNotifyListeners();
    } finally {
      loading = false;
      safeNotifyListeners();
    }
  }

  void pause() {
    _pauseProfileCreation = true;
  }

  void resume() {
    _pauseProfileCreation = false;
  }
}
