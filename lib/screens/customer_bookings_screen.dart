// lib/screens/customer_bookings_screen.dart
// MINIMAL MODIFICATION - Only removed Pending filter and added Cancelled filter
// All original interface preserved

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'booking_detail_customer_screen.dart';
import 'worker_profile_view_screen.dart';
import 'customer_quotes_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomerId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.bookingId)
          .delete();

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

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Bookings'),
            Tab(text: 'Quotes'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBookingsTab(),
            CustomerQuotesScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ONLY CHANGE: Removed 'requested' filter, added 'declined' filter
                _buildFilterChip('all', 'All', Icons.all_inclusive),
                SizedBox(width: 8),
                _buildFilterChip(
                    'accepted', 'Accepted', Icons.check_circle_outline),
                SizedBox(width: 8),
                _buildFilterChip(
                    'in_progress', 'In Progress', Icons.work_outline),
                SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed', Icons.done_all),
                SizedBox(width: 8),
                _buildFilterChip('declined', 'Cancelled', Icons.cancel), // NEW
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _customerId == null
                ? null
                : FirebaseFirestore.instance
                    .collection('bookings')
                    .where('customer_id', isEqualTo: _customerId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              List<BookingModel> allBookings = snapshot.data!.docs
                  .map((doc) => BookingModel.fromFirestore(doc))
                  .toList();

              allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              List<BookingModel> filteredBookings;
              if (_selectedFilter == 'all') {
                filteredBookings = allBookings;
              } else {
                filteredBookings = allBookings
                    .where((booking) =>
                        booking.status.toString().split('.').last ==
                        _selectedFilter)
                    .toList();
              }

              if (filteredBookings.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filteredBookings.length,
                itemBuilder: (context, index) =>
                    _buildBookingCard(filteredBookings[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blue),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blue,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
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

  // ORIGINAL BOOKING CARD - INTERFACE PRESERVED
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
                            ? Colors.red
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.urgency.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('workers')
                        .where('worker_id', isEqualTo: booking.workerId)
                        .limit(1)
                        .get()
                        .then((snapshot) => snapshot.docs.first),
                    builder: (context, workerSnapshot) {
                      String? profileUrl;
                      if (workerSnapshot.hasData) {
                        Map<String, dynamic>? data = workerSnapshot.data?.data()
                            as Map<String, dynamic>?;
                        profileUrl = data?['profile_picture_url'];
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
              // ADDED: Show message for declined bookings
              if (booking.status == BookingStatus.declined) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Worker declined this booking',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showWorkerProfile(booking.workerId),
                      icon: Icon(Icons.person, size: 18),
                      label: Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingDetailCustomerScreen(booking: booking),
                          ),
                        );
                      },
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (booking.status == BookingStatus.requested) ...[
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteBooking(booking),
                    icon: Icon(Icons.cancel, size: 18),
                    label: Text('Cancel Booking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.green;
      case BookingStatus.declined:
        return Colors.red;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.requested:
        return 'PENDING';
      case BookingStatus.accepted:
        return 'ACCEPTED';
      case BookingStatus.declined:
        return 'DECLINED';
      case BookingStatus.inProgress:
        return 'IN PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }
}
