// lib/screens/customer_bookings_screen.dart
// FIXED VERSION - Restores original functionality + Rating feature

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class CustomerBookingsScreen extends StatefulWidget {
  @override
  _CustomerBookingsScreenState createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerId = customerData['customer_id'];
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load customer data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_customerId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Requested', style: TextStyle(fontSize: 14)),
                  _buildBookingCountBadge('requested'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Active', style: TextStyle(fontSize: 14)),
                  _buildBookingCountBadge('active'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Completed', style: TextStyle(fontSize: 14)),
                  _buildBookingCountBadge('completed'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Cancelled', style: TextStyle(fontSize: 14)),
                  _buildBookingCountBadge('cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList('requested'),
          _buildBookingList('active'),
          _buildBookingList('completed'),
          _buildBookingList('cancelled'),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getBookingsStream(String type) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customer_id', isEqualTo: _customerId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Widget _buildBookingList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading bookings'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(type);
        }

        // Filter bookings based on type
        List<DocumentSnapshot> filteredDocs = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? '';

          switch (type) {
            case 'requested':
              return status == 'requested';
            case 'active':
              return status == 'accepted' || status == 'in_progress';
            case 'completed':
              return status == 'completed';
            case 'cancelled':
              return status == 'cancelled' || status == 'declined';
            default:
              return true;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = filteredDocs[index];
              BookingModel booking = BookingModel.fromFirestore(doc);
              return _buildBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCountBadge(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        int count = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String status = data['status'] ?? '';

          switch (type) {
            case 'requested':
              return status == 'requested';
            case 'active':
              return status == 'accepted' || status == 'in_progress';
            case 'completed':
              return status == 'completed';
            case 'cancelled':
              return status == 'cancelled' || status == 'declined';
            default:
              return true;
          }
        }).length;

        if (count == 0) return SizedBox();

        return Container(
          margin: EdgeInsets.only(top: 2),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF9800),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String message;
    String subtitle;

    switch (type) {
      case 'requested':
        icon = Icons.schedule;
        message = 'No pending requests';
        subtitle = 'Your booking requests will appear here';
        break;
      case 'active':
        icon = Icons.event_available;
        message = 'No active bookings';
        subtitle = 'Accepted bookings will appear here';
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        message = 'No completed bookings yet';
        subtitle = 'Completed services will appear here';
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        message = 'No cancelled bookings';
        subtitle = 'Cancelled services will appear here';
        break;
      default:
        icon = Icons.calendar_today;
        message = 'No bookings yet';
        subtitle = 'Start by booking a service';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),

              SizedBox(height: 12),

              // Worker info with rating display
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Icon(Icons.person, color: Colors.orange),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.workerName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (booking.workerPhone.isNotEmpty)
                          Text(
                            booking.workerPhone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        // Show worker's average rating from reviews
                        FutureBuilder<double>(
                          future: _getWorkerAverageRating(booking.workerId),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              return Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    snapshot.data!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),

              // Booking details
              if (booking.issueType.isNotEmpty)
                Text(
                  booking.issueType.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),

              SizedBox(height: 8),

              // Problem description
              Text(
                booking.problemDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.location_on,
                    booking.location.replaceAll('_', ' '),
                  ),
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(booking.scheduledDate),
                  ),
                  _buildInfoChip(
                    Icons.access_time,
                    booking.scheduledTime,
                  ),
                  if (booking.urgency.isNotEmpty)
                    _buildUrgencyChip(booking.urgency),
                ],
              ),

              // Action buttons based on status
              if (booking.status == BookingStatus.requested) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelBooking(booking),
                        icon: Icon(Icons.cancel, size: 18),
                        label: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showBookingDetails(booking),
                        icon: Icon(Icons.info_outline, size: 18),
                        label: Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.inProgress) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _contactWorker(booking),
                        icon: Icon(Icons.phone, size: 18),
                        label: Text('Contact Worker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // RATING BUTTON for completed bookings
              if (booking.status == BookingStatus.completed &&
                  booking.customerRating == null) ...[
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _rateBooking(booking),
                  icon: Icon(Icons.star, size: 18),
                  label: Text('Rate Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],

              // SHOW RATING if already rated
              if (booking.status == BookingStatus.completed &&
                  booking.customerRating != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'You rated: ${booking.customerRating!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => _viewYourReview(booking),
                        child: Text('View Review'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Get worker's average rating from reviews collection
  Future<double> _getWorkerAverageRating(String workerId) async {
    try {
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data() as Map<String, dynamic>)['rating'] ?? 0.0;
      }

      return totalRating / reviewsSnapshot.docs.length;
    } catch (e) {
      print('Error getting worker rating: $e');
      return 0.0;
    }
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: status.color,
          ),
          SizedBox(width: 4),
          Text(
            status.displayName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Icons.schedule;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.work;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String urgency) {
    Color color =
        urgency.toLowerCase() == 'urgent' ? Colors.red : Colors.orange;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            urgency.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildStatusBadge(booking.status),
              SizedBox(height: 20),
              _buildDetailRow(
                  'Service Type', booking.serviceType.replaceAll('_', ' ')),
              _buildDetailRow('Issue', booking.issueType.replaceAll('_', ' ')),
              _buildDetailRow('Worker', booking.workerName),
              _buildDetailRow('Phone', booking.workerPhone),
              _buildDetailRow(
                  'Location', booking.location.replaceAll('_', ' ')),
              _buildDetailRow('Address', booking.address),
              _buildDetailRow('Date', _formatDate(booking.scheduledDate)),
              _buildDetailRow('Time', booking.scheduledTime),
              _buildDetailRow('Budget', booking.budgetRange),
              if (booking.finalPrice != null)
                _buildDetailRow('Final Price',
                    'LKR ${booking.finalPrice!.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              Text(
                'Problem Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking.problemDescription),
              ),

              // Show worker's reviews section
              SizedBox(height: 20),
              Text(
                'Worker Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getWorkerReviews(booking.workerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No reviews yet',
                        style: TextStyle(color: Colors.grey));
                  }
                  return Column(
                    children: snapshot.data!.take(3).map((review) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < review['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 16,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    review['customer_name'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (review['review'].isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(review['review']),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: 20),
              if (booking.status == BookingStatus.accepted ||
                  booking.status == BookingStatus.inProgress)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactWorker(booking);
                  },
                  icon: Icon(Icons.phone),
                  label: Text('Contact Worker'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get worker reviews
  Future<List<Map<String, dynamic>>> _getWorkerReviews(String workerId) async {
    try {
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('worker_id', isEqualTo: workerId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      return reviewsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(BookingModel booking) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel this booking?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Why are you cancelling?',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BookingService.cancelBooking(
                  booking.bookingId,
                  reasonController.text.isNotEmpty
                      ? reasonController.text
                      : 'Customer cancelled',
                );
                _showSuccessSnackBar('Booking cancelled');
              } catch (e) {
                _showErrorSnackBar('Failed to cancel: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _contactWorker(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.workerName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              booking.workerPhone,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showInfoSnackBar('Opening dialer...');
            },
            icon: Icon(Icons.phone),
            label: Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _rateBooking(BookingModel booking) {
    double rating = 0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rate Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How was your experience with ${booking.workerName}?'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: reviewController,
                  decoration: InputDecoration(
                    labelText: 'Review (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Share your experience...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: rating > 0
                  ? () async {
                      Navigator.pop(context);
                      try {
                        // Save rating to booking
                        await FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(booking.bookingId)
                            .update({
                          'customer_rating': rating,
                          'customer_review': reviewController.text,
                          'updated_at': FieldValue.serverTimestamp(),
                        });

                        // Save to reviews collection
                        String reviewId = FirebaseFirestore.instance
                            .collection('reviews')
                            .doc()
                            .id;

                        await FirebaseFirestore.instance
                            .collection('reviews')
                            .doc(reviewId)
                            .set({
                          'review_id': reviewId,
                          'booking_id': booking.bookingId,
                          'customer_id': booking.customerId,
                          'customer_name': booking.customerName,
                          'worker_id': booking.workerId,
                          'worker_name': booking.workerName,
                          'rating': rating,
                          'review': reviewController.text,
                          'service_type': booking.serviceType,
                          'created_at': FieldValue.serverTimestamp(),
                          'is_verified': true,
                        });

                        _showSuccessSnackBar('Thank you for your feedback!');
                      } catch (e) {
                        _showErrorSnackBar(
                            'Failed to submit rating: ${e.toString()}');
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewYourReview(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < (booking.customerRating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            SizedBox(height: 12),
            Text(
              'Rating: ${booking.customerRating?.toStringAsFixed(1) ?? "N/A"}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (booking.customerReview != null &&
                booking.customerReview!.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Your Review:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking.customerReview!),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
