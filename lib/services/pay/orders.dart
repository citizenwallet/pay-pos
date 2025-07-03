import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/models/order.dart';
import 'package:pay_pos/models/pos_total.dart';
import 'package:pay_pos/services/api/api.dart';

class OrdersService {
  final APIService apiService =
      APIService(baseURL: dotenv.env['CHECKOUT_API_BASE_URL'] ?? '');

  final String placeId;

  OrdersService({
    required this.placeId,
  });

  Future<({List<Order> orders})> getOrders({
    int? limit,
    int? offset,
    required Map<String, String> headers,
  }) async {
    try {
      final queryParams = {
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

      String url = '/pos/orders/recent?placeId=$placeId';

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await apiService.get(
        url: url,
        headers: headers,
      );

      final List<Order> orders = (response['orders'] as List)
          .map((order) => Order.fromJson(order))
          .toList();

      return (orders: orders);
    } catch (e, s) {
      debugPrint('Failed to fetch orders: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to fetch orders');
    }
  }

  Future<PosTotal> getPosTotal(
    String posId,
    String tokenAddress, {
    Map<String, String>? headers,
  }) async {
    try {
      String url =
          '/pos/orders/total/$posId?placeId=$placeId&token=$tokenAddress';

      final response = await apiService.get(
        url: url,
        headers: headers,
      );

      if (response == null) {
        throw Exception('Received null response from server');
      }

      if (response['error'] != null) {
        throw Exception('Backend error: ${response['error']}');
      }

      return PosTotal.fromJson(response);
    } catch (e, s) {
      debugPrint('Failed to fetch orders: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to fetch orders');
    }
  }

  Future<({int orderId})> createOrder({
    required List<Map<String, dynamic>> items,
    required String description,
    required double total,
    required String posId,
    String? tokenAddress,
    required Map<String, String> headers,
  }) async {
    final int totalInCents = (total * 100).round();
    if (totalInCents <= 0) {
      throw Exception('Total amount must be greater than 0');
    }

    try {
      String url = '/pos/orders';

      final body = {
        'placeId': int.parse(placeId),
        'items': items,
        'description': description.trim(),
        'total': totalInCents,
        'posId': posId,
      };

      if (tokenAddress != null) {
        body['token'] = tokenAddress;
      }

      final response = await apiService.post(
        url: url,
        body: body,
        headers: headers,
      );

      if (response == null) {
        throw Exception('Received null response from server');
      }

      if (response['error'] != null) {
        throw Exception('Backend error: ${response['error']}');
      }

      final dynamic orderIdValue = response['orderId'];
      if (orderIdValue == null) {
        throw Exception('Server response missing orderId');
      }

      final int orderId = orderIdValue is String
          ? int.parse(orderIdValue)
          : orderIdValue as int;

      return (orderId: orderId,);
    } catch (e, s) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  Future<void> createCardOrder({
    required String serial,
    required String orderId,
    required Map<String, String> headers,
  }) async {
    try {
      String url = '/pos/cards/$serial/orders/$orderId/charge';

      final body = {};

      final response = await apiService.patch(
        url: url,
        body: body,
        headers: headers,
      );

      if (response == null) {
        throw Exception('Received null response from server');
      }

      if (response['error'] != null) {
        throw Exception('Backend error: ${response['error']}');
      }

      return;
    } catch (e, s) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  Future<void> deleteOrder({
    required String orderId,
    required Map<String, String> headers,
  }) async {
    try {
      String url = '/pos/orders/$orderId';

      final response = await apiService.delete(
        url: url,
        body: {},
        headers: headers,
      );

      if (response == null) {
        throw Exception('Received null response from server');
      }

      if (response['error'] != null) {
        throw Exception('Backend error: ${response['error']}');
      }
    } catch (e, s) {
      throw Exception('Failed to delete order: ${e.toString()}');
    }
  }

  Future<String> checkOrderStatus({
    required String orderId,
    required Map<String, String> headers,
  }) async {
    try {
      String url = '/pos/orders/$orderId/status';

      final response = await apiService.get(
        url: url,
        headers: headers,
      );

      final responseData = response['status'];
      final status = responseData['status'];

      return status.toString();
    } catch (e, s) {
      debugPrint('Failed to fetch orders: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to fetch orders');
    }
  }

  Future<void> refundOrder({
    required String orderId,
    required Map<String, String> headers,
  }) async {
    try {
      String url = '/pos/orders/$orderId/refund';

      final body = {};

      final response = await apiService.patch(
        url: url,
        body: body,
        headers: headers,
      );

      if (response == null) {
        throw Exception('Received null response from server');
      }

      if (response['error'] != null) {
        throw Exception('Backend error: ${response['error']}');
      }
    } catch (e, s) {
      debugPrint('Failed to refund order: $e');
      debugPrint('Stack trace: $s');
      throw Exception('Failed to refund order: ${e.toString()}');
    }
  }
}
