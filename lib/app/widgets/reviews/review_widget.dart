import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/core/theme/app_theme.dart';
import 'package:souq/app/services/auth_service.dart';
import 'package:souq/app/services/buyer_service.dart';


class ReviewWidget extends StatefulWidget {
  final int refId;
  final String type; // 'P' for Product, 'S' for Seller
  final String entityName;

  const ReviewWidget({
    super.key,
    required this.refId,
    required this.type,
    required this.entityName,
  });

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<Map<String, dynamic>?> reviewSummary = Rx<Map<String, dynamic>?>(null);

  @override
  void initState() {
    super.initState();
    loadReviews();
    loadReviewSummary();
  }

  void loadReviews() async {
    isLoading.value = true;
    
      final buyerService = Get.find<BuyerService>();
      final response = widget.type == 'P'
          ? await buyerService.getProductReviews(widget.refId)
          : await buyerService.getSellerReviews(widget.refId);
      
      if (response.isSuccess && response.data != null) {
        reviews.value = List<Map<String, dynamic>>.from(response.data ?? []);
      }
   
    isLoading.value = false;
  }

  void loadReviewSummary() async {
  
      final buyerService = Get.find<BuyerService>();
      final response = widget.type == 'P'
          ? await buyerService.getProductReviewSummary(widget.refId)
          : await buyerService.getSellerReviewSummary(widget.refId);
      
      if (response.isSuccess && response.data != null) {
        reviewSummary.value = response.data;
      }
   
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSummary(),
        const SizedBox(height: 16),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Reviews',
          style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _showWriteReviewDialog,
          icon: const Icon(Icons.rate_review, size: 16),
          label: const Text('Write Review'),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Obx(() {
      final summary = reviewSummary.value;
      if (summary == null) return const SizedBox();
      
      final avgRating = (summary['averageRating'] ?? 0.0).toDouble();
      final totalReviews = summary['totalReviews'] ?? 0;
      
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: Get.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildStarRating(avgRating),
                  ],
                ),
                Text('$totalReviews reviews', style: Get.textTheme.bodySmall),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(child: _buildRatingBars(summary)),
          ],
        ),
      );
    });
  }

  Widget _buildRatingBars(Map<String, dynamic> summary) {
    final total = summary['totalReviews'] ?? 1;
    return Column(
      children: [
        for (int i = 5; i >= 1; i--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('$i', style: Get.textTheme.bodySmall),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: (summary['${i == 5 ? 'five' : i == 4 ? 'four' : i == 3 ? 'three' : i == 2 ? 'two' : 'one'}StarCount'] ?? 0) / total,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.buyerPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsList() {
    return Obx(() {
      if (isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (reviews.isEmpty) {
        return const Text('No reviews yet. Be the first to review!');
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reviews.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) => _buildReviewItem(reviews[index]),
      );
    });
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final rating = review['rating'] ?? review['Rating'] ?? 0;
    final userName = review['userName'] ?? review['UserName'] ?? 'Anonymous';
    final reviewText = review['reviewText'] ?? review['ReviewText'] ?? '';
    final reviewTitle = review['reviewTitle'] ?? review['ReviewTitle'] ?? '';
    final createdAt = DateTime.tryParse(review['createdAt'] ?? review['CreatedAt'] ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStarRating(rating.toDouble()),
              const SizedBox(width: 8),
              Text(userName, style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (createdAt != null)
                Text(_formatDate(createdAt), style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          if (reviewTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(reviewTitle, style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ],
          if (reviewText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(reviewText, style: Get.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWriteReviewDialog() {
    final authService = Get.find<AuthService>();
    if (authService.currentUser?.userid == null) {
      Get.snackbar('Login Required', 'Please login to write a review');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WriteReviewDialog(
        refId: widget.refId,
        type: widget.type,
        entityName: widget.entityName,
        onReviewSubmitted: () {
          loadReviews();
          loadReviewSummary();
        },
      ),
    );
  }
}

class WriteReviewDialog extends StatefulWidget {
  final int refId;
  final String type;
  final String entityName;
  final VoidCallback onReviewSubmitted;

  const WriteReviewDialog({
    super.key,
    required this.refId,
    required this.type,
    required this.entityName,
    required this.onReviewSubmitted,
  });

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  int selectedRating = 0;
  final titleController = TextEditingController();
  final reviewController = TextEditingController();
  bool isAnonymous = false;
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.entityName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating
            Row(
              children: [
                const Text('Rating: '),
                ...List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => selectedRating = index + 1),
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Review Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Review text
            TextField(
              controller: reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your Review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Anonymous option
            CheckboxListTile(
              title: const Text('Post anonymously'),
              value: isAnonymous,
              onChanged: (value) => setState(() => isAnonymous = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedRating > 0 && !isSubmitting ? _submitReview : null,
          child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
        ),
      ],
    );
  }

  void _submitReview() async {
    setState(() => isSubmitting = true);
    
    try {
      final buyerService = Get.find<BuyerService>();
      final response = widget.type == 'P'
          ? await buyerService.createProductReview(
              widget.refId,
              selectedRating,
              reviewController.text,
              titleController.text,
              isAnonymous,
            )
          : await buyerService.createSellerReview(
              widget.refId,
              selectedRating,
              reviewController.text,
              titleController.text,
              isAnonymous,
            );
      
      if (response.isSuccess) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
        widget.onReviewSubmitted();
        Get.snackbar('Success', 'Review submitted successfully');
      } else {
        Get.snackbar('Error', response.errorMessage ?? 'Failed to submit review');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error. Please try again.');
    }
    
    setState(() => isSubmitting = false);
  }
}
