import 'order_model.dart';

/// Arguments for [ReviewScreen] via GoRouter `extra`.
class ReviewRouteArgs {
  final String orderId;
  final String dealId;
  final String dealTitle;
  final Order? order;

  const ReviewRouteArgs({
    required this.orderId,
    required this.dealId,
    required this.dealTitle,
    this.order,
  });
}
