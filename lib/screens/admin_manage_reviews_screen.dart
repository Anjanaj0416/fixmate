// lib/screens/admin_manage_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageReviewsScreen extends StatefulWidget {
  @override
  _AdminManageReviewsScreenState createState() =>
      _AdminManageReviewsScreenState();
}

class _AdminManageReviewsScreenState extends State<AdminManageReviewsScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No reviews found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String customerName = data['customer_name'] ?? 'Unknown Customer';
            String workerName = data['worker_name'] ?? 'Unknown Worker';
            double rating = (data['rating'] ?? 0.0).toDouble();
            String review = data['review'] ?? 'No review text';
            String serviceType = data['service_type'] ?? 'Unknown';
            Timestamp? createdAt = data['created_at'] as Timestamp?;
            String bookingId = data['booking_id'] ?? 'N/A';

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'reviewed $workerName',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDeleteReview(doc.id, customerName),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                        SizedBox(width: 8),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Review Text
                    Text(
                      review,
                      style: TextStyle(fontSize: 14),
                    ),

                    SizedBox(height: 12),

                    // Footer Info
                    Divider(),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service: ${serviceType.replaceAll('_', ' ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Booking ID: $bookingId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt.toDate()),
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
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDeleteReview(
      String reviewId, String customerName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Review'),
        content: Text(
          'Are you sure you want to delete the review by $customerName? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteReview(reviewId);
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
