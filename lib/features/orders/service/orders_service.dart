import 'dart:math';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../model/order_model.dart';

class OrdersService {
  final Dio _dio = DioClient.instance;

  static Map<String, dynamic> _orderRowToJson(Map<String, dynamic> m) {
    final st = m['status'];
    return {
      'id': '${m['id']}',
      'deal_id': '${m['deal_id']}',
      'deal_title': m['deal_title'] as String?,
      'discounted_price': m['discounted_price'],
      'quantity': m['quantity'],
      'status': st is String ? st : st.toString(),
      'claim_code': (m['order_code'] ?? m['claim_code']) as String?,
      'pickup_at': m['pickup_at']?.toString(),
      'created_at': m['created_at']?.toString() ?? '',
      'total_price': m['total_price'],
      'preferred_method': m['preferred_method']?.toString(),
    };
  }

  static String _randomOrderCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    final suffix =
        List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
    return 'GRB-$suffix';
  }

  /// [preferredMethod] `pickup` or `delivery`. [deliveryFee] ignored when pickup.
  /// [paymentMethod] label stored on `payments`, e.g. Telebirr / Chapa.
  Future<Order> placeOrder({
    required String dealId,
    int quantity = 1,
    String preferredMethod = 'pickup',
    double deliveryFee = 0,
    required String paymentMethod,
  }) async {
    if (Env.hasSupabase) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw 'You must be signed in to place an order.';

      final method = preferredMethod.toLowerCase() == 'delivery'
          ? 'delivery'
          : 'pickup';
      final fee = method == 'delivery' ? deliveryFee : 0.0;

      try {
        final now = DateTime.now().toUtc().toIso8601String();
        final deal = await Supabase.instance.client
            .from('deals')
            .select(
              'id, title, discounted_price, quantity_remaining, '
              'removed_by_admin, expiry_time, is_active',
            )
            .eq('id', dealId)
            .eq('removed_by_admin', false)
            .maybeSingle();

        if (deal == null) {
          throw 'Deal not found.';
        }

        final rem = (deal['quantity_remaining'] as num?)?.toInt() ??
            (deal['quantity_available'] as num?)?.toInt() ??
            0;
        if (rem < quantity) {
          throw 'Not enough quantity available.';
        }
        if (deal['is_active'] != true) {
          throw 'This deal is not active.';
        }
        final exp = deal['expiry_time']?.toString();
        if (exp != null && exp.compareTo(now) <= 0) {
          throw 'This deal has expired.';
        }

        final title = deal['title'] as String? ?? 'Deal';
        final price = deal['discounted_price'];
        final unit = price is num ? price.toDouble() : double.tryParse('$price') ?? 0.0;
        final subtotal = unit * quantity;
        final total = subtotal + fee;

        final code = _randomOrderCode();
        final inserted = await Supabase.instance.client
            .from('orders')
            .insert({
              'user_id': uid,
              'deal_id': dealId,
              'quantity': quantity,
              'deal_title': title,
              'discounted_price': price,
              'claim_code': code,
              'total_price': total,
              'order_code': code,
              'preferred_method': method,
              'status': 'Created',
            })
            .select()
            .single();

        final orderMap = Map<String, dynamic>.from(inserted);
        final orderId = '${orderMap['id']}';

        try {
          await Supabase.instance.client.from('payments').insert({
            'order_id': orderId,
            'payment_method': paymentMethod,
            'amount': total,
            'status': 'success',
            'transaction_reference':
                'SIM-${paymentMethod.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}',
          });
        } catch (_) {
          // Payments RLS/table mismatch — order still created.
        }

        return Order.fromJson(_orderRowToJson(orderMap));
      } on PostgrestException catch (e) {
        throw e.message;
      }
    }

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
    if (Env.hasSupabase) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw 'Not signed in.';

      try {
        final rows = await Supabase.instance.client
            .from('orders')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);

        final list = rows as List<dynamic>;
        return list
            .map((e) => Order.fromJson(
                  _orderRowToJson(Map<String, dynamic>.from(e as Map)),
                ))
            .toList();
      } on PostgrestException catch (e) {
        throw e.message;
      }
    }

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
    if (Env.hasSupabase) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) throw 'Not signed in.';

      try {
        final updated = await Supabase.instance.client
            .from('orders')
            .update({'status': 'Cancelled'})
            .eq('id', orderId)
            .eq('user_id', uid)
            .select()
            .maybeSingle();

        if (updated == null) {
          throw 'Order not found or cannot be cancelled.';
        }
        return Order.fromJson(_orderRowToJson(Map<String, dynamic>.from(updated)));
      } on PostgrestException catch (e) {
        throw e.message;
      }
    }

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
