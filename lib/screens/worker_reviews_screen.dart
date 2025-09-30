// lib/screens/worker_reviews_screen.dart
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/rating_service.dart';
import 'package:intl/intl.dart';

class WorkerReviewsScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const WorkerReviewsScreen({
    Key? key,
    required this.workerId,
    required this.workerName,
  }) : super(key: key);

  @override
  _WorkerReviewsScreenState createState() => _WorkerReviewsScreenState();
}

class _WorkerReviewsScreenState extends State<WorkerReviewsScreen> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final reviews = await RatingService.getWorkerReviews(widget.workerId);
      final stats = await RatingService.getWorkerRatingStats(widget.workerId);

      setState(() {
        _reviews = reviews;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load reviews: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews'),
        backgroundColor: Color(0xFFFF9800),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: _reviews.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildRatingHeader(),
                          _buildRatingBreakdown(),
                          Divider(thickness: 8, color: Colors.grey[200]),
                          _buildReviewsList(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Reviews from customers will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHeader() {
    double averageRating = _stats['average_rating'] ?? 0.0;
    int totalReviews = _stats['total_reviews'] ?? 0;

    return Container(
      padding: EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Average rating
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : (index < averageRating.ceil() &&
                                    averageRating % 1 != 0)
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Color(0xFFFF9800),
                        size: 24,
                      );
                    }),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(width: 32),

              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getRatingDescription(averageRating),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBreakdown() {
    Map<int, int> breakdown = _stats['rating_breakdown'] ?? {};
    int totalReviews = _stats['total_reviews'] ?? 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...List.generate(5, (index) {
            int stars = 5 - index;
            int count = breakdown[stars] ?? 0;
            double percentage = totalReviews > 0 ? count / totalReviews : 0;

            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '$stars',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.star, size: 16, color: Color(0xFFFF9800)),
                  SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF9800),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => Divider(height: 24),
      itemBuilder: (context, index) {
        return _buildReviewCard(_reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer name and rating
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text(
                  review.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Color(0xFFFF9800),
                            size: 16,
                          );
                        }),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy').format(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Review text
          Text(
            review.review,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),

          // Tags
          if (review.tags.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.tags.map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Service type badge
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              review.serviceType,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent service quality';
    if (rating >= 4.0) return 'Very good service quality';
    if (rating >= 3.5) return 'Good service quality';
    if (rating >= 3.0) return 'Average service quality';
    return 'Needs improvement';
  }
}
