// lib/screens/booking_detail_customer_screen.dart
// MODIFIED VERSION - Blue section headers + gradient background (white → light blur)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
        List<String> favoriteWorkers =
            List<String>.from(data['favorite_workers'] ?? []);

        setState(() {
          _isFavorite = favoriteWorkers.contains(widget.booking.workerId);
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFavorite = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (_isFavorite) {
        // Remove from favorites
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .update({
          'favorite_workers': FieldValue.arrayRemove([widget.booking.workerId])
        });

        setState(() => _isFavorite = false);
        _showSuccessSnackBar('Removed from favorites');
      } else {
        // Add to favorites
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .update({
          'favorite_workers': FieldValue.arrayUnion([widget.booking.workerId])
        });

        setState(() => _isFavorite = true);
        _showSuccessSnackBar('Added to favorites ❤️');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update favorites: ${e.toString()}');
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _openChat(BuildContext context) async {
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
            otherUserName: widget.booking.workerName,
            currentUserType: 'customer',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  Future<void> _openRatingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(booking: widget.booking),
    );

    if (result == true) {
      setState(() {});
      Navigator.pop(context);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // 🎨 MODIFIED: Added gradient background (white at top → light blur at bottom)
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
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
                              'Booking Status',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getStatusText(widget.booking.status),
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

              // Booking Information Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🎨 MODIFIED: Changed to blue color
                      Text(
                        'Booking Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Changed from default to blue
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.confirmation_number,
                        'Booking ID',
                        widget.booking.bookingId.length > 12
                            ? '...${widget.booking.bookingId.substring(widget.booking.bookingId.length - 12)}'
                            : widget.booking.bookingId,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Created',
                        _formatDate(widget.booking.createdAt),
                      ),
                      _buildInfoRow(
                        Icons.schedule,
                        'Scheduled',
                        '${_formatDate(widget.booking.scheduledDate)} at ${widget.booking.scheduledTime}',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🎨 MODIFIED: Changed to blue color
                          Text(
                            'Worker Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  Colors.blue, // Changed from default to blue
                            ),
                          ),
                          // FAVORITE BUTTON - Show only for completed bookings
                          if (widget.booking.status == BookingStatus.completed)
                            _isLoadingFavorite
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                    onPressed: _toggleFavorite,
                                    tooltip: _isFavorite
                                        ? 'Remove from favorites'
                                        : 'Add to favorites',
                                  ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.person,
                        'Name',
                        widget.booking.workerName,
                      ),
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        widget.booking.workerPhone,
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openChat(context),
                          icon: Icon(Icons.chat, size: 18),
                          label: Text('Chat with Worker'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Service Details Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🎨 MODIFIED: Changed to blue color
                      Text(
                        'Service Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Changed from default to blue
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.build,
                        'Service Type',
                        widget.booking.serviceType.replaceAll('_', ' '),
                      ),
                      _buildInfoRow(
                        Icons.category,
                        'Sub Service',
                        widget.booking.subService,
                      ),
                      _buildInfoRow(
                        Icons.priority_high,
                        'Issue Type',
                        widget.booking.issueType,
                      ),
                      _buildInfoRow(
                        Icons.warning_amber,
                        'Urgency',
                        widget.booking.urgency,
                      ),
                      _buildInfoRow(
                        Icons.attach_money,
                        'Budget',
                        widget.booking.budgetRange,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Problem Description:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.booking.problemDescription,
                        style: TextStyle(fontSize: 14),
                      ),
                      if (widget.booking.problemImageUrls.isNotEmpty) ...[
                        SizedBox(height: 12),
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
                              Row(
                                children: [
                                  Icon(Icons.photo_library,
                                      color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '${widget.booking.problemImageUrls.length} photo(s) attached',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => _viewIssuePhotos(context),
                                child: Text('View'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Location Card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🎨 MODIFIED: Changed to blue color
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue, // Changed from default to blue
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        widget.booking.location,
                      ),
                      _buildInfoRow(
                        Icons.home,
                        'Address',
                        widget.booking.address,
                      ),
                    ],
                  ),
                ),
              ),

              // Rate Worker Button (only for completed bookings that haven't been rated)
              if (widget.booking.status == BookingStatus.completed &&
                  widget.booking.customerRating == null) ...[
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openRatingDialog,
                    icon: Icon(Icons.star, size: 20),
                    label: Text('Rate Worker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Icons.hourglass_empty;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.work;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Issue Photo Viewer Screen
class IssuePhotoViewerScreenCustomer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Issue Photos'),
        backgroundColor: Colors.blue,
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
