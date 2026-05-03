class CustomerNotification {
  final String id;
  final String? title;
  final String? message;
  final bool isRead;
  final String createdAt;

  CustomerNotification({
    required this.id,
    this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory CustomerNotification.fromRow(Map<String, dynamic> m) {
    return CustomerNotification(
      id: '${m['id']}',
      title: m['title'] as String?,
      message: m['message'] as String?,
      isRead: m['is_read'] as bool? ?? false,
      createdAt: m['created_at']?.toString() ?? '',
    );
  }
}
