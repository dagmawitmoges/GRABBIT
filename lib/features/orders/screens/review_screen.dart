import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/provider/auth_provider.dart';
import '../../deals/provider/deals_provider.dart';
import '../../reviews/provider/reviews_provider.dart';
import 'package:dio/dio.dart';
import '../model/review_route_args.dart';
import '../model/order_model.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String dealId;
  final String dealTitle;
  final Order? order;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.dealId,
    required this.dealTitle,
    this.order,
  });

  factory ReviewScreen.fromArgs(ReviewRouteArgs args) {
    return ReviewScreen(
      orderId: args.orderId,
      dealId: args.dealId,
      dealTitle: args.dealTitle,
      order: args.order,
    );
  }

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final name = ref.read(authProvider).user?.fullName.trim();
    final reviewerName =
        (name != null && name.isNotEmpty) ? name : 'Customer';

    try {
      if (Env.hasSupabase) {
        if (widget.dealId.isEmpty) {
          throw 'Missing deal information. Open this screen from your order.';
        }
        await ref.read(reviewsServiceProvider).submitReviewForCompletedOrder(
              orderId: widget.orderId,
              dealId: widget.dealId,
              rating: _rating,
              comment: _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
              reviewerName: reviewerName,
            );
        ref.invalidate(dealReviewsProvider(widget.dealId));
        ref.invalidate(dealDetailProvider(widget.dealId));
        await ref.read(dealsProvider.notifier).refresh();
      } else {
        await DioClient.instance.post(
          '${ApiConstants.orders}/${widget.orderId}/review',
          data: {
            'rating': _rating,
            'comment': _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Review submitted! It appears on the deal and the business profile.',
            ),
            backgroundColor: AppTheme.primary,
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Failed to submit review. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showOrderDetails() {
    final o = widget.order;
    if (o == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${o.claimCode ?? '—'}'),
            Text('Qty: ${o.quantity}'),
            Text('Status: ${o.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Rate your order',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.order != null)
            TextButton(
              onPressed: _showOrderDetails,
              child: const Text(
                'Order',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dealTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How was your experience?',
              style: TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            const Text(
              'Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabel(_rating),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Comment (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
