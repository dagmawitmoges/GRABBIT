import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../deals/model/review_model.dart';
import '../../reviews/provider/reviews_provider.dart';

class VendorReviewsScreen extends ConsumerWidget {
  final String vendorUserId;

  const VendorReviewsScreen({super.key, required this.vendorUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorReviewsProvider(vendorUserId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Business reviews',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return Center(
              child: Text(
                'No reviews for this business yet.',
                style: GoogleFonts.poppins(color: AppTheme.textMedium),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _VendorReviewTile(review: reviews[i]),
          );
        },
      ),
    );
  }
}

class _VendorReviewTile extends StatelessWidget {
  final Review review;

  const _VendorReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.reviewerName ?? 'Customer',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppTheme.textMedium,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
