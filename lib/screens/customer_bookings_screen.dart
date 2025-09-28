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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      List<BookingModel> bookings =
          await BookingService.getCustomerBookings(currentUserId);

      setState(() {
        _allBookings = bookings;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load bookings: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<BookingModel> _getBookingsByStatus(String status) {
    if (status == 'all') return _allBookings;
    return _allBookings
        .where(
            (booking) => booking.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Color(0xFFFF9800),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${_allBookings.length})'),
            Tab(
                text:
                    'Confirmed (${_getBookingsByStatus('confirmed').length})'),
            Tab(
                text:
                    'In Progress (${_getBookingsByStatus('in_progress').length})'),
            Tab(
                text:
                    'Completed (${_getBookingsByStatus('completed').length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_allBookings, 'all'),
                _buildBookingsList(
                    _getBookingsByStatus('confirmed'), 'confirmed'),
                _buildBookingsList(
                    _getBookingsByStatus('in_progress'), 'in_progress'),
                _buildBookingsList(
                    _getBookingsByStatus('completed'), 'completed'),
              ],
            ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, String status) {
    if (bookings.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'confirmed':
        message = 'No confirmed bookings yet';
        icon = Icons.event_note;
        break;
      case 'in_progress':
        message = 'No ongoing services';
        icon = Icons.work_outline;
        break;
      case 'completed':
        message = 'No completed services';
        icon = Icons.done_all;
        break;
      default:
        message = 'No bookings yet';
        icon = Icons.calendar_today;
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
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your bookings will appear here once you book a service.',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor = _getStatusColor(booking.status);

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booking ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${booking.bookingId}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Worker Info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFFF9800),
                  child: Text(
                    booking.workerDetails?['first_name']
                                ?.toString()
                                .isNotEmpty ==
                            true
                        ? booking.workerDetails!['first_name'][0].toUpperCase()
                        : 'W',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.workerDetails?['worker_name'] ?? 'Worker',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        booking.workerDetails?['business_name'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (booking.workerDetails?['rating'] != null)
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${booking.workerDetails!['rating']}',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Service Details
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, size: 16, color: Color(0xFFFF9800)),
                      SizedBox(width: 8),
                      Text(
                        booking.serviceType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    booking.problemDescription,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Schedule and Price
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            booking.scheduledTime,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'LKR ${booking.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    switch (booking.status.toLowerCase()) {
      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _contactWorker(booking),
                child: Text('Contact Worker'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelBooking(booking),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Cancel'),
              ),
            ),
          ],
        );

      case 'in_progress':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _contactWorker(booking),
                child: Text('Contact Worker'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _markAsCompleted(booking),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Mark Complete'),
              ),
            ),
          ],
        );

      case 'completed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _rateWorker(booking),
                child: Text('Rate Service'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _bookAgain(booking),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800)),
                child: Text('Book Again'),
              ),
            ),
          ],
        );

      default:
        return SizedBox.shrink();
    }
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
                'Worker: ${booking.workerDetails?['worker_name'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            if (booking.workerDetails?['phone_number'] != null) ...[
              Text('Phone: ${booking.workerDetails!['phone_number']}'),
              SizedBox(height: 8),
            ],
            if (booking.workerDetails?['email'] != null) ...[
              Text('Email: ${booking.workerDetails!['email']}'),
              SizedBox(height: 8),
            ],
            Text('You can contact the worker to discuss service details.'),
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

  void _cancelBooking(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BookingService.updateBookingStatus(
                  booking.bookingId!,
                  'cancelled',
                  reason: 'Cancelled by customer',
                );
                _showSuccessSnackBar('Booking cancelled successfully');
                _loadBookings();
              } catch (e) {
                _showErrorSnackBar('Failed to cancel booking: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Completed'),
        content: Text('Mark this service as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BookingService.updateBookingStatus(
                    booking.bookingId!, 'completed');
                _showSuccessSnackBar('Service marked as completed');
                _loadBookings();
              } catch (e) {
                _showErrorSnackBar('Failed to update status: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  void _rateWorker(BookingModel booking) {
    // Implement rating functionality
    _showInfoSnackBar('Rating feature will be implemented soon');
  }

  void _bookAgain(BookingModel booking) {
    // Navigate back to service request with pre-filled data
    _showInfoSnackBar('Book again feature will be implemented soon');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
