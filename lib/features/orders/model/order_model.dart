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
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        dealId: json['deal_id'] as String,
        dealTitle: json['deal_title'] as String?,
        discountedPrice: json['discounted_price'] != null
            ? double.tryParse(json['discounted_price'].toString())
            : null,
        quantity: (json['quantity'] ?? 1) as int,
        status: json['status'] as String,
        claimCode: json['claim_code'] as String?,
        pickupAt: json['pickup_at'] as String?,
        createdAt: json['created_at'] as String,
      );

  bool get isCancellable =>
      status != 'Cancelled' && status != 'Completed';
} 