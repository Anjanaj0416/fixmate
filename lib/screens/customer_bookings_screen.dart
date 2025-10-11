// lib/screens/customer_bookings_screen.dart
// MODIFIED VERSION - Added ONLY gradient background (white → light blue)
// All original functionality preserved exactly as-is
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'booking_detail_customer_screen.dart';
import 'worker_profile_view_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  String _selectedFilter = 'all';
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        setState(() {
          _customerId =
              (customerDoc.data() as Map<String, dynamic>)['customer_id'] ??
                  user.uid;
        });
      }
    }
  }

  // Delete booking function
  Future<void> _deleteBooking(BookingModel booking) async {
    if (booking.status != BookingStatus.requested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only cancel pending bookings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Delete the booking
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.bookingId)
          .delete();

      // Send notification to worker
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipient_id': booking.workerId,
        'recipient_type': 'worker',
        'worker_id': booking.workerId,
        'type': 'booking_cancelled',
        'title': 'Booking Cancelled',
        'message':
            '${booking.customerName} has cancelled a ${booking.serviceType} booking request',
        'booking_id': booking.bookingId,
        'created_at': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Close loading
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Container(
          // 🎨 GRADIENT BACKGROUND ADDED
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFE3F2FD), // Soft light blue
              ],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        // 🎨 GRADIENT BACKGROUND ADDED
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFE3F2FD), // Soft light blue
            ],
          ),
        ),
        child: Column(
          children: [
            // Filter Tabs
            Container(
              color: Colors.grey[100],
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All', Icons.list),
                    _buildFilterChip('requested', 'Requested', Icons.schedule),
                    _buildFilterChip(
                        'accepted', 'Accepted', Icons.check_circle),
                    _buildFilterChip('in_progress', 'In Progress', Icons.work),
                    _buildFilterChip('completed', 'Completed', Icons.done_all),
                  ],
                ),
              ),
            ),

            // Bookings List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getBookingsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading bookings: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  List<BookingModel> bookings = snapshot.data!.docs
                      .map((doc) => BookingModel.fromFirestore(doc))
                      .toList();

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(bookings[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
            SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('customer_id', isEqualTo: _customerId);

    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.orderBy('created_at', descending: true).snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No bookings yet'
                : 'No ${_selectedFilter} bookings',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Book a service to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showWorkerProfile(String workerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerProfileViewScreen(workerId: workerId),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingDetailCustomerScreen(booking: booking),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (booking.urgency.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.urgency.toLowerCase() == 'urgent'
                            ? Colors.red[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.urgency.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: booking.urgency.toLowerCase() == 'urgent'
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),

              // Worker Info
              Row(
                children: [
                  // Worker Profile Photo
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('workers')
                        .doc(booking.workerId)
                        .get(),
                    builder: (context, snapshot) {
                      String? profileUrl;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        profileUrl = data?['profilePictureUrl'] ??
                            data?['profile_picture_url'];
                      }

                      return GestureDetector(
                        onTap: () => _showWorkerProfile(booking.workerId),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue[100],
                          backgroundImage: profileUrl != null
                              ? NetworkImage(profileUrl)
                              : null,
                          child: profileUrl == null
                              ? Icon(Icons.person, color: Colors.blue)
                              : null,
                        ),
                      );
                    },
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.workerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          booking.serviceType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (booking.issueType.isNotEmpty)
                          Text(
                            booking.issueType,
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

              // Problem Description
              if (booking.problemDescription.isNotEmpty) ...[
                Text(
                  booking.problemDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
              ],

              // Location and Schedule
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    booking.location,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    '${booking.scheduledDate.toString().split(' ')[0]} ${booking.scheduledTime}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),

              // Budget Range
              if (booking.budgetRange.isNotEmpty) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.payments, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Budget: ${booking.budgetRange}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],

              // Action buttons at bottom
              SizedBox(height: 12),
              Row(
                children: [
                  // View Worker Profile Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showWorkerProfile(booking.workerId),
                      icon: Icon(Icons.person, size: 18),
                      label: Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),

                  // Show delete button only for requested bookings
                  if (booking.status == BookingStatus.requested) ...[
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteBooking(booking),
                        icon: Icon(Icons.delete, size: 18),
                        label: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
        return Colors.red;
      case BookingStatus.declined:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.declined:
        return 'Declined';
      default:
        return 'Unknown';
    }
  }
}
