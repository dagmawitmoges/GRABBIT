import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../model/review_model.dart';
import '../provider/deals_provider.dart';

class DealDetailScreen extends ConsumerWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});
String _getDetailImage(deal) {
  if (deal.images.isNotEmpty) {
    return deal.images.first;
  }
  switch (deal.title) {
    case 'Grilled Meat Platter':
      return 'lib/assets/grilled.jpg';
    case 'Vegan Pastry Box':
      return 'lib/assets/veganpastry.jpg';
    default:
      return 'lib/assets/juicecombo.jpg';
  }
}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealAsync = ref.watch(dealDetailProvider(dealId));
    final reviewsAsync = ref.watch(dealReviewsProvider(dealId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: dealAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.red, size: 48),
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
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppTheme.primary,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppTheme.textDark, size: 18),
                ),
              ),
             flexibleSpace: FlexibleSpaceBar(
  background: _getDetailImage(deal).startsWith('http')
      ? Image.network(
          _getDetailImage(deal),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.divider,
            child: const Icon(Icons.storefront_outlined,
                size: 80, color: AppTheme.textLight),
          ),
        )
      : Image.asset(
          _getDetailImage(deal),
          fit: BoxFit.cover,
        ),
),

            ),

            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    Row(
                      children: [
                        if (deal.categoryName != null)
                          _Tag(
                              label: deal.categoryName!,
                              color: AppTheme.primary),
                        if (deal.subcityName != null) ...[
                          const SizedBox(width: 8),
                          _Tag(label: deal.subcityName!, color: Colors.blue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      deal.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Discounted Price',
                                style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontSize: 12),
                              ),
                              Text(
                                'ETB ${deal.discountedPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(
                                'ETB ${deal.originalPrice.toStringAsFixed(0)} original',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textLight,
                                  decoration:
                                      TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${deal.discountPercentage.toStringAsFixed(0)}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Info row
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.inventory_2_outlined,
                          label:
                              '${deal.availableQuantity} available',
                          color: deal.availableQuantity < 5
                              ? Colors.orange
                              : AppTheme.primary,
                        ),
                        if (deal.expiryTime != null) ...[
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.access_time,
                            label:
                                'Expires ${_formatDate(deal.expiryTime!)}',
                            color: AppTheme.textMedium,
                          ),
                        ],
                      ],
                    ),

                    if (deal.description != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'About this deal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        deal.description!,
                        style: const TextStyle(
                          color: AppTheme.textMedium,
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    const Text(
                      'Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    reviewsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      ),
                      error: (_, __) => const Text(
                        'Could not load reviews',
                        style:
                            TextStyle(color: AppTheme.textLight),
                      ),
                      data: (reviews) => reviews.isEmpty
                          ? const Text(
                              'No reviews yet',
                              style: TextStyle(
                                  color: AppTheme.textLight),
                            )
                          : Column(
                              children: reviews
                                  .map((r) =>
                                      _ReviewCard(review: r))
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
      bottomNavigationBar: dealAsync.maybeWhen(
        data: (deal) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(
              deal.availableQuantity > 0
                  ? 'Reserve Now'
                  : 'Out of Stock',
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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.reviewerName ?? 'Anonymous',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star
                        : Icons.star_border,
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
              style: const TextStyle(
                  color: AppTheme.textMedium, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
