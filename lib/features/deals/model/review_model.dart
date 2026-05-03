class Review {
  final String id;
  final int rating;
  final String? comment;
  final String? reviewerName;
  final String createdAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    this.reviewerName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final r = json['rating'];
    return Review(
      id: json['id'] as String,
      rating: r is int ? r : int.tryParse('$r') ?? 0,
      comment: json['comment'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}