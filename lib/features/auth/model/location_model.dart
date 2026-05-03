class Location {
  final String id;
  final String? subCity;
  final String city;
  final String country;
  final int sortOrder;

  Location({
    required this.id,
    this.subCity,
    required this.city,
    required this.country,
    this.sortOrder = 0,
  });

  /// Short label for dropdowns (e.g. "Bole · Addis Ababa").
  String get label {
    final s = (subCity ?? '').trim();
    if (s.isEmpty) return city;
    return '$s · $city';
  }

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: '${json['id']}',
        subCity: json['sub_city'] as String?,
        city: (json['city'] as String?) ?? '',
        country: (json['country'] as String?) ?? '',
        sortOrder: json['sort_order'] is int
            ? json['sort_order'] as int
            : int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
