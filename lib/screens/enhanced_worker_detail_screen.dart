// lib/screens/enhanced_worker_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import 'worker_reviews_screen.dart';

class EnhancedWorkerDetailScreen extends StatefulWidget {
  final WorkerModel worker;
  final String? problemDescription; // Added optional parameter

  const EnhancedWorkerDetailScreen({
    Key? key,
    required this.worker,
    this.problemDescription, // Optional
  }) : super(key: key);

  @override
  _EnhancedWorkerDetailScreenState createState() =>
      _EnhancedWorkerDetailScreenState();
}

class _EnhancedWorkerDetailScreenState
    extends State<EnhancedWorkerDetailScreen> {
  RatingStats? _stats;
  List<ReviewModel> _recentReviews = [];
  bool _isLoadingStats = true;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    try {
      // Check if workerId is null
      if (widget.worker.workerId == null) {
        print('Warning: Worker ID is null');
        setState(() {
          _isLoadingStats = false;
          _isLoadingReviews = false;
        });
        return;
      }

      // Load rating statistics
      RatingStats stats = await ReviewService.getWorkerRatingStats(
        widget.worker.workerId!,
      );

      // Load recent reviews (first 3)
      List<ReviewModel> reviews = await ReviewService.getWorkerReviews(
        widget.worker.workerId!,
        limit: 3,
      );

      setState(() {
        _stats = stats;
        _recentReviews = reviews;
        _isLoadingStats = false;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Error loading rating data: $e');
      setState(() {
        _isLoadingStats = false;
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Profile'),
        backgroundColor: Color(0xFFFF9800),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share worker profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker header
            _buildWorkerHeader(),

            // Rating summary
            _buildRatingSummarySection(),

            Divider(height: 1, thickness: 8, color: Colors.grey[200]),

            // Recent reviews
            _buildRecentReviewsSection(),

            Divider(height: 1, thickness: 8, color: Colors.grey[200]),

            // Worker details
            _buildDetailsSection(),

            SizedBox(height: 80), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBookButton(),
    );
  }

  Widget _buildWorkerHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFFF9800),
            child: Text(
              widget.worker.firstName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(width: 16),

          // Worker info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.worker.workerName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.worker.serviceType.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      widget.worker.location.city,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Verified badge
          if (widget.worker.verified)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified, color: Colors.blue, size: 24),
                  SizedBox(height: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummarySection() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ratings & Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (_isLoadingStats)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFFF9800)),
              ),
            )
          else if (_stats != null && _stats!.totalReviews > 0)
            Row(
              children: [
                // Overall rating
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        _stats!.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _stats!.averageRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_stats!.totalReviews} reviews',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 20),

                // Rating bars
                Expanded(
                  flex: 3,
                  child: Column(
                    children: List.generate(5, (index) {
                      int stars = 5 - index;
                      double percentage = _stats!.getStarPercentage(stars);

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('$stars', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF9800),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_stats != null &&
                  _stats!.totalReviews > 3 &&
                  widget.worker.workerId != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerReviewsScreen(
                          workerId: widget.worker.workerId!,
                          workerName: widget.worker.workerName,
                        ),
                      ),
                    );
                  },
                  child: Text('See all'),
                ),
            ],
          ),
          SizedBox(height: 12),
          if (_isLoadingReviews)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFFF9800)),
              ),
            )
          else if (_recentReviews.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _recentReviews.length,
              separatorBuilder: (context, index) => Divider(height: 24),
              itemBuilder: (context, index) {
                return _buildReviewItem(_recentReviews[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Text(
                review.customerName[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        review.customerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (review.isVerified) ...[
                        SizedBox(width: 4),
                        Icon(Icons.verified, size: 14, color: Colors.blue),
                      ],
                    ],
                  ),
                  Text(
                    review.getTimeAgo(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating.round()
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
          ],
        ),
        if (review.review.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            review.review,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Show problem description if provided
          if (widget.problemDescription != null &&
              widget.problemDescription!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Your Request',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.problemDescription!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          _buildDetailItem(
            Icons.work_outline,
            'Experience',
            '${widget.worker.experienceYears} years',
          ),
          _buildDetailItem(
            Icons.check_circle_outline,
            'Jobs Completed',
            '${widget.worker.jobsCompleted} jobs',
          ),
          _buildDetailItem(
            Icons.trending_up,
            'Success Rate',
            '${widget.worker.successRate.toStringAsFixed(1)}%',
          ),
          _buildDetailItem(
            Icons.phone,
            'Contact',
            widget.worker.contact.phoneNumber,
          ),
          _buildDetailItem(
            Icons.attach_money,
            'Daily Rate',
            'LKR ${widget.worker.pricing.dailyWageLkr.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFFFF9800)),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBookButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to booking screen
            // You can implement this based on your booking flow
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF9800),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            'Book Now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
