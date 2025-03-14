import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/models/user.dart';
import 'package:pay_pos/services/api/api.dart';

class ProfileService {
  final APIService apiService =
      APIService(baseURL: dotenv.env['CHECKOUT_API_BASE_URL'] ?? '');
  final String account;

  ProfileService({required this.account});

  Future<User> getProfile() async {
    try {
      final response = await apiService.get(url: '/accounts/$account/profile');

      final Map<String, dynamic> data = response;

      /* Example API Response:
       * {
       *   "profile": {
       *     "account": "0x5566D6D4Df27a6fD7856b7564F81266863Ba3ee8",
       *     "username": "kevin", 
       *     "name": "Kevin",
       *     "description": "👋👋👋",
       *     "image": "https://ipfs.internal.citizenwallet.xyz/QmU5EC55tBoAZCF2Ebp58HnzbqAuGYEzDcnGLbAUZVW35H",
       *     "place_id": null
       *   }
       * }
       */

      return User.fromJson(data['profile']);
    } catch (e, s) {
      debugPrint('Failed to fetch profile: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to fetch profile');
    }
  }
}
