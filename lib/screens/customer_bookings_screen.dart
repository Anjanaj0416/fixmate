// lib/screens/customer_bookings_screen.dart
// NEW FILE - Customer bookings list with chat access
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'booking_detail_customer_screen.dart';
import '../utils/string_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
                  _buildFilterChip('accepted', 'Accepted', Icons.check_circle),
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.workerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          booking.serviceType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${_formatDate(booking.scheduledDate)} at ${booking.scheduledTime}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.budgetRange,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'ID: ${StringUtils.formatBookingId(booking.bookingId)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case BookingStatus.requested:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case BookingStatus.accepted:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case BookingStatus.inProgress:
        color = Colors.blue;
        icon = Icons.work;
        break;
      case BookingStatus.completed:
        color = Colors.teal;
        icon = Icons.done_all;
        break;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 'requested':
        message = 'No pending requests';
        icon = Icons.inbox_outlined;
        break;
      case 'accepted':
        message = 'No accepted bookings';
        icon = Icons.check_circle_outline;
        break;
      case 'in_progress':
        message = 'No jobs in progress';
        icon = Icons.work_outline;
        break;
      case 'completed':
        message = 'No completed bookings';
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
          Icon(icon, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Start by booking a service'
                : 'Check other tabs for bookings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
