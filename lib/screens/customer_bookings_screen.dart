// lib/screens/customer_bookings_screen.dart
// MODIFIED VERSION - Integrated quotes into booking filters

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import 'booking_detail_customer_screen.dart';
import 'worker_profile_view_screen.dart';
import 'quote_detail_customer_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  String _selectedFilter = 'accepted'; // Default to 'accepted'
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        setState(() {
          _customerId =
              (customerDoc.data() as Map<String, dynamic>)['customer_id'] ??
                  user.uid;
        });
      }
    }
  }

  Future<void> _deleteBooking(BookingModel booking) async {
    if (booking.status != BookingStatus.requested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only cancel pending bookings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.bookingId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteQuote(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Quote'),
        content: Text('Are you sure you want to delete this quote request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await QuoteService.deleteQuote(quoteId: quoteId);
        _showSuccessSnackBar('Quote deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete quote: ${e.toString()}');
      }
    }
  }

  Future<void> _cancelInvoice(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Invoice?'),
        content: Text('Are you sure you want to cancel this invoice?'),
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
        await QuoteService.cancelInvoice(quoteId: quoteId);
        _showSuccessSnackBar('Invoice cancelled successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to cancel invoice: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('pending_quotes', 'Pending Quotes',
                        Icons.request_quote),
                    SizedBox(width: 8),
                    _buildFilterChip('accepted_invoices', 'Accepted Invoices',
                        Icons.receipt_long),
                    SizedBox(width: 8),
                    _buildFilterChip(
                        'accepted', 'Accepted', Icons.check_circle_outline),
                    SizedBox(width: 8),
                    _buildFilterChip(
                        'in_progress', 'In Progress', Icons.work_outline),
                    SizedBox(width: 8),
                    _buildFilterChip('completed', 'Completed', Icons.done_all),
                    SizedBox(width: 8),
                    _buildFilterChip('cancelled', 'Cancelled', Icons.cancel),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_customerId == null) {
      return Center(child: CircularProgressIndicator());
    }

    // Show quotes for pending_quotes and accepted_invoices filters
    if (_selectedFilter == 'pending_quotes' ||
        _selectedFilter == 'accepted_invoices') {
      return StreamBuilder<List<QuoteModel>>(
        stream: QuoteService.getCustomerQuotes(_customerId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<QuoteModel> quotes = [];

          if (_selectedFilter == 'pending_quotes') {
            quotes = (snapshot.data ?? [])
                .where((q) =>
                    q.status == QuoteStatus.pending ||
                    q.status == QuoteStatus.declined)
                .toList();
          } else if (_selectedFilter == 'accepted_invoices') {
            quotes = (snapshot.data ?? [])
                .where((q) => q.status == QuoteStatus.accepted)
                .where((q) => q.bookingId == null || q.bookingId!.isEmpty)
                .toList();
          }

          if (quotes.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: quotes.length,
            itemBuilder: (context, index) => _selectedFilter == 'pending_quotes'
                ? _buildPendingQuoteCard(quotes[index])
                : _buildAcceptedInvoiceCard(quotes[index]),
          );
        },
      );
    }

    // Show bookings for other filters
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customer_id', isEqualTo: _customerId)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        List<BookingModel> allBookings = snapshot.data!.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();

        List<BookingModel> filteredBookings = allBookings.where((booking) {
          String statusString = booking.status.toString().split('.').last;

          if (_selectedFilter == 'accepted') {
            return statusString == 'accepted';
          } else if (_selectedFilter == 'in_progress') {
            return statusString == 'inProgress';
          } else if (_selectedFilter == 'completed') {
            return statusString == 'completed';
          } else if (_selectedFilter == 'cancelled') {
            return statusString == 'cancelled' || statusString == 'declined';
          }
          return false;
        }).toList();

        if (filteredBookings.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) =>
              _buildBookingCard(filteredBookings[index]),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    bool isSelected = _selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.blue,
          ),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selected: isSelected,
      selectedColor: Colors.blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blue,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    String filterName = _selectedFilter
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No $filterName',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter.contains('quote') ||
                    _selectedFilter.contains('invoice')
                ? 'Your ${filterName.toLowerCase()} will appear here'
                : 'Book a service to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showWorkerProfile(String workerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerProfileViewScreen(workerId: workerId),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (booking.urgency.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.urgency.toLowerCase() == 'urgent'
                          ? Colors.red[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14,
                            color: booking.urgency.toLowerCase() == 'urgent'
                                ? Colors.red
                                : Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          booking.urgency,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: booking.urgency.toLowerCase() == 'urgent'
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              booking.workerName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              booking.serviceType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${booking.scheduledDate.day}/${booking.scheduledDate.month}/${booking.scheduledDate.year}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  booking.scheduledTime,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            if (booking.finalPrice != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                  Text(
                    'LKR ${booking.finalPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingDetailCustomerScreen(booking: booking),
                        ),
                      );
                    },
                    icon: Icon(Icons.info_outline, size: 16),
                    label: Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showWorkerProfile(booking.workerId);
                    },
                    icon: Icon(Icons.person_outline, size: 16),
                    label: Text('Worker Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (booking.status == BookingStatus.requested) ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _deleteBooking(booking),
                  icon: Icon(Icons.cancel_outlined, size: 16),
                  label: Text('Cancel Booking'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingQuoteCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.workerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        quote.serviceType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: quote.status == QuoteStatus.declined
                        ? Colors.red
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    quote.status == QuoteStatus.declined
                        ? 'DECLINED'
                        : 'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QuoteDetailCustomerScreen(quote: quote),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.info_outline, size: 18),
                  label: Text('View Details'),
                ),
                IconButton(
                  onPressed: () => _deleteQuote(quote.quoteId),
                  icon: Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Quote',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedInvoiceCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quote.workerName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.receipt, color: Colors.green),
              ],
            ),
            SizedBox(height: 4),
            Text(
              quote.serviceType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice Ready',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Final Price:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'LKR ${quote.finalPrice?.toStringAsFixed(2) ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  if (quote.workerNote != null &&
                      quote.workerNote!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Divider(),
                    SizedBox(height: 8),
                    Text(
                      'Worker Note:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      quote.workerNote!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuoteDetailCustomerScreen(quote: quote),
                        ),
                      );
                    },
                    icon: Icon(Icons.info_outline, size: 16),
                    label: Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelInvoice(quote.quoteId),
                    icon: Icon(Icons.cancel_outlined, size: 16),
                    label: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.requested:
        return 'REQUESTED';
      case BookingStatus.accepted:
        return 'ACCEPTED';
      case BookingStatus.inProgress:
        return 'IN PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
