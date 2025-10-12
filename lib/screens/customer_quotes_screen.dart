// lib/screens/customer_quotes_screen.dart
// MODIFIED VERSION - Create accepted bookings and navigate to Accepted tab

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import 'quote_detail_customer_screen.dart';
import 'customer_dashboard.dart';

class CustomerQuotesScreen extends StatefulWidget {
  @override
  State<CustomerQuotesScreen> createState() => _CustomerQuotesScreenState();
}

class _CustomerQuotesScreenState extends State<CustomerQuotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          setState(() {
            _customerId =
                (customerDoc.data() as Map<String, dynamic>)['customer_id'] ??
                    user.uid;
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
          backgroundColor: Colors.blue,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Quotes'),
        backgroundColor: Colors.blue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Pending Quotes'),
            Tab(text: 'Accepted Invoices'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingQuotesTab(),
            _buildAcceptedInvoicesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingQuotesTab() {
    return StreamBuilder<List<QuoteModel>>(
      stream: QuoteService.getCustomerQuotes(_customerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        List<QuoteModel> pendingQuotes = (snapshot.data ?? [])
            .where((q) =>
                q.status == QuoteStatus.pending ||
                q.status == QuoteStatus.declined)
            .toList();

        if (pendingQuotes.isEmpty) {
          return _buildEmptyState(
            'No pending quotes',
            'Your quote requests will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pendingQuotes.length,
          itemBuilder: (context, index) =>
              _buildPendingQuoteCard(pendingQuotes[index]),
        );
      },
    );
  }

  Widget _buildAcceptedInvoicesTab() {
    return StreamBuilder<List<QuoteModel>>(
      stream: QuoteService.getCustomerQuotes(_customerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // ✅ FIXED: Filter out invoices that have been converted to bookings
        List<QuoteModel> acceptedQuotes = (snapshot.data ?? [])
            .where((q) => q.status == QuoteStatus.accepted)
            .where((q) =>
                q.bookingId == null ||
                q.bookingId!.isEmpty) // ✅ ENABLED: Filter out converted quotes
            .toList();

        if (acceptedQuotes.isEmpty) {
          return _buildEmptyState(
            'No accepted invoices',
            'Accepted quotes will appear here',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: acceptedQuotes.length,
          itemBuilder: (context, index) =>
              _buildAcceptedInvoiceCard(acceptedQuotes[index]),
        );
      },
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
                  onPressed: () => _viewQuoteDetails(quote),
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
                        'LKR ${quote.finalPrice?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  if (quote.workerNote != null && quote.workerNote!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note: ${quote.workerNote}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'good',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelInvoice(quote),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                    ),
                    icon: Icon(Icons.close, size: 18),
                    label: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptInvoice(quote),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.check_circle, size: 20),
                    label: Text('Accept & Book'),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _viewQuoteDetails(quote),
              icon: Icon(Icons.info_outline, size: 16),
              label: Text('View Full Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _viewQuoteDetails(QuoteModel quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteDetailCustomerScreen(quote: quote),
      ),
    );
  }

  Future<void> _deleteQuote(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Quote?'),
        content: Text('Are you sure you want to delete this quote request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
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

  Future<void> _cancelInvoice(QuoteModel quote) async {
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
        await QuoteService.cancelInvoice(quoteId: quote.quoteId);
        _showSuccessSnackBar('Invoice cancelled successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to cancel invoice: ${e.toString()}');
      }
    }
  }

  // MODIFIED: Accept invoice and navigate to Accepted bookings tab
  Future<void> _acceptInvoice(QuoteModel quote) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Invoice?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm booking with:'),
            SizedBox(height: 8),
            Text('Worker: ${quote.workerName}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Price: LKR ${quote.finalPrice?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Creating booking...'),
              ],
            ),
          ),
        );

        // MODIFIED: Accept invoice and create booking
        String bookingId =
            await QuoteService.acceptInvoice(quoteId: quote.quoteId);

        // Close loading dialog
        Navigator.pop(context);

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Booking Created!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your booking has been created successfully!'),
                SizedBox(height: 12),
                Text('Booking ID: $bookingId',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // MODIFIED: Navigate to Bookings tab with Accepted filter
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerDashboard(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                icon: Icon(Icons.calendar_today),
                label:
                    Text('View Booking', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Failed to accept invoice: ${e.toString()}');
      }
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
