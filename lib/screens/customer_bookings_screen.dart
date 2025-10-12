// lib/screens/customer_bookings_screen.dart
// ABSOLUTE MINIMAL CHANGE - Only removed "All" filter chip
// Everything else is 100% preserved

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
  String _selectedFilter =
      'accepted'; // CHANGED: default to 'accepted' instead of 'all'
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
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
          .update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
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
                // ONLY CHANGE: Removed 'all' filter chip
                _buildFilterChip(
                    'accepted', 'Accepted', Icons.check_circle_outline),
                SizedBox(width: 8),
                _buildFilterChip(
                    'in_progress', 'In Progress', Icons.work_outline),
                SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed', Icons.done_all),
                SizedBox(width: 8),
                _buildFilterChip('declined', 'Cancelled', Icons.cancel),
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

              // Filter bookings based on selected filter
              List<BookingModel> filteredBookings = allBookings
                  .where((booking) =>
                      booking.status.toString().split('.').last ==
                      _selectedFilter)
                  .toList();

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
            'No ${_selectedFilter} bookings',
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
                          color: booking.urgency.toLowerCase() == 'urgent'
                              ? Colors.red[700]
                              : Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              InkWell(
                onTap: () => _showWorkerProfile(booking.workerId),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.person, color: Colors.blue),
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
                            booking.serviceType
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.room, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    booking.scheduledTime,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              if (booking.finalPrice != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.green),
                    Text(
                      'LKR ${booking.finalPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.budgetRange.isNotEmpty &&
                  booking.finalPrice == null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Budget: ${booking.budgetRange}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (booking.status == BookingStatus.requested) ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _deleteBooking(booking),
                      icon: Icon(Icons.cancel, color: Colors.red, size: 18),
                      label: Text(
                        'Cancel Booking',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
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
        return 'PENDING';
      case BookingStatus.accepted:
        return 'ACCEPTED';
      case BookingStatus.inProgress:
        return 'IN PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.declined:
        return 'DECLINED';
      default:
        return 'UNKNOWN';
    }
  }
}
