// lib/screens/worker_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class WorkerBookingsScreen extends StatefulWidget {
  @override
  _WorkerBookingsScreenState createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _workerId;

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
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load worker data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_workerId == null) {
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
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New Requests', style: TextStyle(fontSize: 13)),
                  _buildBookingCountBadge('requested'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Accepted', style: TextStyle(fontSize: 13)),
                  _buildBookingCountBadge('accepted'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('In Progress', style: TextStyle(fontSize: 13)),
                  _buildBookingCountBadge('in_progress'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Completed', style: TextStyle(fontSize: 13)),
                  _buildBookingCountBadge('completed'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('All', style: TextStyle(fontSize: 13)),
                  _buildBookingCountBadge('all'),
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
          _buildBookingList('accepted'),
          _buildBookingList('in_progress'),
          _buildBookingList('completed'),
          _buildBookingList('all'),
        ],
      ),
    );
  }

  Widget _buildBookingCountBadge(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        int count = snapshot.data!.docs.length;
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

  Stream<QuerySnapshot> _getBookingsStream(String type) {
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('worker_id', isEqualTo: _workerId)
        .orderBy('created_at', descending: true);

    switch (type) {
      case 'requested':
        return query.where('status', isEqualTo: 'requested').snapshots();
      case 'accepted':
        return query.where('status', isEqualTo: 'accepted').snapshots();
      case 'in_progress':
        return query.where('status', isEqualTo: 'in_progress').snapshots();
      case 'completed':
        return query.where('status', isEqualTo: 'completed').snapshots();
      default:
        return query.snapshots();
    }
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(type);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              BookingModel booking = BookingModel.fromFirestore(doc);
              return _buildBookingCard(booking);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    IconData icon;
    String message;

    switch (type) {
      case 'requested':
        icon = Icons.notifications_none;
        message = 'No new booking requests';
        break;
      case 'accepted':
        icon = Icons.check_circle_outline;
        message = 'No accepted bookings';
        break;
      case 'in_progress':
        icon = Icons.work_outline;
        message = 'No bookings in progress';
        break;
      case 'completed':
        icon = Icons.done_all;
        message = 'No completed bookings yet';
        break;
      default:
        icon = Icons.calendar_today;
        message = 'No bookings yet';
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
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            type == 'requested'
                ? 'New booking requests will appear here'
                : 'Your $type bookings will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with service and urgency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceType
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          booking.subService.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildUrgencyBadge(booking.urgency),
                ],
              ),

              SizedBox(height: 12),

              // Customer info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green[100],
                    child: Text(
                      booking.customerName.isNotEmpty
                          ? booking.customerName[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          booking.customerPhone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

              // Quick info
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.location_on,
                    booking.location.replaceAll('_', ' '),
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(booking.scheduledDate),
                    Colors.purple,
                  ),
                  _buildInfoChip(
                    Icons.access_time,
                    booking.scheduledTime,
                    Colors.orange,
                  ),
                  _buildInfoChip(
                    Icons.attach_money,
                    booking.budgetRange,
                    Colors.green,
                  ),
                ],
              ),

              if (booking.problemDescription.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Problem Description:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        booking.problemDescription,
                        style: TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 12),

              // Action buttons
              _buildActionButtons(booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    IconData icon;

    switch (urgency.toLowerCase()) {
      case 'urgent':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'normal':
        color = Colors.orange;
        icon = Icons.info;
        break;
      default:
        color = Colors.blue;
        icon = Icons.schedule;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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

  Widget _buildActionButtons(BookingModel booking) {
    List<Widget> buttons = [];

    switch (booking.status) {
      case BookingStatus.requested:
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _declineBooking(booking),
              icon: Icon(Icons.close, size: 18),
              label: Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
              ),
            ),
          ),
        );
        buttons.add(SizedBox(width: 8));
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptBooking(booking),
              icon: Icon(Icons.check, size: 18),
              label: Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
        );
        break;

      case BookingStatus.accepted:
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startWork(booking),
              icon: Icon(Icons.play_arrow, size: 18),
              label: Text('Start Work'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        );
        buttons.add(SizedBox(width: 8));
        buttons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _contactCustomer(booking),
              icon: Icon(Icons.phone, size: 18),
              label: Text('Contact'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
        );
        break;

      case BookingStatus.inProgress:
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _completeBooking(booking),
              icon: Icon(Icons.done_all, size: 18),
              label: Text('Mark Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
        );
        break;

      case BookingStatus.completed:
        if (booking.workerRating == null) {
          buttons.add(
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ Service Completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ),
          );
        } else {
          buttons.add(
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 18, color: Colors.amber),
                    SizedBox(width: 4),
                    Text(
                      'Rated: ${booking.workerRating!.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        break;

      default:
        break;
    }

    if (buttons.isEmpty) return SizedBox();

    return Row(children: buttons);
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _buildStatusBadge(booking.status),
                  SizedBox(width: 8),
                  _buildUrgencyBadge(booking.urgency),
                ],
              ),
              SizedBox(height: 20),
              _buildDetailSection('Customer Information', [
                _buildDetailRow('Name', booking.customerName),
                _buildDetailRow('Phone', booking.customerPhone),
                _buildDetailRow('Email', booking.customerEmail),
              ]),
              _buildDetailSection('Service Details', [
                _buildDetailRow(
                    'Service Type', booking.serviceType.replaceAll('_', ' ')),
                _buildDetailRow(
                    'Sub Service', booking.subService.replaceAll('_', ' ')),
                _buildDetailRow(
                    'Issue Type', booking.issueType.replaceAll('_', ' ')),
              ]),
              _buildDetailSection('Schedule', [
                _buildDetailRow('Date', _formatDate(booking.scheduledDate)),
                _buildDetailRow('Time', booking.scheduledTime),
                _buildDetailRow('Urgency', booking.urgency),
              ]),
              _buildDetailSection('Location', [
                _buildDetailRow('Area', booking.location.replaceAll('_', ' ')),
                _buildDetailRow('Address', booking.address),
              ]),
              _buildDetailSection('Budget', [
                _buildDetailRow('Budget Range', booking.budgetRange),
                if (booking.finalPrice != null)
                  _buildDetailRow('Final Price',
                      'LKR ${booking.finalPrice!.toStringAsFixed(2)}'),
              ]),
              if (booking.problemDescription.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Problem Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(booking.problemDescription),
                ),
              ],
              if (booking.problemImageUrls.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Problem Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: booking.problemImageUrls.length,
                    itemBuilder: (context, index) => Container(
                      margin: EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(booking.problemImageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 20),
              _buildActionButtons(booking),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
              Text('Customer: ${booking.customerName}'),
              SizedBox(height: 4),
              Text(
                'Service: ${booking.serviceType.replaceAll('_', ' ')}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Final Price (Optional)',
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
                  hintText: 'Enter price',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Any additional information...',
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
      await BookingService.updateBookingStatus(
        bookingId,
        BookingStatus.accepted,
        finalPrice: price,
      );
      _showSuccessSnackBar('Booking accepted successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to accept booking: ${e.toString()}');
    }
  }

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
      await BookingService.updateBookingStatus(
        bookingId,
        BookingStatus.declined,
        cancellationReason: reason,
      );
      _showSuccessSnackBar('Booking declined');
    } catch (e) {
      _showErrorSnackBar('Failed to decline booking: ${e.toString()}');
    }
  }

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
                  booking.bookingId,
                  BookingStatus.inProgress,
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
                  booking.bookingId,
                  BookingStatus.completed,
                );
                _showSuccessSnackBar('Booking marked as completed!');
              } catch (e) {
                _showErrorSnackBar('Failed: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Mark Complete'),
          ),
        ],
      ),
    );
  }

  void _contactCustomer(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${booking.customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.customerPhone,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.customerEmail,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'You can call or message the customer to discuss service details.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showInfoSnackBar('Opening dialer...');
            },
            icon: Icon(Icons.phone),
            label: Text('Call Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
