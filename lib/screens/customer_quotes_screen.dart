// lib/screens/customer_quotes_screen.dart
// MODIFIED VERSION - Navigate to Accepted bookings tab after accepting invoice

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import 'quote_detail_customer_screen.dart';
import 'customer_dashboard.dart'; // ADDED: Import CustomerDashboard

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
          elevation: 0,
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

        List<QuoteModel> acceptedQuotes = (snapshot.data ?? [])
            .where((q) => q.status == QuoteStatus.accepted)
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
              _buildInvoiceCard(acceptedQuotes[index]),
        );
      },
    );
  }

  Widget _buildPendingQuoteCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailCustomerScreen(quote: quote),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    quote.workerName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getQuoteStatusColor(quote.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: _getQuoteStatusColor(quote.status)),
                    ),
                    child: Text(
                      _getQuoteStatusText(quote.status),
                      style: TextStyle(
                        color: _getQuoteStatusColor(quote.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                quote.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                quote.problemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              if (quote.status == QuoteStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteQuote(quote),
                        icon: Icon(Icons.delete, size: 16),
                        label: Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuoteDetailCustomerScreen(quote: quote),
                            ),
                          );
                        },
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (quote.status == QuoteStatus.declined) ...[
                Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Worker declined this quote',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailCustomerScreen(quote: quote),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    quote.workerName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Icon(Icons.receipt, color: Colors.green),
                ],
              ),
              SizedBox(height: 8),
              Text(
                quote.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Price:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      'LKR ${quote.finalPrice?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    if (quote.workerNote != null &&
                        quote.workerNote!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Note: ${quote.workerNote}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                quote.problemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelInvoice(quote),
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
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptInvoice(quote),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept & Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: TextButton.icon(
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
                  label: Text('View Full Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
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
          Text(subtitle, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Color _getQuoteStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending:
        return Colors.orange;
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.declined:
        return Colors.red;
      case QuoteStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getQuoteStatusText(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending:
        return 'PENDING';
      case QuoteStatus.accepted:
        return 'ACCEPTED';
      case QuoteStatus.declined:
        return 'DECLINED';
      case QuoteStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Future<void> _deleteQuote(QuoteModel quote) async {
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
        await QuoteService.deleteQuote(quoteId: quote.quoteId);
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

  // MODIFIED: Navigate to Accepted bookings tab after accepting invoice
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
            Text('Price: LKR ${quote.finalPrice?.toStringAsFixed(2) ?? 'N/A'}'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This will start your booking',
                style: TextStyle(fontSize: 12, color: Colors.green[900]),
              ),
            ),
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
            child: Text('Accept & Book', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Creating booking...'),
                  ],
                ),
              ),
            ),
          ),
        );

        String bookingId =
            await QuoteService.acceptInvoice(quoteId: quote.quoteId);

        // Close loading dialog
        Navigator.pop(context);

        // Show success dialog with navigation button
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
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
                  // Close dialog
                  Navigator.pop(context);
                  // Navigate to CustomerDashboard with Bookings tab -> Accepted filter
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
        // Close loading dialog if open
        Navigator.pop(context);
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
