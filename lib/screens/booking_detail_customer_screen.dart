// lib/screens/booking_detail_customer_screen.dart
// New file - Customer view of booking with chat option
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../utils/string_utils.dart';

class BookingDetailCustomerScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailCustomerScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  Future<void> _openChat(BuildContext context) async {
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
            otherUserName: booking.workerName,
            currentUserType: 'customer',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(booking.status),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(booking.status), color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            booking.status.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Worker Details Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Worker Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _detailRow('Name', booking.workerName),
                    _detailRow('Phone', booking.workerPhone),
                    _detailRow(
                        'Service', booking.serviceType.replaceAll('_', ' ')),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Booking Information Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _detailRow('Booking ID',
                        StringUtils.formatBookingId(booking.bookingId)),
                    _detailRow('Location', booking.location),
                    _detailRow('Address', booking.address),
                    _detailRow('Date', _formatDate(booking.scheduledDate)),
                    _detailRow('Time', booking.scheduledTime),
                    _detailRow('Budget', booking.budgetRange),
                    _detailRow('Urgency', booking.urgency.toUpperCase()),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Problem Description Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problem Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    Text(booking.problemDescription),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Chat Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: Text(
                  'Chat with ${booking.workerName}',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.teal;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Icons.schedule;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.work;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
