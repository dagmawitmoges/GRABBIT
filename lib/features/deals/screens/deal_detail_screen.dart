import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../model/review_model.dart';
import '../provider/deals_provider.dart';

class DealDetailScreen extends ConsumerWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealDetailProvider(dealId));
    final reviewsAsync = ref.watch(dealReviewsProvider(dealId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: dealAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(err.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (deal) => CustomScrollView(
          slivers: [
            // Image app bar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back_ios,
                      color: Colors.black, size: 16),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: deal.images.isNotEmpty
                    ? Image.network(
                        deal.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.storefront_outlined,
                              size: 80, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.storefront_outlined,
                            size: 80, color: Colors.grey),
                      ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & subcity
                    Row(
                      children: [
                        if (deal.categoryName != null)
                          _Tag(label: deal.categoryName!,
                              color: const Color(0xFF1DB954)),
                        if (deal.subcityName != null) ...[
                          const SizedBox(width: 8),
                          _Tag(
                              label: deal.subcityName!,
                              color: Colors.blue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      deal.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price row
                    Row(
                      children: [
                        Text(
                          'ETB ${deal.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ETB ${deal.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB954),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${deal.discountPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info row
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${deal.availableQuantity} available',
                          style: TextStyle(
                            color: deal.availableQuantity < 5
                                ? Colors.orange
                                : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (deal.expiryTime != null) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Expires ${_formatDate(deal.expiryTime!)}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    if (deal.description != null) ...[
                      const Text(
                        'About this deal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        deal.description!,
                        style: TextStyle(
                            color: Colors.grey[700], height: 1.5),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Reviews section
                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    reviewsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF1DB954)),
                      ),
                      error: (_, __) => const Text(
                        'Could not load reviews',
                        style: TextStyle(color: Colors.grey),
                      ),
                      data: (reviews) => reviews.isEmpty
                          ? const Text(
                              'No reviews yet',
                              style: TextStyle(color: Colors.grey),
                            )
                          : Column(
                              children: reviews
                                  .map((r) => _ReviewCard(review: r))
                                  .toList(),
                            ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Reserve button
      bottomNavigationBar: dealAsync.maybeWhen(
        data: (deal) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: deal.availableQuantity > 0
                ? () => context.push('/orders/new', extra: deal)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              deal.availableQuantity > 0 ? 'Reserve Now' : 'Out of Stock',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.reviewerName ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
          if (review.comment != null) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}