import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/order_model.dart';
import '../service/orders_service.dart';

final ordersServiceProvider =
    Provider<OrdersService>((ref) => OrdersService());

// Orders state
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final bool isPlacing;
  final String? successMessage;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.isPlacing = false,
    this.successMessage,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool? isPlacing,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isPlacing: isPlacing ?? this.isPlacing,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrdersService _service;

  OrdersNotifier(this._service) : super(const OrdersState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _service.getOrders();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Order?> placeOrder({
    required String dealId,
    int quantity = 1,
    String preferredMethod = 'pickup',
    double deliveryFee = 0,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isPlacing: true, clearError: true);
    try {
      final order = await _service.placeOrder(
        dealId: dealId,
        quantity: quantity,
        preferredMethod: preferredMethod,
        deliveryFee: deliveryFee,
        paymentMethod: paymentMethod,
      );
      state = state.copyWith(
        isPlacing: false,
        orders: [order, ...state.orders],
        successMessage: 'Order placed successfully!',
      );
      return order;
    } catch (e) {
      state = state.copyWith(isPlacing: false, error: e.toString());
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    state = state.copyWith(clearError: true);
    try {
      final updated = await _service.cancelOrder(orderId);
      final updatedList = state.orders.map((o) {
        return o.id == orderId ? updated : o;
      }).toList();
      state = state.copyWith(orders: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, OrdersState>(
  (ref) => OrdersNotifier(ref.watch(ordersServiceProvider)),
);