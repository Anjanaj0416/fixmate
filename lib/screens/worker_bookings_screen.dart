// lib/screens/worker_bookings_screen.dart
// MODIFIED VERSION - Added Quotes Tab

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'worker_quotes_screen.dart'; // ✅ Import quotes screen

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
    _tabController =
        TabController(length: 6, vsync: this); // ✅ Changed from 5 to 6 tabs
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
              colors: [
                Colors.white,
                Color(0xFFFFE5CC),
              ],
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings & Quotes'), // ✅ Updated title
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Quotes'), // ✅ NEW: First tab for quotes
            Tab(text: 'New Requests'),
            Tab(text: 'Accepted'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
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
            WorkerQuotesScreen(), // ✅ NEW: Quotes tab
            _buildBookingsList('requested'),
            _buildBookingsList('accepted'),
            _buildBookingsList('in_progress'),
            _buildBookingsList('completed'),
            _buildBookingsList('all'),
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

  Stream<QuerySnapshot> _getBookingsStream(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('worker_id', isEqualTo: _workerId)
        .orderBy('created_at', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots();
  }

  Widget _buildEmptyState(String statusFilter) {
    String message;
    switch (statusFilter) {
      case 'requested':
        message = 'No new booking requests';
        break;
      case 'accepted':
        message = 'No accepted bookings';
        break;
      case 'in_progress':
        message = 'No bookings in progress';
        break;
      case 'completed':
        message = 'No completed bookings';
        break;
      default:
        message = 'No bookings yet';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Bookings will appear here',
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.customerPhone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),

            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),

            // Service details
            _buildDetailRow(Icons.build, 'Service',
                booking.serviceType.replaceAll('_', ' ')),
            _buildDetailRow(Icons.description, 'Issue',
                booking.issueType.replaceAll('_', ' ')),
            _buildDetailRow(Icons.location_on, 'Location',
                booking.location.replaceAll('_', ' ')),
            _buildDetailRow(Icons.access_time, 'Urgency', booking.urgency),

            // Action buttons
            if (booking.status == BookingStatus.requested) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDeclineBooking(booking),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAcceptBooking(booking),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (booking.status == BookingStatus.accepted) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleStartWork(booking),
                  icon: Icon(Icons.play_arrow, size: 18),
                  label: Text('Start Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            if (booking.status == BookingStatus.inProgress) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleCompleteWork(booking),
                  icon: Icon(Icons.check_circle, size: 18),
                  label: Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            // Chat button for all active bookings
            if (booking.status != BookingStatus.cancelled &&
                booking.status != BookingStatus.declined) ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(booking),
                  icon: Icon(Icons.chat, size: 18),
                  label: Text('Chat with Customer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ],
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
        statusText = 'New';
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptBooking(BookingModel booking) async {
    try {
      await BookingService.updateBookingStatus(
        bookingId: booking.bookingId,
        newStatus: BookingStatus.accepted,
      );
      _showSuccessSnackBar('Booking accepted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to accept booking: ${e.toString()}');
    }
  }

  Future<void> _handleDeclineBooking(BookingModel booking) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Booking'),
        content: Text('Are you sure you want to decline this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BookingService.updateBookingStatus(
          bookingId: booking.bookingId,
          newStatus: BookingStatus.declined,
        );
        _showSuccessSnackBar('Booking declined');
      } catch (e) {
        _showErrorSnackBar('Failed to decline booking: ${e.toString()}');
      }
    }
  }

  Future<void> _handleStartWork(BookingModel booking) async {
    try {
      await BookingService.updateBookingStatus(
        bookingId: booking.bookingId,
        newStatus: BookingStatus.inProgress,
      );
      _showSuccessSnackBar('Work started');
    } catch (e) {
      _showErrorSnackBar('Failed to start work: ${e.toString()}');
    }
  }

  Future<void> _handleCompleteWork(BookingModel booking) async {
    try {
      await BookingService.updateBookingStatus(
        bookingId: booking.bookingId,
        newStatus: BookingStatus.completed,
      );
      _showSuccessSnackBar('Work completed successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to complete work: ${e.toString()}');
    }
  }

  Future<void> _openChat(BookingModel booking) async {
    try {
      String chatId = await ChatService.createOrGetChatRoom(
        bookingId: booking.bookingId,
        customerId: booking.customerId,
        customerName: booking.customerName,
        workerId: booking.workerId,
        workerName: booking.workerName,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
                  chatId: chatId,
                  bookingId: booking.bookingId,
                  otherUserName: booking.customerName,
                  currentUserType: 'worker',
                )),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open chat: ${e.toString()}');
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
        duration: Duration(seconds: 5),
      ),
    );
  }
}
