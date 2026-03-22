import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../model/order_model.dart';

class OrdersService {
  final Dio _dio = DioClient.instance;

  Future<Order> placeOrder({
    required String dealId,
    int quantity = 1,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.orders,
        data: {
          'deal_id': dealId,
          'quantity': quantity,
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _dio.get(ApiConstants.orders);
      final List data = response.data as List;
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Order> cancelOrder(String orderId) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.orders}/$orderId/cancel',
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    switch (e.response?.statusCode) {
      case 400:
        return 'Cannot process this order. Please check the deal availability.';
      case 403:
        return 'You are not allowed to perform this action.';
      case 404:
        return 'Order not found.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}