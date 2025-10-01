// lib/screens/booking_detail_customer_screen.dart
// FIXED VERSION - Added Rate & Review button for completed bookings
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/chat_service.dart';
import '../widgets/rating_dialog.dart';
import 'chat_screen.dart';
import '../utils/string_utils.dart';

class BookingDetailCustomerScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailCustomerScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<BookingDetailCustomerScreen> createState() =>
      _BookingDetailCustomerScreenState();
}

class _BookingDetailCustomerScreenState
    extends State<BookingDetailCustomerScreen> {
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
        bookingId: widget.booking.bookingId,
        customerId: widget.booking.customerId,
        customerName: widget.booking.customerName,
        workerId: widget.booking.workerId,
        workerName: widget.booking.workerName,
      );

      // Close loading
      Navigator.pop(context);

      // Open chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            bookingId: widget.booking.bookingId,
            otherUserName: widget.booking.workerName,
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

  // NEW METHOD: View issue photos
  void _viewIssuePhotos(BuildContext context) {
    if (widget.booking.problemImageUrls.isEmpty) {
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
        builder: (context) => IssuePhotoViewerScreenCustomer(
          imageUrls: widget.booking.problemImageUrls,
          problemDescription: widget.booking.problemDescription,
          workerName: widget.booking.workerName,
        ),
      ),
    );
  }

  // CRITICAL FIX: Add this method to open rating dialog
  Future<void> _openRatingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(booking: widget.booking),
    );

    if (result == true) {
      // Rating submitted successfully, refresh the screen
      setState(() {
        // This will rebuild the widget and reflect the updated rating status
      });

      // Optionally navigate back to refresh the bookings list
      Navigator.pop(context);
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
              color: _getStatusColor(widget.booking.status),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(widget.booking.status),
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.booking.status.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
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

            // Worker Information Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Worker Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _detailRow('Name', widget.booking.workerName),
                    _detailRow('Phone', widget.booking.workerPhone),
                    _detailRow('Service',
                        widget.booking.serviceType.replaceAll('_', ' ')),
                    if (widget.booking.workerRating != null &&
                        widget.booking.workerRating! > 0)
                      _detailRow('Rating',
                          '${widget.booking.workerRating!.toStringAsFixed(1)} ⭐'),
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
                        StringUtils.formatBookingId(widget.booking.bookingId)),
                    _detailRow('Location', widget.booking.location),
                    _detailRow('Address', widget.booking.address),
                    _detailRow(
                        'Date', _formatDate(widget.booking.scheduledDate)),
                    _detailRow('Time', widget.booking.scheduledTime),
                    _detailRow('Budget', widget.booking.budgetRange),
                    _detailRow('Urgency', widget.booking.urgency),
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
                    Text(
                      widget.booking.problemDescription.isEmpty
                          ? 'No description provided'
                          : widget.booking.problemDescription,
                      style: TextStyle(fontSize: 15),
                    ),
                    if (widget.booking.problemImageUrls.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.booking.problemImageUrls.length} photo${widget.booking.problemImageUrls.length > 1 ? 's' : ''} attached',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _viewIssuePhotos(context),
                              icon: Icon(Icons.remove_red_eye, size: 18),
                              label: Text('View'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // CRITICAL FIX: Add Rate & Review button for completed bookings
            if (widget.booking.status == BookingStatus.completed &&
                widget.booking.customerRating == null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _openRatingDialog,
                  icon: Icon(Icons.star, color: Colors.white),
                  label: Text(
                    'Rate & Review',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // Show rating if already submitted
            if (widget.booking.status == BookingStatus.completed &&
                widget.booking.customerRating != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Your Rating: ${widget.booking.customerRating!.toStringAsFixed(1)} ⭐',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    if (widget.booking.customerReview != null &&
                        widget.booking.customerReview!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Your Review:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.booking.customerReview!,
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ],
                  ],
                ),
              ),

            // Add some spacing if rate button exists
            if (widget.booking.status == BookingStatus.completed)
              SizedBox(height: 16),

            // Chat Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: Text(
                  'Chat with ${widget.booking.workerName}',
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

// Photo viewer screen
class IssuePhotoViewerScreenCustomer extends StatefulWidget {
  final List<String> imageUrls;
  final String problemDescription;
  final String workerName;

  const IssuePhotoViewerScreenCustomer({
    Key? key,
    required this.imageUrls,
    required this.problemDescription,
    required this.workerName,
  }) : super(key: key);

  @override
  State<IssuePhotoViewerScreenCustomer> createState() =>
      _IssuePhotoViewerScreenCustomerState();
}

class _IssuePhotoViewerScreenCustomerState
    extends State<IssuePhotoViewerScreenCustomer> {
  late PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

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
        title: Text('Issue Photos'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Image viewer with page view
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
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
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
                SizedBox(height: 8),
                Text(
                  'Worker: ${widget.workerName}',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 13,
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
