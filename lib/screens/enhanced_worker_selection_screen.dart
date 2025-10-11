// lib/screens/customer_bookings_screen.dart
// RESTORED ORIGINAL INTERFACE + Added Quotes as filter chip
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'booking_detail_customer_screen.dart';
import 'worker_profile_view_screen.dart';
import 'customer_quotes_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  String _selectedFilter =
      'all'; // ✅ Can be 'all', 'requested', 'accepted', 'in_progress', 'completed', 'quotes'
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.bookingId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFE3F2FD),
              ],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ✅ RESTORED: Original interface with gradient background
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: Column(
          children: [
            // ✅ RESTORED: Original Filter Chips + Added Quotes chip
            Container(
              color: Colors.grey[100],
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All', Icons.list),
                    _buildFilterChip(
                        'quotes', 'Quotes', Icons.request_quote), // ✅ NEW
                    _buildFilterChip('requested', 'Requested', Icons.schedule),
                    _buildFilterChip(
                        'accepted', 'Accepted', Icons.check_circle),
                    _buildFilterChip('in_progress', 'In Progress', Icons.build),
                    _buildFilterChip('completed', 'Completed', Icons.done_all),
                  ],
                ),
              ),
            ),

            // ✅ Show quotes screen OR bookings list
            Expanded(
              child: _selectedFilter == 'quotes'
                  ? CustomerQuotesScreen() // ✅ NEW: Show quotes screen
                  : _buildBookingsList(), // ✅ ORIGINAL: Show bookings
            ),
          ],
        ),
      ),
    );
  }

  // ✅ RESTORED: Original bookings list
  Widget _buildBookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(),
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
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        List<BookingModel> bookings = snapshot.data!.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();

        // Filter bookings based on selected filter
        if (_selectedFilter != 'all') {
          bookings = bookings.where((booking) {
            return booking.status.toString().split('.').last == _selectedFilter;
          }).toList();
        }

        if (bookings.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index]);
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.blue),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.blue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customer_id', isEqualTo: _customerId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Start by requesting a service'
                : 'No ${_selectedFilter.replaceAll('_', ' ')} bookings',
            style: TextStyle(color: Colors.grey[600]),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BookingDetailCustomerScreen(booking: booking),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Worker name and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.workerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),

              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),

              // Service details
              Row(
                children: [
                  Icon(Icons.build, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.serviceType.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Issue type
              Row(
                children: [
                  Icon(Icons.description, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.issueType.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Budget
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.blue),
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

  Widget _buildStatusBadge(BookingStatus status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case BookingStatus.requested:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        statusText = 'Requested';
        break;
      case BookingStatus.accepted:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        statusText = 'Accepted';
        break;
      case BookingStatus.inProgress:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case BookingStatus.completed:
        backgroundColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        statusText = 'Completed';
        break;
      case BookingStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case BookingStatus.declined:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        statusText = 'Declined';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
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
}
