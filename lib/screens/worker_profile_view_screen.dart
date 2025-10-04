// lib/screens/worker_profile_view_screen.dart
// NEW FILE - Customer can view worker profile details, ratings, and reviews
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../models/review_model.dart';
import '../services/rating_service.dart';
import 'package:intl/intl.dart';

class WorkerProfileViewScreen extends StatefulWidget {
  final String workerId;

  const WorkerProfileViewScreen({
    Key? key,
    required this.workerId,
  }) : super(key: key);

  @override
  _WorkerProfileViewScreenState createState() =>
      _WorkerProfileViewScreenState();
}

class _WorkerProfileViewScreenState extends State<WorkerProfileViewScreen> {
  bool _isLoading = true;
  WorkerModel? _worker;
  List<ReviewModel> _reviews = [];
  Map<String, dynamic> _ratingStats = {};

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 Looking for worker with ID: ${widget.workerId}');

      // Try to get worker directly by document ID (Firebase UID)
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.workerId)
          .get();

      // If not found by UID, try searching by worker_id field
      if (!workerDoc.exists) {
        print('⚠️ Not found by UID, searching by worker_id field...');
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('workers')
            .where('worker_id', isEqualTo: widget.workerId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('Worker not found');
        }

        workerDoc = querySnapshot.docs.first;
      }

      print('✅ Worker document found!');

      // Check if document data is valid before parsing
      if (!workerDoc.exists || workerDoc.data() == null) {
        throw Exception('Worker document is empty or invalid');
      }

      // Try to parse the worker model with error handling
      try {
        _worker = WorkerModel.fromFirestore(workerDoc);
        print('✅ Worker model parsed successfully: ${_worker!.workerName}');
      } catch (parseError) {
        print('❌ Error parsing worker model: $parseError');
        print('📄 Raw document data: ${workerDoc.data()}');
        throw Exception(
            'Failed to parse worker data: ${parseError.toString()}');
      }

      // Load reviews and ratings
      _reviews = await RatingService.getWorkerReviews(widget.workerId);
      _ratingStats = await RatingService.getWorkerRatingStats(widget.workerId);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load worker profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Worker Profile'),
          backgroundColor: Colors.blue,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Worker Profile'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Worker profile not found',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Profile'),
        backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),

              // Personal Details
              _buildPersonalDetails(),

              // Rating & Reviews Section
              _buildRatingsSection(),

              // Reviews List
              _buildReviewsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Photo
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: _worker!.profilePictureUrl != null &&
                      _worker!.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(_worker!.profilePictureUrl!)
                  : null,
              child: _worker!.profilePictureUrl == null ||
                      _worker!.profilePictureUrl!.isEmpty
                  ? Text(
                      _worker!.workerName.isNotEmpty
                          ? _worker!.workerName[0].toUpperCase()
                          : 'W',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(height: 16),

          // Name
          Text(
            _worker!.workerName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),

          // Service Type
          Text(
            _worker!.serviceType,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),

          // Verified Badge
          if (_worker!.verified)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Verified Worker',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

          SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.star,
                _worker!.rating > 0
                    ? _worker!.rating.toStringAsFixed(1)
                    : 'New',
                'Rating',
              ),
              _buildStatItem(
                Icons.work,
                '${_worker!.jobsCompleted}',
                'Jobs Done',
              ),
              _buildStatItem(
                Icons.trending_up,
                '${_worker!.successRate.toStringAsFixed(0)}%',
                'Success',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetails() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Business Name
          _buildDetailRow(Icons.business, 'Business', _worker!.businessName),

          // Experience
          _buildDetailRow(
            Icons.calendar_today,
            'Experience',
            '${_worker!.experienceYears} years',
          ),

          // Location
          _buildDetailRow(
            Icons.location_on,
            'Location',
            '${_worker!.location.city}${_worker!.location.state.isNotEmpty ? ", ${_worker!.location.state}" : ""}',
          ),

          // Phone
          if (_worker!.contact.phoneNumber.isNotEmpty)
            _buildDetailRow(
              Icons.phone,
              'Phone',
              _worker!.contact.phoneNumber,
            ),

          // Email
          if (_worker!.contact.email.isNotEmpty)
            _buildDetailRow(
              Icons.email,
              'Email',
              _worker!.contact.email,
            ),

          // Bio
          if (_worker!.profile.bio.isNotEmpty) ...[
            Divider(height: 24),
            Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _worker!.profile.bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],

          // Pricing
          Divider(height: 24),
          Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildPricingRow(
            'Daily Wage',
            'LKR ${_worker!.pricing.dailyWageLkr.toStringAsFixed(0)}',
          ),
          if (_worker!.pricing.halfDayRateLkr > 0)
            _buildPricingRow(
              'Half Day',
              'LKR ${_worker!.pricing.halfDayRateLkr.toStringAsFixed(0)}',
            ),
          if (_worker!.pricing.minimumChargeLkr > 0)
            _buildPricingRow(
              'Minimum Charge',
              'LKR ${_worker!.pricing.minimumChargeLkr.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    if (_ratingStats.isEmpty || _ratingStats['total_reviews'] == 0) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.star_border, size: 48, color: Colors.grey[300]),
            SizedBox(height: 8),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    double avgRating = _ratingStats['average_rating'] ?? 0.0;
    int totalReviews = _ratingStats['total_reviews'] ?? 0;
    Map<int, int> breakdown = _ratingStats['rating_breakdown'] ?? {};

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
          Row(
            children: [
              // Average Rating
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$totalReviews reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Breakdown
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      _buildRatingBar(i, breakdown[i] ?? 0, totalReviews),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    double percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
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
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Show first 5 reviews
          ...(_reviews.take(5).map((review) => _buildReviewCard(review))),

          // View All Reviews button if more than 5
          if (_reviews.length > 5)
            Center(
              child: TextButton(
                onPressed: () {
                  // Show all reviews in dialog or new screen
                  _showAllReviews();
                },
                child: Text('View All ${_reviews.length} Reviews'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  review.customerName.isNotEmpty
                      ? review.customerName[0].toUpperCase()
                      : 'C',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(review.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            review.review,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          if (review.tags.isNotEmpty) ...[
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: review.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.blue[50],
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'All Reviews (${_reviews.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(_reviews[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
