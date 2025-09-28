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
  List<BookingModel> _allBookings = [];
  List<BookingModel> _activeBookings = [];
  List<BookingModel> _completedBookings = [];
  List<BookingModel> _cancelledBookings = [];
  bool _isLoading = true;
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
          _customerId = customerData['customer_id'];
          await _loadBookings();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load customer data: ${e.toString()}');
    }
  }

  Future<void> _loadBookings() async {
    if (_customerId == null) return;

    try {
      setState(() => _isLoading = true);

      List<BookingModel> bookings =
          await BookingService.getCustomerBookings(_customerId!);

      setState(() {
        _allBookings = bookings;
        _activeBookings = bookings
            .where((b) =>
                b.status == BookingStatus.requested ||
                b.status == BookingStatus.accepted ||
                b.status == BookingStatus.inProgress)
            .toList();
        _completedBookings =
            bookings.where((b) => b.status == BookingStatus.completed).toList();
        _cancelledBookings = bookings
            .where((b) =>
                b.status == BookingStatus.cancelled ||
                b.status == BookingStatus.declined)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load bookings: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Column(
                children: [
                  Text('All'),
                  Text('(${_allBookings.length})',
                      style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Column(
                children: [
                  Text('Active'),
                  Text('(${_activeBookings.length})',
                      style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Column(
                children: [
                  Text('Completed'),
                  Text('(${_completedBookings.length})',
                      style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Column(
                children: [
                  Text('Cancelled'),
                  Text('(${_cancelledBookings.length})',
                      style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(_allBookings, 'all'),
                  _buildBookingsList(_activeBookings, 'active'),
                  _buildBookingsList(_completedBookings, 'completed'),
                  _buildBookingsList(_cancelledBookings, 'cancelled'),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, String type) {
    if (bookings.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'active':
        message = 'No active bookings';
        icon = Icons.schedule;
        break;
      case 'completed':
        message = 'No completed bookings';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled bookings';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No bookings yet';
        icon = Icons.calendar_today_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
                        booking.serviceType.replaceAll('_', ' ').toUpperCase(),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: booking.status.color.withOpacity(0.3)),
                  ),
                  child: Text(
                    booking.status.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: booking.status.color,
                    ),
                  ),
                ),
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
                        'Booking ID: ${booking.bookingId}',
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

            // Service details
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      'Issue Type', booking.issueType.replaceAll('_', ' ')),
                  _buildDetailRow(
                      'Location', booking.location.replaceAll('_', ' ')),
                  _buildDetailRow('Urgency', booking.urgency),
                  _buildDetailRow('Budget Range', booking.budgetRange),
                  _buildDetailRow(
                      'Scheduled Date', _formatDate(booking.scheduledDate)),
                  _buildDetailRow('Scheduled Time', booking.scheduledTime),
                  if (booking.problemDescription.isNotEmpty)
                    _buildDetailRow('Description', booking.problemDescription),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Bottom info and actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${_formatDateTime(booking.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (booking.finalPrice != null)
                        Text(
                          'Final Price: LKR ${booking.finalPrice!.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildActionButtons(booking),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
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
      case BookingStatus.pending:
        buttons.add(
          OutlinedButton(
            onPressed: () => _cancelBooking(booking),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
        );
        break;

      case BookingStatus.accepted:
      case BookingStatus.inProgress:
        buttons.addAll([
          OutlinedButton(
            onPressed: () => _contactWorker(booking),
            child: Text('Contact', style: TextStyle(fontSize: 12)),
          ),
          SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _cancelBooking(booking),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
            ),
            child: Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
        ]);
        break;

      case BookingStatus.completed:
        if (booking.customerRating == null) {
          buttons.add(
            ElevatedButton(
              onPressed: () => _rateService(booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text(
                'Rate Service',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          );
        } else {
          buttons.add(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.green[700]),
                  SizedBox(width: 4),
                  Text(
                    booking.customerRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        break;

      default:
        break;
    }

    return Row(children: buttons);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
            Text('Phone: ${booking.workerPhone}'),
            SizedBox(height: 8),
            Text(
                'You can call or message the worker to discuss your service requirements.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfoSnackBar('Calling feature coming soon!');
            },
            child: Text('Call'),
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
              await _performCancelBooking(
                  booking.bookingId, cancellationReason ?? '');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Cancel Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelBooking(String bookingId, String reason) async {
    try {
      await BookingService.cancelBooking(bookingId, reason);
      _showSuccessSnackBar('Booking cancelled successfully');
      await _loadBookings();
    } catch (e) {
      _showErrorSnackBar('Failed to cancel booking: ${e.toString()}');
    }
  }

  void _rateService(BookingModel booking) {
    double rating = 5.0;
    String review = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      rating = (index + 1).toDouble();
                      // Force rebuild of dialog
                      Navigator.pop(context);
                      _rateService(booking);
                    },
                    child: Icon(
                      Icons.star,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                      size: 32,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      _showSuccessSnackBar('Thank you for your feedback!');
      await _loadBookings();
    } catch (e) {
      _showErrorSnackBar('Failed to submit rating: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
