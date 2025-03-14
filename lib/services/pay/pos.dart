import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/models/user.dart';
import 'package:pay_pos/services/api/api.dart';

class POSService {
  final APIService apiService =
      APIService(baseURL: dotenv.env['DASHBOARD_API_BASE_URL'] ?? '');
  final String posId;

  POSService({
    required this.posId,
  });

  Future<String> checkIdActivation(String id) async {
    try {
      final response = await apiService.get(url: '/pos/activated?posId=13');

      final Map<String, dynamic> data = response;

      final placeId = data['place_id'];
      print(placeId);
      return placeId;
    } catch (e, s) {
      debugPrint('Failed to fetch pos id: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to check ID activation');
    }
  }
}
