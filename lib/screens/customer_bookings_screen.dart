// lib/screens/customer_bookings_screen.dart
// UPDATED VERSION - Added Rate & Review button for completed bookings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/rating_service.dart';
import '../widgets/rating_dialog.dart';

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

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor = _getStatusColor(booking.status);
    IconData statusIcon = _getStatusIcon(booking.status);

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
                Expanded(
                  child: Text(
                    booking.bookingId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        booking.status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Worker info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFF9800),
                  child: Text(
                    booking.workerName[0].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.workerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        booking.serviceType,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
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
            _buildInfoRow(Icons.calendar_today,
                '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}'),
            SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, booking.scheduledTime),
            SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, booking.location),

            // Show rating if already rated
            if (booking.status == BookingStatus.completed &&
                booking.customerRating != null) ...[
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Your Rating: ${booking.customerRating!.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (booking.customerReview != null &&
                  booking.customerReview!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  booking.customerReview!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],

            // Rate & Review button for completed bookings
            if (booking.status == BookingStatus.completed &&
                booking.customerRating == null) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(booking),
                  icon: Icon(Icons.star_rate, color: Colors.white),
                  label: Text(
                    'Rate & Review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // Action buttons for other statuses
            if (booking.status == BookingStatus.requested) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(booking.bookingId),
                      child: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  void _showRatingDialog(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(booking: booking),
    );

    if (result == true) {
      // Refresh the list after successful rating
      setState(() {});
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BookingService.cancelBooking(bookingId, 'Cancelled by customer');
        _showSuccessSnackBar('Booking cancelled successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to cancel booking: ${e.toString()}');
      }
    }
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
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Icons.schedule;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.build;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
