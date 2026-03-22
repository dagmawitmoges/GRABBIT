class Deal {
  final String id;
  final String title;
  final String? description;
  final double originalPrice;
  final double discountedPrice;
  final int availableQuantity;
  final String? expiryTime;
  final List<String> images;
  final String? categoryName;
  final String? subcityName;
  final String? location;
  final bool isActive;
  final double? averageRating;

  Deal({
    required this.id,
    required this.title,
    this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.availableQuantity,
    this.expiryTime,
    required this.images,
    this.categoryName,
    this.subcityName,
    this.location,
    required this.isActive,
    this.averageRating,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    // Handle images — API returns array of URLs
    List<String> parseImages(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    // Handle price — may come as int or double
    double parsePrice(dynamic raw) {
      if (raw == null) return 0.0;
      if (raw is double) return raw;
      if (raw is int) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0.0;
    }

    return Deal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      originalPrice: parsePrice(json['original_price']),
      discountedPrice: parsePrice(
        json['discounted_price'] ?? json['discount_price'],
      ),
      availableQuantity: (json['available_quantity'] ??
              json['quantity_available'] ??
              json['total_quantity'] ??
              json['quantity'] ??
              0) as int,
      expiryTime: (json['expiry_time'] ?? json['expiry_date']) as String?,
      images: parseImages(json['images']),
      categoryName: json['category_name'] as String?,
      subcityName: json['subcity_name'] as String?,
      location: json['location'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
    );
  }

  double get discountPercentage =>
      ((originalPrice - discountedPrice) / originalPrice * 100);
}