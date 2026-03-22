import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/error_banner.dart';
import 'package:dio/dio.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String dealTitle;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.dealTitle,
  });

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

    try {
      await DioClient.instance.post(
        '${ApiConstants.orders}/${widget.orderId}/review',
        data: {
          'rating': _rating,
          'comment': _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Color(0xFF1DB954),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Write a Review',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Deal title
            Text(
              widget.dealTitle,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'How was your experience?',
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 32),

            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],

            // Star rating
            const Text(
              'Rating',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
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
                color: Color(0xFF1DB954),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 32),

            // Comment
            const Text(
              'Comment (optional)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience with this deal...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1DB954)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
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
                        'Submit Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
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
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}