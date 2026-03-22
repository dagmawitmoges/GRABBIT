import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../model/order_model.dart';
import '../provider/orders_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(ordersProvider.notifier).fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ordersState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary),
            )
          : ordersState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(ordersState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(ordersProvider.notifier)
                            .fetchOrders(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ordersState.orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 40,
                                color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No orders yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Browse deals and place your first order',
                            style: TextStyle(
                                color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Browse Deals'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () => ref
                          .read(ordersProvider.notifier)
                          .fetchOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ordersState.orders.length,
                        itemBuilder: (context, index) {
                          final order = ordersState.orders[index];
                          return _OrderCard(
                            order: order,
                            onCancel: () async {
                              final confirm =
                                  await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  title:
                                      const Text('Cancel Order'),
                                  content: const Text(
                                      'Are you sure you want to cancel?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, true),
                                      child: const Text('Yes',
                                          style: TextStyle(
                                              color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true &&
                                  context.mounted) {
                                await ref
                                    .read(ordersProvider.notifier)
                                    .cancelOrder(order.id);
                              }
                            },
                            onReview: () => context.push(
                              '/orders/${order.id}/review',
                              extra: order.dealTitle ?? 'Deal',
                            ),
                          );
                        },
                      ),
                    ),
bottomNavigationBar: const BottomNav(currentIndex: 0),    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  const _OrderCard({
    required this.order,
    required this.onCancel,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.dealTitle ?? 'Deal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.status)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _statusColor(order.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (order.claimCode != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    order.claimCode!,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                'Qty: ${order.quantity}',
                style: const TextStyle(
                    color: AppTheme.textMedium, fontSize: 13),
              ),
              if (order.discountedPrice != null) ...[
                const SizedBox(width: 12),
                Text(
                  'ETB ${(order.discountedPrice! * order.quantity).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
              const Spacer(),
              if (order.status == 'Completed')
                TextButton(
                  onPressed: onReview,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Review'),
                ),
              if (order.isCancellable)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Created':
        return AppTheme.primary;
      case 'Cancelled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}