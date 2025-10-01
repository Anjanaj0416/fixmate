// lib/screens/worker_bookings_screen.dart
// COMPLETE FIXED VERSION - Replace your entire file with this

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'New Requests'),
            Tab(text: 'Accepted'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('requested'),
          _buildBookingsList('accepted'),
          _buildBookingsList('in_progress'),
          _buildBookingsList('completed'),
          _buildBookingsList('all'),
        ],
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

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getBookingsStream(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('worker_id', isEqualTo: _workerId);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.orderBy('created_at', descending: true).snapshots();
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'requested':
        message = 'No new booking requests';
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
        message = 'No bookings found';
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
            type == 'requested'
                ? 'New requests will appear here'
                : 'Bookings will appear here',
            style: TextStyle(color: Colors.grey[400]),
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
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and urgency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(booking.status),
                  if (booking.urgency.isNotEmpty)
                    _buildUrgencyBadge(booking.urgency),
                ],
              ),

              SizedBox(height: 12),

              // Customer info
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (booking.customerPhone.isNotEmpty)
                          Text(
                            booking.customerPhone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
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

              // Service details
              Text(
                booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              SizedBox(height: 4),
              if (booking.issueType.isNotEmpty)
                Text(
                  booking.issueType,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(height: 8),
              Text(
                booking.problemDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Location and schedule
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.location_on,
                    booking.location,
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${_formatDate(booking.scheduledDate)} ${booking.scheduledTime}',
                    Colors.green,
                  ),
                  if (booking.budgetRange.isNotEmpty)
                    _buildInfoChip(
                      Icons.attach_money,
                      booking.budgetRange,
                      Colors.purple,
                    ),
                ],
              ),

              // Action buttons based on status
              if (booking.status == BookingStatus.requested) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _declineBooking(booking),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptBooking(booking),
                        icon: Icon(Icons.check, size: 18),
                        label: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (booking.status == BookingStatus.accepted) ...[
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _startWork(booking),
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 44),
                  ),
                ),
              ],

              if (booking.status == BookingStatus.inProgress) ...[
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _completeBooking(booking),
                  icon: Icon(Icons.done_all),
                  label: Text('Complete Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 44),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color =
        urgency.toLowerCase() == 'urgent' ? Colors.red : Colors.orange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            urgency.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBookingDetails(BookingModel booking) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Customer', booking.customerName),
              _detailRow('Phone', booking.customerPhone),
              _detailRow('Service', booking.serviceType.replaceAll('_', ' ')),
              _detailRow('Issue', booking.issueType),
              _detailRow('Location', booking.location),
              _detailRow('Address', booking.address),
              _detailRow('Date', _formatDate(booking.scheduledDate)),
              _detailRow('Time', booking.scheduledTime),
              _detailRow('Budget', booking.budgetRange),
              _detailRow('Status', booking.status.displayName),
              SizedBox(height: 8),
              Text('Problem Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(booking.problemDescription),

              // NEW: Photo viewing section
              if (booking.problemImageUrls.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${booking.problemImageUrls.length} issue photo${booking.problemImageUrls.length > 1 ? 's' : ''} available',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          _viewIssuePhotos(booking); // Open photo viewer
                        },
                        icon: Icon(Icons.remove_red_eye, size: 18),
                        label: Text('View'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16),

              // Chat Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog first
                    _openChatWithCustomer(booking);
                  },
                  icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                  label: Text(
                    'Chat with ${booking.customerName}',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),

          // Accept/Decline buttons based on status
          if (booking.status == BookingStatus.requested) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _acceptBooking(booking);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Accept'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _declineBooking(booking);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Decline'),
            ),
          ],
        ],
      ),
    );
  }

// NEW METHOD: Add this method to your WorkerBookingsScreen class
  void _viewIssuePhotos(BookingModel booking) {
    if (booking.problemImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No photos available for this booking'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IssuePhotoViewerScreenWorker(
          imageUrls: booking.problemImageUrls,
          problemDescription: booking.problemDescription,
          customerName: booking.customerName,
        ),
      ),
    );
  }

// ADD this new method to your worker_bookings_screen.dart file:
  Future<void> _openChatWithCustomer(BookingModel booking) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Create or get chat room
      String chatId = await ChatService.createOrGetChatRoom(
        bookingId: booking.bookingId,
        customerId: booking.customerId,
        customerName: booking.customerName,
        workerId: booking.workerId,
        workerName: booking.workerName,
      );

      // Close loading
      Navigator.pop(context);

      // Open chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            bookingId: booking.bookingId,
            otherUserName: booking.customerName,
            currentUserType: 'worker',
          ),
        ),
      );
    } catch (e) {
      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'N/A' : value),
          ),
        ],
      ),
    );
  }

  // ==================== ACCEPT BOOKING ====================
  void _acceptBooking(BookingModel booking) {
    TextEditingController priceController = TextEditingController();
    TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accept booking from ${booking.customerName}?'),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Final Price (Optional)',
                  border: OutlineInputBorder(),
                  prefixText: 'LKR ',
                  hintText: 'Enter agreed price',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add any notes for the customer',
                ),
                maxLines: 2,
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

              double? finalPrice;
              if (priceController.text.isNotEmpty) {
                finalPrice = double.tryParse(priceController.text);
              }

              await _performAcceptBooking(
                booking.bookingId,
                finalPrice,
                notesController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Accept Booking'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAcceptBooking(
      String bookingId, double? price, String notes) async {
    try {
      print('🔄 Accepting booking: $bookingId');

      await BookingService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.accepted,
        finalPrice: price,
        notes: notes.isNotEmpty ? notes : null,
      );

      print('✅ Booking accepted successfully');
      _showSuccessSnackBar('Booking accepted successfully!');
    } catch (e) {
      print('❌ Failed to accept booking: $e');
      _showErrorSnackBar('Failed to accept booking: ${e.toString()}');
    }
  }

  // ==================== DECLINE BOOKING ====================
  void _declineBooking(BookingModel booking) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to decline this booking request?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Let the customer know why...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeclineBooking(
                booking.bookingId,
                reasonController.text.isNotEmpty
                    ? reasonController.text
                    : 'Worker declined the request',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeclineBooking(String bookingId, String reason) async {
    try {
      print('🔄 Declining booking: $bookingId');

      // CRITICAL: Use 'declined' status with reason
      await BookingService.updateBookingStatus(
        bookingId: bookingId,
        newStatus: BookingStatus.declined,
        notes: reason,
      );

      print('✅ Booking declined successfully');
      _showSuccessSnackBar('Booking declined');
    } catch (e) {
      print('❌ Failed to decline booking: $e');
      _showErrorSnackBar('Failed to decline booking: ${e.toString()}');
    }
  }

  // ==================== START WORK ====================
  void _startWork(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Work'),
        content: Text('Are you ready to start working on this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await BookingService.updateBookingStatus(
                  bookingId: booking.bookingId,
                  newStatus: BookingStatus.inProgress,
                );
                _showSuccessSnackBar('Work started!');
              } catch (e) {
                _showErrorSnackBar('Failed: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Start Work'),
          ),
        ],
      ),
    );
  }

  // ==================== COMPLETE WORK ====================
  void _completeBooking(BookingModel booking) {
    TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark this booking as completed?'),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Work Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Summary of work done...',
              ),
              maxLines: 3,
            ),
          ],
        ),
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
                  bookingId: booking.bookingId,
                  newStatus: BookingStatus.completed,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );
                _showSuccessSnackBar('Booking marked as completed!');
              } catch (e) {
                _showErrorSnackBar('Failed: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  // ==================== SNACKBAR HELPERS ====================
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// COMPLETE CLASS - Add this at the end of worker_bookings_screen.dart
// Replace the incomplete IssuePhotoViewerScreenWorker class

class IssuePhotoViewerScreenWorker extends StatefulWidget {
  final List<String> imageUrls;
  final String problemDescription;
  final String customerName;

  const IssuePhotoViewerScreenWorker({
    Key? key,
    required this.imageUrls,
    required this.problemDescription,
    required this.customerName,
  }) : super(key: key);

  @override
  State<IssuePhotoViewerScreenWorker> createState() =>
      _IssuePhotoViewerScreenWorkerState();
}

class _IssuePhotoViewerScreenWorkerState
    extends State<IssuePhotoViewerScreenWorker> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Issue Photos (${_currentImageIndex + 1}/${widget.imageUrls.length})',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Customer info banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(color: Colors.orange.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Customer: ${widget.customerName}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Image viewer with zoom
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.orange,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.white, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Problem description at bottom
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Problem Description:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.problemDescription,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Image navigation dots (if multiple images)
          if (widget.imageUrls.length > 1)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.orange
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
