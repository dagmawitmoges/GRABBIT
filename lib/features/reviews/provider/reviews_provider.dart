import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../deals/model/review_model.dart';
import '../service/reviews_service.dart';

final reviewsServiceProvider =
    Provider<ReviewsService>((ref) => ReviewsService());

final vendorReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, vendorUserId) async {
  return ref.read(reviewsServiceProvider).fetchReviewsForVendor(vendorUserId);
});
