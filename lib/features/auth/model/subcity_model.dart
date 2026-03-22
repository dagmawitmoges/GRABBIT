class Subcity {
  final String id;
  final String name;
  final int? sortOrder;

  Subcity({
    required this.id,
    required this.name,
    this.sortOrder,
  });

  factory Subcity.fromJson(Map<String, dynamic> json) => Subcity(
        id: json['id'] as String,
        name: json['name'] as String,
        sortOrder: json['sort_order'] as int?,
      );
}