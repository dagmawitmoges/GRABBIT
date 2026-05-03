import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../model/order_model.dart';
import '../model/review_route_args.dart';
import '../provider/orders_provider.dart';
import '../../reviews/provider/reviews_provider.dart';
import '../../../features/deals/provider/deals_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

Color _orderStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'created':
      return AppTheme.primary;
    case 'confirmed':
      return Colors.teal;
    case 'cancelled':
    case 'canceled':
      return Colors.red;
    case 'completed':
      return Colors.blue;
    default:
      return Colors.orange;
  }
}

String _formatOrderTimestamp(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

Future<void> _onOrderCardTap(
    BuildContext context, WidgetRef ref, Order order) async {
  if (order.status.toLowerCase() == 'completed') {
    final hasReview =
        await ref.read(reviewsServiceProvider).hasReviewForOrder(order.id);
    if (!context.mounted) return;
    if (hasReview) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thanks!'),
          content: const Text(
            'You already left a review for this order.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showOrderDetailDialog(context, order);
              },
              child: const Text('View order'),
            ),
          ],
        ),
      );
      return;
    }
    if (!context.mounted) return;
    context.push(
      '/orders/${order.id}/review',
      extra: ReviewRouteArgs(
        orderId: order.id,
        dealId: order.dealId,
        dealTitle: order.dealTitle ?? 'Deal',
        order: order,
      ),
    );
    return;
  }
  _showOrderDetailDialog(context, order);
}

void _showOrderDetailDialog(BuildContext context, Order order) {
  final sub = order.lineSubtotal;
  final method = order.preferredMethod;
  final fulfillment = method == null
      ? '—'
      : method.toLowerCase() == 'delivery'
          ? 'Delivery'
          : 'Pickup';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Order details',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: AppTheme.textDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _OrderDetailRow(label: 'Deal', value: order.dealTitle ?? '—'),
            _OrderDetailRow(
              label: 'Status',
              value: order.status,
              valueColor: _orderStatusColor(order.status),
            ),
            if (order.claimCode != null)
              _OrderDetailRow(label: 'Order code', value: order.claimCode!),
            _OrderDetailRow(label: 'Quantity', value: '${order.quantity}'),
            if (order.discountedPrice != null)
              _OrderDetailRow(
                label: 'Unit price',
                value: 'ETB ${order.discountedPrice!.toStringAsFixed(0)}',
              ),
            if (sub != null)
              _OrderDetailRow(
                label: 'Items subtotal',
                value: 'ETB ${sub.toStringAsFixed(0)}',
              ),
            if (order.totalPrice != null)
              _OrderDetailRow(
                label: 'Total paid',
                value: 'ETB ${order.totalPrice!.toStringAsFixed(0)}',
                emphasize: true,
              ),
            _OrderDetailRow(label: 'Fulfillment', value: fulfillment),
            if (order.pickupAt != null && order.pickupAt!.isNotEmpty)
              _OrderDetailRow(
                label: 'Pickup / ready time',
                value: _formatOrderTimestamp(order.pickupAt!),
              ),
            _OrderDetailRow(
              label: 'Placed on',
              value: _formatOrderTimestamp(order.createdAt),
            ),
            _OrderDetailRow(
              label: 'Order ID',
              value: order.id,
              small: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).fetchOrders());
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
                            onOpenDetail: () =>
                                _onOrderCardTap(context, ref, order),
                            onCancel: () async {
                              final confirm = await showDialog<bool>(
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
                                          Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Yes',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true &&
                                  context.mounted) {
                                final ok = await ref
                                    .read(ordersProvider.notifier)
                                    .cancelOrder(order.id);
                                if (ok && context.mounted) {
                                  ref
                                      .read(dealsProvider.notifier)
                                      .refresh();
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;
  final bool small;

  const _OrderDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textMedium,
                fontSize: small ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppTheme.textDark,
                fontSize: small ? 11 : (emphasize ? 16 : 14),
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onOpenDetail;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.onOpenDetail,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetail,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        color: _orderStatusColor(order.status)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          color: _orderStatusColor(order.status),
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
                if (order.status.toLowerCase() == 'completed') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap the card to rate your experience',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
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
          ),
        ),
      ),
    );
  }
}
