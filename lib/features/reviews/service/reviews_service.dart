import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../deals/model/review_model.dart';

class ReviewsService {
  Future<bool> hasReviewForOrder(String orderId) async {
    if (!Env.hasSupabase) return false;
    try {
      final row = await Supabase.instance.client
          .from('reviews')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();
      return row != null;
    } on PostgrestException {
      return false;
    }
  }

  Future<void> submitReviewForCompletedOrder({
    required String orderId,
    required String dealId,
    required int rating,
    String? comment,
    required String reviewerName,
  }) async {
    if (!Env.hasSupabase) {
      throw 'Reviews require Supabase.';
    }
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw 'Sign in to submit a review.';

    try {
      await Supabase.instance.client.from('reviews').insert({
        'order_id': orderId,
        'deal_id': dealId,
        'user_id': uid,
        'rating': rating,
        'comment': comment,
        'reviewer_name': reviewerName.isEmpty ? null : reviewerName,
      });
    } on PostgrestException catch (e) {
      final code = e.code?.toString();
      if (code == '23505') {
        throw 'You already submitted a review for this order.';
      }
      throw e.message;
    }
  }

  /// All reviews for deals belonging to this vendor (via denormalized `vendor_user_id`).
  Future<List<Review>> fetchReviewsForVendor(String vendorUserId) async {
    if (!Env.hasSupabase) return [];

    try {
      final rows = await Supabase.instance.client
          .from('reviews')
          .select()
          .eq('vendor_user_id', vendorUserId)
          .order('created_at', ascending: false);

      final list = rows as List<dynamic>;
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Review.fromJson({
          'id': '${m['id']}',
          'rating': m['rating'] is int
              ? m['rating'] as int
              : int.tryParse('${m['rating']}') ?? 0,
          'comment': m['comment'] as String?,
          'reviewer_name': m['reviewer_name'] as String?,
          'created_at': m['created_at']?.toString() ?? '',
        });
      }).toList();
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }
}
