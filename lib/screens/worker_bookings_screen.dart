// lib/screens/worker_bookings_screen.dart
// FIXED VERSION - Removed workerId parameter from updateBookingStatus calls

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'worker_quotes_screen.dart';

class WorkerBookingsScreen extends StatefulWidget {
  @override
  _WorkerBookingsScreenState createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _workerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWorkerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (workerDoc.exists) {
          Map<String, dynamic> workerData =
              workerDoc.data() as Map<String, dynamic>;
          setState(() {
            _workerId = workerData['worker_id'];
            _isLoading = false;
          });
          print('✅ Worker loaded: $_workerId');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load worker data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _workerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings'),
          backgroundColor: Color(0xFFFF9800),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFE5CC)],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Quotes'),
            Tab(text: 'Accepted'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFE5CC),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            WorkerQuotesScreen(),
            _buildBookingsList('accepted'),
            _buildBookingsList('in_progress'),
            _buildBookingsList('completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(statusFilter),
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
          return _buildEmptyState(statusFilter);
        }

        List<BookingModel> bookings = snapshot.data!.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();

        bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getBookingsStream(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('worker_id', isEqualTo: _workerId);

    query = query.where('status', isEqualTo: statusFilter);

    return query.snapshots();
  }

  Widget _buildEmptyState(String statusFilter) {
    String title = 'No bookings';
    String subtitle = 'Bookings will appear here';

    switch (statusFilter) {
      case 'accepted':
        title = 'No accepted bookings';
        subtitle = 'Accepted bookings will appear here';
        break;
      case 'in_progress':
        title = 'No ongoing work';
        subtitle = 'Jobs in progress will appear here';
        break;
      case 'completed':
        title = 'No completed bookings';
        subtitle = 'Completed jobs will appear here';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                if (booking.urgency.toLowerCase() == 'urgent')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.red[700]),
                        SizedBox(width: 4),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
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
                        booking.customerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (booking.status == BookingStatus.accepted)
                  TextButton.icon(
                    onPressed: () => _startWork(booking),
                    icon: Icon(Icons.play_arrow, size: 18),
                    label: Text('Start Work'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                if (booking.status == BookingStatus.inProgress)
                  TextButton.icon(
                    onPressed: () => _completeWork(booking),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('Complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewBookingDetails(booking),
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
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
        return 'NEW REQUEST';
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

  // FIXED: Removed workerId parameter
  Future<void> _startWork(BookingModel booking) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Work?'),
        content: Text(
            'Are you ready to start working on ${booking.customerName}\'s request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Start Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // FIXED: Removed workerId parameter
        await BookingService.updateBookingStatus(
          bookingId: booking.bookingId,
          newStatus: BookingStatus.inProgress,
        );
        _showSuccessSnackBar('Work started successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to start work: ${e.toString()}');
      }
    }
  }

  // FIXED: Removed workerId parameter
  Future<void> _completeWork(BookingModel booking) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Work?'),
        content: Text('Have you finished working on this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // FIXED: Removed workerId parameter
        await BookingService.updateBookingStatus(
          bookingId: booking.bookingId,
          newStatus: BookingStatus.completed,
        );
        _showSuccessSnackBar('Booking completed successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to complete booking: ${e.toString()}');
      }
    }
  }

  void _viewBookingDetails(BookingModel booking) {
    _showInfoSnackBar('Booking details: ${booking.bookingId}');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }
}
