// lib/screens/booking_detail_customer_screen.dart
// MODIFIED VERSION - Added Review/Rating option for completed bookings
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/chat_service.dart';
import '../services/rating_service.dart';
import '../utils/string_utils.dart';
import 'chat_screen.dart';

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
  bool _hasReviewed = false;
  bool _isCheckingReview = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _checkIfReviewed();
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

  Future<void> _checkIfReviewed() async {
    try {
      setState(() => _isCheckingReview = true);

      // Check if review already exists for this booking
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('booking_id', isEqualTo: widget.booking.bookingId)
          .where('customer_id', isEqualTo: widget.booking.customerId)
          .limit(1)
          .get();

      setState(() {
        _hasReviewed = reviewSnapshot.docs.isNotEmpty;
        _isCheckingReview = false;
      });
    } catch (e) {
      print('Error checking review status: $e');
      setState(() => _isCheckingReview = false);
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFavorite = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentReference customerRef =
          FirebaseFirestore.instance.collection('customers').doc(user.uid);

      if (_isFavorite) {
        // Remove from favorites
        await customerRef.update({
          'favorite_workers': FieldValue.arrayRemove([widget.booking.workerId])
        });
        setState(() => _isFavorite = false);
        _showSnackBar('Removed from favorites', Colors.orange);
      } else {
        // Add to favorites
        await customerRef.update({
          'favorite_workers': FieldValue.arrayUnion([widget.booking.workerId])
        });
        setState(() => _isFavorite = true);
        _showSnackBar('Added to favorites', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to update favorites', Colors.red);
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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
            otherUserName: widget.booking.workerName,
            currentUserType: 'customer',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Failed to open chat: $e', Colors.red);
    }
  }

  // View issue photos
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

  // NEW: Show review dialog
  Future<void> _showReviewDialog() async {
    if (_hasReviewed) {
      _showSnackBar('You have already reviewed this worker', Colors.orange);
      return;
    }

    double rating = 5.0;
    TextEditingController reviewController = TextEditingController();

    bool? submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rate ${widget.booking.workerName}',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your experience?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      iconSize: 40,
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          rating = (index + 1).toDouble();
                        });
                      },
                    );
                  }),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    '${rating.toStringAsFixed(1)} / 5.0',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Review text
                Text(
                  'Write a review (optional)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this worker...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reviewController.text.trim().isEmpty) {
                  // Show confirmation if no review text
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Submit without review?'),
                      content: Text(
                          'You haven\'t written a review. Submit rating only?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Go Back'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Submit'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                }

                // Submit review
                try {
                  await RatingService.submitRating(
                    bookingId: widget.booking.bookingId,
                    customerId: widget.booking.customerId,
                    customerName: widget.booking.customerName,
                    workerId: widget.booking.workerId,
                    workerName: widget.booking.workerName,
                    rating: rating,
                    review: reviewController.text.trim(),
                    serviceType: widget.booking.serviceType,
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit review: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Submit Review'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true) {
      _showSnackBar('Thank you for your review!', Colors.green);
      _checkIfReviewed(); // Refresh review status
    }
  }

  Color _getStatusColor(BookingStatus status) {
    return status.color;
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return Icons.schedule;
      case BookingStatus.accepted:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.build;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
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
                                color: Colors.white70,
                                fontSize: 12,
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

              // NEW: Review Button - Only show if completed and not reviewed
              if (widget.booking.status == BookingStatus.completed &&
                  !_isCheckingReview)
                _hasReviewed
                    ? Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You have reviewed this worker',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: _showReviewDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.amber[700],
                                    size: 28,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rate Your Experience',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Share your feedback about ${widget.booking.workerName}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

              if (widget.booking.status == BookingStatus.completed &&
                  !_isCheckingReview)
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
                ],
              ),

              SizedBox(height: 16),

              // Worker Information
              _buildSectionCard(
                title: 'Worker Information',
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
                            widget.booking.workerName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.chat_bubble_outline),
                            color: Colors.green,
                            onPressed: _openChat,
                            tooltip: 'Chat with worker',
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            color: _isFavorite ? Colors.red : Colors.grey,
                            onPressed:
                                _isLoadingFavorite ? null : _toggleFavorite,
                            tooltip: _isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                  _buildInfoRow('Phone', widget.booking.workerPhone),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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

              SizedBox(height: 16),

              // Location Details
              _buildSectionCard(
                title: 'Location Details',
                icon: Icons.location_on,
                color: Colors.teal,
                children: [
                  _buildInfoRow('Location', widget.booking.location),
                  _buildInfoRow('Address', widget.booking.address),
                ],
              ),

              SizedBox(height: 16),

              // Additional Details
              _buildSectionCard(
                title: 'Additional Details',
                icon: Icons.more_horiz,
                color: Colors.indigo,
                children: [
                  _buildInfoRow('Urgency',
                      StringUtils.capitalizeWords(widget.booking.urgency)),
                  _buildInfoRow('Budget Range', widget.booking.budgetRange),
                  if (widget.booking.finalPrice != null)
                    _buildInfoRow(
                      'Final Price',
                      'LKR ${widget.booking.finalPrice!.toStringAsFixed(2)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
