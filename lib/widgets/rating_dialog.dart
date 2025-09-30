// lib/widgets/rating_dialog.dart
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/review_service.dart';

class RatingDialog extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback onReviewSubmitted;

  const RatingDialog({
    Key? key,
    required this.booking,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0;
  int _hoveredStar = -1;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final Map<int, String> _ratingDescriptions = {
    1: 'Poor',
    2: 'Below Average',
    3: 'Average',
    4: 'Good',
    5: 'Excellent',
  };

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReviewService.submitReview(
        bookingId: widget.booking.bookingId,
        customerId: widget.booking.customerId,
        customerName: widget.booking.customerName,
        workerId: widget.booking.workerId,
        workerName: widget.booking.workerName,
        rating: _rating,
        review: _reviewController.text.trim(),
        serviceType: widget.booking.serviceType,
      );

      Navigator.of(context).pop();
      widget.onReviewSubmitted();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Thank you for your feedback!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= _rating;
        final isHovered = starNumber <= _hoveredStar;

        return MouseRegion(
          onEnter: (_) {
            setState(() {
              _hoveredStar = starNumber;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredStar = -1;
            });
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                _rating = starNumber.toDouble();
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isSelected || isHovered ? Icons.star : Icons.star_border,
                color: isSelected || isHovered ? Colors.amber : Colors.grey,
                size: 48,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFFF9800),
                    child: Text(
                      widget.booking.workerName[0].toUpperCase(),
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
                          'Rate Your Experience',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'with ${widget.booking.workerName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Service type chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Star rating
              _buildStarRating(),

              SizedBox(height: 12),

              // Rating description
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: Text(
                  _rating > 0
                      ? _ratingDescriptions[_rating.toInt()] ?? ''
                      : 'Tap to rate',
                  key: ValueKey(_rating),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _rating > 0 ? Color(0xFFFF9800) : Colors.grey,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Review text field
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  labelText: 'Write a review (optional)',
                  hintText: 'Share details of your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting || _rating == 0 ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF9800),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the rating dialog
Future<void> showRatingDialog(BuildContext context, BookingModel booking,
    VoidCallback onReviewSubmitted) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      booking: booking,
      onReviewSubmitted: onReviewSubmitted,
    ),
  );
}
