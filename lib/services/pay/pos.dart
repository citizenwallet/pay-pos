import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      final response = await apiService.get(url: '/pos/activated?posId=$posId');

      final Map<String, dynamic> data = response;

      final placeId = data['place_id'].toString();

      return placeId;
    } catch (e, s) {
      debugPrint('Failed to fetch pos id: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to check ID activation');
    }
  }

  Future<void> updatePos(String posId) async {
    try {
      String url = '/pos/updateStatus?posId=$posId';

      final response = await apiService.put(url: url, body: {
        'isActive': false,
      });
    } catch (e, s) {
      debugPrint('Failed to update pos: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to update pos');
    }
  }
}
