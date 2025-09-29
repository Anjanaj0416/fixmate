// lib/screens/customer_bookings_screen.dart
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
                  Text('All', style: TextStyle(fontSize: 14)),
                  _buildBookingCountBadge('all'),
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
          _buildBookingList('all'),
          _buildBookingList('active'),
          _buildBookingList('completed'),
          _buildBookingList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingCountBadge(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        int count = snapshot.data!.docs.length;
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

  Stream<QuerySnapshot> _getBookingsStream(String type) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('customer_id', isEqualTo: _customerId)
        .orderBy('created_at', descending: true);

    switch (type) {
      case 'active':
        return query.where('status',
            whereIn: ['requested', 'accepted', 'in_progress']).snapshots();
      case 'completed':
        return query.where('status', isEqualTo: 'completed').snapshots();
      case 'cancelled':
        return query
            .where('status', whereIn: ['cancelled', 'declined']).snapshots();
      default:
        return query.snapshots();
    }
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              BookingModel booking = BookingModel.fromFirestore(doc);
              return _buildBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String message;

    switch (type) {
      case 'active':
        icon = Icons.event_available;
        message = 'No active bookings';
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        message = 'No completed bookings yet';
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        message = 'No cancelled bookings';
        break;
      default:
        icon = Icons.calendar_today;
        message = 'No bookings yet';
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
            type == 'all'
                ? 'Your service bookings will appear here'
                : 'Your $type bookings will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          booking.subService.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),

              SizedBox(height: 12),

              // Worker info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      booking.workerName.isNotEmpty
                          ? booking.workerName[0].toUpperCase()
                          : 'W',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.workerName.isNotEmpty
                              ? booking.workerName
                              : 'Worker not assigned',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ID: ${booking.bookingId.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),

              // Quick info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(booking.scheduledDate),
                  ),
                  _buildInfoChip(
                    Icons.access_time,
                    booking.scheduledTime,
                  ),
                  _buildInfoChip(
                    Icons.priority_high,
                    booking.urgency,
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Action buttons
              _buildActionButtons(booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    switch (booking.status) {
      case BookingStatus.requested:
        buttons.add(
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
        );
        buttons.add(SizedBox(width: 8));
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _contactWorker(booking),
              icon: Icon(Icons.phone, size: 18),
              label: Text('Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
        );
        break;

      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _contactWorker(booking),
              icon: Icon(Icons.phone, size: 18),
              label: Text('Contact Worker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        );
        break;

      case BookingStatus.completed:
        if (booking.customerRating == null) {
          buttons.add(
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _rateService(booking),
                icon: Icon(Icons.star, size: 18),
                label: Text('Rate Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9800),
                ),
              ),
            ),
          );
        } else {
          buttons.add(
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 18, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Rated: ${booking.customerRating!.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        break;

      case BookingStatus.declined:
        buttons.add(
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Worker Declined',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
          ),
        );
        break;

      default:
        break;
    }

    if (buttons.isEmpty) return SizedBox();

    return Row(children: buttons);
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
              _buildDetailSection('Service Information', [
                _buildDetailRow(
                    'Service Type', booking.serviceType.replaceAll('_', ' ')),
                _buildDetailRow(
                    'Sub Service', booking.subService.replaceAll('_', ' ')),
                _buildDetailRow(
                    'Issue Type', booking.issueType.replaceAll('_', ' ')),
              ]),
              _buildDetailSection('Worker Information', [
                _buildDetailRow('Worker Name', booking.workerName),
                _buildDetailRow('Worker Phone', booking.workerPhone),
              ]),
              _buildDetailSection('Schedule', [
                _buildDetailRow('Date', _formatDate(booking.scheduledDate)),
                _buildDetailRow('Time', booking.scheduledTime),
                _buildDetailRow('Urgency', booking.urgency),
              ]),
              _buildDetailSection('Location', [
                _buildDetailRow('Area', booking.location.replaceAll('_', ' ')),
                _buildDetailRow('Address', booking.address),
              ]),
              _buildDetailSection('Budget', [
                _buildDetailRow('Budget Range', booking.budgetRange),
                if (booking.finalPrice != null)
                  _buildDetailRow('Final Price',
                      'LKR ${booking.finalPrice!.toStringAsFixed(2)}'),
              ]),
              if (booking.problemDescription.isNotEmpty) ...[
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
              ],
              if (booking.status == BookingStatus.completed &&
                  booking.customerRating != null) ...[
                SizedBox(height: 16),
                Text(
                  'Your Rating',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(
                        5,
                        (index) => Icon(
                              Icons.star,
                              color: index < booking.customerRating!
                                  ? Colors.amber
                                  : Colors.grey[300],
                              size: 24,
                            )),
                    SizedBox(width: 8),
                    Text(
                      booking.customerRating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (booking.customerReview != null &&
                    booking.customerReview!.isNotEmpty) ...[
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
              SizedBox(height: 20),
              _buildActionButtons(booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _contactWorker(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${booking.workerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.workerPhone,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'You can call or message the worker to discuss your service requirements.',
              style: TextStyle(color: Colors.grey[600]),
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

  void _cancelBooking(BookingModel booking) {
    String? cancellationReason;

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
              decoration: InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => cancellationReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCancelBooking(booking.bookingId,
                  cancellationReason ?? 'Customer cancelled');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelBooking(String bookingId, String reason) async {
    try {
      await BookingService.cancelBooking(bookingId, reason);
      _showSuccessSnackBar('Booking cancelled successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to cancel booking: ${e.toString()}');
    }
  }

  void _rateService(BookingModel booking) {
    double rating = 5.0;
    String review = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rate Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How was your experience with ${booking.workerName}?'),
                SizedBox(height: 16),
                Text('Rating:'),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          rating = (index + 1).toDouble();
                        });
                      },
                      child: Icon(
                        Icons.star,
                        size: 40,
                        color: index < rating ? Colors.amber : Colors.grey[300],
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Review (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Share your experience...',
                  ),
                  maxLines: 3,
                  onChanged: (value) => review = value,
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
              onPressed: () async {
                Navigator.pop(context);
                await _submitRating(booking.bookingId, rating, review);
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(
      String bookingId, double rating, String review) async {
    try {
      await BookingService.addRating(
        bookingId: bookingId,
        rating: rating,
        review: review,
        isCustomerRating: true,
      );
      _showSuccessSnackBar('Rating submitted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to submit rating: ${e.toString()}');
    }
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
