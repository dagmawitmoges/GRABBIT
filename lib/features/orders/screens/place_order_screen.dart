import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/checkout_constants.dart';
import '../../../features/deals/model/deal_model.dart';
import '../../../features/deals/provider/deals_provider.dart';
import '../../../features/notifications/provider/notifications_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../model/order_model.dart';
import '../provider/orders_provider.dart';

class PlaceOrderScreen extends ConsumerStatefulWidget {
  final Deal deal;
  const PlaceOrderScreen({super.key, required this.deal});

  @override
  ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
  int _quantity = 1;
  bool _delivery = false;
  bool _checkoutBusy = false;
  bool _didInvalidateDealForFreshStock = false;

  double _deliveryFeeLine() => _delivery ? kDeliveryFeeEtb : 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidateDealForFreshStock) return;
    _didInvalidateDealForFreshStock = true;
    // Avoid stale `quantity_remaining` from a cached detail fetch.
    ref.invalidate(dealDetailProvider(widget.deal.id));
  }

  void _clampQuantityToStock(int available) {
    if (available < 1) return;
    if (_quantity > available) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _quantity = available);
      });
    }
  }

  Future<void> _openPaymentSheet(double grandTotal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pay with',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose Telebirr or Chapa. This step simulates a successful payment; '
                  'wire real Telebirr/Chapa SDKs or checkout URLs when ready.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total to pay',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                  ),
                ),
                Text(
                  'ETB ${grandTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _PaymentOptionTile(
                  label: 'Telebirr',
                  subtitle: 'Pay with Telebirr wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF0052CC),
                  busy: false,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _completePurchase('Telebirr');
                  },
                ),
                const SizedBox(height: 12),
                _PaymentOptionTile(
                  label: 'Chapa',
                  subtitle: 'Cards & mobile money via Chapa',
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF6B21A8),
                  busy: false,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _completePurchase('Chapa');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completePurchase(String paymentMethod) async {
    if (_checkoutBusy) return;
    if (!mounted) return;
    setState(() => _checkoutBusy = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Processing $paymentMethod…',
                  style: GoogleFonts.poppins(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Order? order;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      order = await ref.read(ordersProvider.notifier).placeOrder(
            dealId: widget.deal.id,
            quantity: _quantity,
            preferredMethod: _delivery ? 'delivery' : 'pickup',
            deliveryFee: kDeliveryFeeEtb,
            paymentMethod: paymentMethod,
          );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        setState(() => _checkoutBusy = false);
      }
    }

    if (!mounted || order == null) return;

    ref.invalidate(dealDetailProvider(widget.deal.id));
    await ref.read(dealsProvider.notifier).refresh();
    final fulfillment = _delivery ? 'delivery' : 'pickup';
    try {
      await ref.read(notificationsServiceProvider).insertOrderPlaced(
            title: 'Order placed',
            message:
                'Order code: ${order.claimCode ?? '—'}. ${_delivery ? 'Delivery' : 'Pickup'} ($paymentMethod).',
          );
      await ref.read(notificationsListProvider.notifier).refresh();
    } catch (_) {}
    if (mounted) {
      _showSuccessDialog(order, fulfillment, paymentMethod);
    }
  }

  void _showSuccessDialog(
    Order order,
    String fulfillment,
    String paymentMethod,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.primary, size: 64),
            const SizedBox(height: 16),
            Text(
              'Payment successful',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paid with $paymentMethod',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your order code',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.claimCode ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              fulfillment == 'delivery'
                  ? 'We’ll use this code for your delivery. Keep it handy.'
                  : 'Show this code when you pick up your order.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textMedium,
                height: 1.35,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/orders'),
              child: const Text('View My Orders'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final deal =
        ref.watch(dealDetailProvider(widget.deal.id)).valueOrNull ?? widget.deal;
    _clampQuantityToStock(deal.availableQuantity);

    final subtotal = deal.discountedPrice * _quantity;
    final deliveryFee = _deliveryFeeLine();
    final grandTotal = subtotal + deliveryFee;
    final savings =
        (deal.originalPrice - deal.discountedPrice) * _quantity;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: deal.images.isNotEmpty
                        ? Image.network(
                            deal.images.first,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ETB ${deal.discountedPrice.toStringAsFixed(0)} / item',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (ordersState.error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: ordersState.error!),
            ],

            const SizedBox(height: 28),
            Text(
              'How do you want it?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FulfillmentChip(
                    label: 'Pickup',
                    subtitle: 'Collect at store',
                    icon: Icons.storefront_outlined,
                    selected: !_delivery,
                    onTap: () => setState(() => _delivery = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FulfillmentChip(
                    label: 'Delivery',
                    subtitle: '+ ETB ${kDeliveryFeeEtb.toStringAsFixed(0)}',
                    icon: Icons.delivery_dining_rounded,
                    selected: _delivery,
                    onTap: () => setState(() => _delivery = true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            Text(
              'Quantity',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _quantity < deal.availableQuantity
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
                Text(
                  '${deal.availableQuantity} left',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            Text(
              'Order summary',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Subtotal',
              value: 'ETB ${subtotal.toStringAsFixed(0)}',
            ),
            if (_delivery)
              _SummaryRow(
                label: 'Delivery fee',
                value: 'ETB ${deliveryFee.toStringAsFixed(0)}',
              ),
            _SummaryRow(
              label: 'You save',
              value: 'ETB ${savings.toStringAsFixed(0)}',
              valueColor: AppTheme.primary,
            ),
            const Divider(height: 28),
            _SummaryRow(
              label: 'Total',
              value: 'ETB ${grandTotal.toStringAsFixed(0)}',
              isBold: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ElevatedButton(
            onPressed: ordersState.isPlacing || _checkoutBusy || deal.availableQuantity < 1
                ? null
                : () => _openPaymentSheet(grandTotal),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
            ),
            child: Text(
              'Continue to payment — ETB ${grandTotal.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppTheme.divider,
      child: const Icon(Icons.storefront_outlined, color: AppTheme.textLight),
    );
  }
}

class _FulfillmentChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FulfillmentChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.12)
          : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  color: selected ? AppTheme.primary : AppTheme.textMedium),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textMedium,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? AppTheme.textDark,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontSize: isBold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
