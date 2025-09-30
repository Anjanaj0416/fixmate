// lib/screens/updated_customer_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import '../widgets/rating_dialog.dart';

class UpdatedCustomerBookingsScreen extends StatefulWidget {
  const UpdatedCustomerBookingsScreen({Key? key}) : super(key: key);

  @override
  _UpdatedCustomerBookingsScreenState createState() =>
      _UpdatedCustomerBookingsScreenState();
}

class _UpdatedCustomerBookingsScreenState
    extends State<UpdatedCustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      setState(() {
        _customerId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_customerId == null) {
      return Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFFF9800))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Color(0xFFFF9800),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(['requested', 'accepted', 'in_progress']),
          _buildBookingsList(['completed']),
          _buildBookingsList(['cancelled', 'declined']),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<String> statuses) {
    return StreamBuilder<List<BookingModel>>(
      stream: BookingService.getCustomerBookingsStream(_customerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9800)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Failed to load bookings',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<BookingModel> allBookings = snapshot.data ?? [];
        List<BookingModel> filteredBookings = allBookings
            .where((booking) =>
                statuses.contains(booking.status.toString().split('.').last))
            .toList();

        if (filteredBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No bookings found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: Color(0xFFFF9800),
          child: ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildBookingCard(filteredBookings[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with worker info
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFFF9800),
                    child: Text(
                      booking.workerName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          booking.serviceType.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),

              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),

              // Booking details
              _buildDetailRow(Icons.calendar_today,
                  '${_formatDate(booking.scheduledDate)} • ${booking.scheduledTime}'),
              SizedBox(height: 8),
              _buildDetailRow(Icons.location_on, booking.location),

              if (booking.problemDescription.isNotEmpty) ...[
                SizedBox(height: 8),
                _buildDetailRow(
                  Icons.description,
                  booking.problemDescription,
                  maxLines: 2,
                ),
              ],

              if (booking.budgetRange.isNotEmpty) ...[
                SizedBox(height: 8),
                _buildDetailRow(Icons.attach_money, booking.budgetRange),
              ],

              // Rating section for completed bookings
              if (booking.status == BookingStatus.completed) ...[
                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 12),
                _buildRatingSection(booking),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.requested:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BookingStatus.accepted:
        color = Colors.blue;
        text = 'Accepted';
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        break;
      case BookingStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case BookingStatus.declined:
        color = Colors.grey;
        text = 'Declined';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {int? maxLines}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(BookingModel booking) {
    return FutureBuilder<bool>(
      future: ReviewService.hasReviewedBooking(booking.bookingId),
      builder: (context, snapshot) {
        bool hasReviewed = snapshot.data ?? false;

        if (hasReviewed) {
          // Show existing rating
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You rated this service',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                      if (booking.customerRating != null)
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < booking.customerRating!.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show rate button
          return ElevatedButton.icon(
            onPressed: () => _showRatingDialog(booking),
            icon: Icon(Icons.star_border, size: 18),
            label: Text('Rate Worker'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9800),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _showRatingDialog(BookingModel booking) async {
    await showRatingDialog(
      context,
      booking,
      () {
        // Refresh the list after rating
        setState(() {});
      },
    );
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
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20),

                // All booking details here
                _buildDetailsField('Booking ID', booking.bookingId),
                _buildDetailsField('Worker', booking.workerName),
                _buildDetailsField(
                    'Service', booking.serviceType.replaceAll('_', ' ')),
                _buildDetailsField('Date', _formatDate(booking.scheduledDate)),
                _buildDetailsField('Time', booking.scheduledTime),
                _buildDetailsField('Location', booking.location),
                _buildDetailsField('Address', booking.address),
                if (booking.problemDescription.isNotEmpty)
                  _buildDetailsField('Description', booking.problemDescription),
                if (booking.budgetRange.isNotEmpty)
                  _buildDetailsField('Budget', booking.budgetRange),
                _buildDetailsField('Status', booking.status.displayName),
                _buildDetailsField('Created', _formatDate(booking.createdAt)),

                SizedBox(height: 20),

                // Actions
                if (booking.status == BookingStatus.requested ||
                    booking.status == BookingStatus.accepted) ...[
                  ElevatedButton(
                    onPressed: () => _cancelBooking(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancel Booking'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
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
        await BookingService.cancelBooking(
          booking.bookingId,
          'Cancelled by customer',
        );

        Navigator.pop(context); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
