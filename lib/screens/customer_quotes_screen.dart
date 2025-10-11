// lib/screens/customer_quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';

class CustomerQuotesScreen extends StatefulWidget {
  @override
  _CustomerQuotesScreenState createState() => _CustomerQuotesScreenState();
}

class _CustomerQuotesScreenState extends State<CustomerQuotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;
  bool _isLoading = true;

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
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerId = customerData['customer_id'] ?? user.uid;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load customer data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Quotes'),
          backgroundColor: Colors.orange,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Quotes'),
        backgroundColor: Colors.orange,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuotesList('pending'),
          _buildQuotesList('accepted'),
          _buildQuotesList('all'),
        ],
      ),
    );
  }

  Widget _buildQuotesList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getQuotesStream(statusFilter),
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
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        List<QuoteModel> quotes = snapshot.data!.docs
            .map((doc) => QuoteModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            return _buildQuoteCard(quotes[index]);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getQuotesStream(String statusFilter) {
    Query query = FirebaseFirestore.instance
        .collection('quotes')
        .where('customer_id', isEqualTo: _customerId)
        .orderBy('created_at', descending: true);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query.snapshots();
  }

  Widget _buildEmptyState(String statusFilter) {
    String message = statusFilter == 'pending'
        ? 'No pending quotes'
        : statusFilter == 'accepted'
            ? 'No accepted quotes'
            : 'No quotes yet';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Request quotes from service providers',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: quote.getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quote.getStatusText(),
                    style: TextStyle(
                      color: quote.getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Service details
            _buildDetailRow(
                Icons.build, 'Service', quote.serviceType.replaceAll('_', ' ')),
            _buildDetailRow(Icons.description, 'Issue',
                quote.issueType.replaceAll('_', ' ')),
            _buildDetailRow(Icons.access_time, 'Urgency', quote.urgency),
            _buildDetailRow(
                Icons.attach_money, 'Budget Range', quote.budgetRange),

            // Show final price and note if accepted
            if (quote.status == QuoteStatus.accepted &&
                quote.finalPrice != null) ...[
              Divider(height: 24),
              _buildDetailRow(Icons.money, 'Final Price',
                  'LKR ${quote.finalPrice!.toStringAsFixed(2)}',
                  highlight: true),
              if (quote.workerNote != null && quote.workerNote!.isNotEmpty)
                _buildDetailRow(Icons.note, 'Worker Note', quote.workerNote!),
            ],

            SizedBox(height: 12),

            // Action buttons
            if (quote.status == QuoteStatus.pending)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteQuote(quote.quoteId),
                  icon: Icon(Icons.delete, size: 18),
                  label: Text('Cancel Quote'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                  ),
                ),
              ),

            // Invoice actions (Accept/Cancel)
            if (quote.status == QuoteStatus.accepted &&
                quote.finalPrice != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelInvoice(quote.quoteId),
                      icon: Icon(Icons.cancel, size: 18),
                      label: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptInvoice(quote.quoteId),
                      icon: Icon(Icons.check_circle, size: 18),
                      label: Text('Accept & Start'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: highlight ? Colors.green : Colors.grey),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.green : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuote(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Quote'),
        content: Text('Are you sure you want to cancel this quote request?'),
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
        await QuoteService.deleteQuote(quoteId: quoteId);
        _showSuccessSnackBar('Quote cancelled successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to cancel quote: ${e.toString()}');
      }
    }
  }

  Future<void> _cancelInvoice(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Invoice'),
        content: Text(
            'Are you sure you want to cancel this invoice? The worker will be notified.'),
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

  Future<void> _acceptInvoice(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Invoice & Start Booking'),
        content: Text(
            'By accepting this invoice, you agree to the price and terms. A booking will be created and the worker will be notified to start the service.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                Text('Accept & Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        String bookingId =
            await QuoteService.acceptInvoiceAndCreateBooking(quoteId: quoteId);

        // Close loading
        Navigator.pop(context);

        _showSuccessSnackBar(
            'Booking started successfully! Booking ID: $bookingId');
      } catch (e) {
        // Close loading
        Navigator.pop(context);
        _showErrorSnackBar('Failed to accept invoice: ${e.toString()}');
      }
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
}
