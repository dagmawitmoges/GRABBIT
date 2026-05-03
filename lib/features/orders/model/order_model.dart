class Order {
  final String id;
  final String dealId;
  final String? dealTitle;
  final double? discountedPrice;
  final int quantity;
  final String status;
  final String? claimCode;
  final String? pickupAt;
  final String createdAt;
  /// Charged total (includes delivery when applicable). From `orders.total_price`.
  final double? totalPrice;
  /// `pickup` or `delivery` when set.
  final String? preferredMethod;

  Order({
    required this.id,
    required this.dealId,
    this.dealTitle,
    this.discountedPrice,
    required this.quantity,
    required this.status,
    this.claimCode,
    this.pickupAt,
    required this.createdAt,
    this.totalPrice,
    this.preferredMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        dealId: json['deal_id'] as String,
        dealTitle: json['deal_title'] as String?,
        discountedPrice: json['discounted_price'] != null
            ? double.tryParse(json['discounted_price'].toString())
            : null,
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse('${json['quantity'] ?? 1}') ?? 1,
        status: json['status'] == null
            ? ''
            : json['status'] is String
                ? json['status'] as String
                : json['status'].toString(),
        claimCode: (json['order_code'] ?? json['claim_code']) as String?,
        pickupAt: json['pickup_at'] as String?,
        createdAt: json['created_at'] as String,
        totalPrice: json['total_price'] != null
            ? double.tryParse(json['total_price'].toString())
            : null,
        preferredMethod: json['preferred_method'] as String?,
      );

  /// Subtotal from unit deal price × quantity (may differ from [totalPrice] if delivery was added).
  double? get lineSubtotal {
    if (discountedPrice == null) return null;
    return discountedPrice! * quantity;
  }

  bool get isCancellable {
    final s = status.toLowerCase();
    return s != 'canceled' &&
        s != 'cancelled' &&
        s != 'completed';
  }
}