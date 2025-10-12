// lib/screens/booking_detail_worker_screen.dart
// FIXED VERSION - Corrected all compilation errors
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/chat_service.dart';
import '../utils/string_utils.dart';
import 'chat_screen.dart';

class BookingDetailWorkerScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailWorkerScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<BookingDetailWorkerScreen> createState() =>
      _BookingDetailWorkerScreenState();
}

class _BookingDetailWorkerScreenState extends State<BookingDetailWorkerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFE5CC)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.booking.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(widget.booking.status),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Booking Information
              _buildSectionCard(
                title: 'Booking Information',
                icon: Icons.info_outline,
                color: Colors.blue,
                children: [
                  _buildInfoRow('Booking ID',
                      StringUtils.formatBookingId(widget.booking.bookingId)),
                  _buildInfoRow(
                    'Created',
                    '${widget.booking.createdAt.toString().split(' ')[0]}',
                  ),
                  _buildInfoRow(
                    'Scheduled',
                    '${widget.booking.scheduledDate.toString().split(' ')[0]} at ${widget.booking.scheduledTime}',
                  ),
                  _buildInfoRow(
                      'Urgency', widget.booking.urgency.toUpperCase()),
                ],
              ),

              SizedBox(height: 16),

              // Customer Information
              _buildSectionCard(
                title: 'Customer Information',
                icon: Icons.person,
                color: Colors.orange,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                            widget.booking.customerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.chat_bubble_outline),
                        color: Colors.green,
                        onPressed: _openChat,
                        tooltip: 'Chat with customer',
                      ),
                    ],
                  ),
                  Divider(),
                  _buildInfoRow('Phone', widget.booking.customerPhone),
                  _buildInfoRow('Email', widget.booking.customerEmail),
                ],
              ),

              SizedBox(height: 16),

              // Service Details
              _buildSectionCard(
                title: 'Service Details',
                icon: Icons.build,
                color: Colors.purple,
                children: [
                  _buildInfoRow('Service Type',
                      StringUtils.capitalizeWords(widget.booking.serviceType)),
                  _buildInfoRow('Sub Service',
                      StringUtils.capitalizeWords(widget.booking.subService)),
                  _buildInfoRow('Issue Type',
                      StringUtils.capitalizeWords(widget.booking.issueType)),
                ],
              ),

              SizedBox(height: 16),

              // Problem Description with Image Viewer
              _buildSectionCard(
                title: 'Problem Description',
                icon: Icons.description,
                color: Colors.red,
                children: [
                  Text(widget.booking.problemDescription),

                  // View Photos Button
                  if (widget.booking.problemImageUrls.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  IssuePhotoViewerScreenWorker(
                                imageUrls: widget.booking.problemImageUrls,
                                problemDescription:
                                    widget.booking.problemDescription,
                                customerName: widget.booking.customerName,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.photo_library, color: Colors.white),
                        label: Text(
                          'View Photos (${widget.booking.problemImageUrls.length})',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 16),

              // Location Details
              _buildSectionCard(
                title: 'Location Details',
                icon: Icons.location_on,
                color: Colors.green,
                children: [
                  _buildInfoRow('Location', widget.booking.location),
                  _buildInfoRow('Address', widget.booking.address),
                ],
              ),

              SizedBox(height: 16),

              // Budget Information
              if (widget.booking.budgetRange.isNotEmpty ||
                  widget.booking.finalPrice != null)
                _buildSectionCard(
                  title: 'Pricing Information',
                  icon: Icons.attach_money,
                  color: Colors.teal,
                  children: [
                    if (widget.booking.budgetRange.isNotEmpty)
                      _buildInfoRow(
                          'Customer Budget', widget.booking.budgetRange),
                    if (widget.booking.finalPrice != null)
                      _buildInfoRow(
                        'Final Price',
                        'LKR ${widget.booking.finalPrice!.toStringAsFixed(2)}',
                      ),
                    if (widget.booking.workerNotes != null &&
                        widget.booking.workerNotes!.isNotEmpty)
                      _buildInfoRow('Notes', widget.booking.workerNotes!),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      String chatId = await ChatService.createOrGetChatRoom(
        bookingId: widget.booking.bookingId,
        customerId: widget.booking.customerId,
        customerName: widget.booking.customerName,
        workerId: widget.booking.workerId,
        workerName: widget.booking.workerName,
      );

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            bookingId: widget.booking.bookingId,
            otherUserName: widget.booking.customerName,
            currentUserType: 'worker',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Issue Photo Viewer Screen for Worker
class IssuePhotoViewerScreenWorker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Issue Photos'),
        backgroundColor: Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Problem description header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: $customerName',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Problem Description:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  problemDescription,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Photo grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImage(
                          imageUrl: imageUrls[index],
                          imageIndex: index + 1,
                          totalImages: imageUrls.length,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'photo_$index',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Full screen image viewer
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final int imageIndex;
  final int totalImages;

  const FullScreenImage({
    Key? key,
    required this.imageUrl,
    required this.imageIndex,
    required this.totalImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Photo $imageIndex of $totalImages'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
