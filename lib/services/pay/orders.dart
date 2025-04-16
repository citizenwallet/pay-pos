import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/models/order.dart';
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
  }) async {
    try {
      final queryParams = {
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      };

      String url = '/places/$placeId/orders/recent';

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await apiService.get(
        url: url,
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

  Future<({int orderId})> createOrder({
    required List<Map<String, dynamic>> items,
    required String description,
    required double total,
    required String account,
    required Map<String, String> headers,
  }) async {
    print("2.1");
    print(headers);
    final int totalInCents = (total * 100).round();
    if (totalInCents <= 0) {
      throw Exception('Total amount must be greater than 0');
    }
    print("2.2");
    try {
      String url = '/places/$placeId/createOrder';
      print("2.3");
      final body = {
        'placeId': int.parse(placeId),
        'items': items,
        'description': description.trim(),
        'total': totalInCents,
        'account': account,
        'type': "pos",
      };
      print("2.4");
      final response = await apiService.post(
        url: url,
        body: body,
        headers: headers,
      );
      print(response);
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

  Future<void> deleteOrder({
    required String orderId,
    required Map<String, String> headers,
  }) async {
    try {
      String url = '/places/$placeId/deleteOrder?orderId=$orderId';

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
  }) async {
    try {
      String url = '/places/$placeId/orders/paidOrderById?orderId=$orderId';

      final response = await apiService.get(
        url: url,
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
}
