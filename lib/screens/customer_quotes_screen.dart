// lib/screens/customer_quotes_screen.dart
// NEW FILE - Customer Quotes Tab showing all quotes and accepted invoices

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import 'quote_detail_customer_screen.dart';

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
          return _buildEmptyState('No pending quotes',
              'Request quotes from workers to get started');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pendingQuotes.length,
          itemBuilder: (context, index) {
            return _buildPendingQuoteCard(pendingQuotes[index]);
          },
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
          return _buildEmptyState('No accepted invoices',
              'Invoices will appear here when workers accept your quotes');
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: acceptedQuotes.length,
          itemBuilder: (context, index) {
            return _buildInvoiceCard(acceptedQuotes[index]);
          },
        );
      },
    );
  }

  Widget _buildPendingQuoteCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        // ADDED: Navigate to detail screen on tap
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getQuoteStatusColor(quote.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getQuoteStatusText(quote.status),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // ADDED: Arrow icon to indicate it's tappable
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[400]),
                ],
              ),
              SizedBox(height: 12),
              Text(
                quote.workerName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                quote.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                quote.problemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                'Budget: ${quote.budgetRange}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteQuote(quote),
                      icon: Icon(Icons.delete, size: 18),
                      label: Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // ADDED: View Details button
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
                      icon: Icon(Icons.visibility, size: 18),
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
        // ADDED: Navigate to detail screen on tap
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
                    '📄 INVOICE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      // ADDED: Arrow icon
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ],
              ),
              Divider(height: 24),
              Text(
                quote.workerName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                quote.serviceType.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Final Price:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'LKR ${quote.finalPrice?.toStringAsFixed(2) ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    if (quote.workerNote != null &&
                        quote.workerNote!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Note: ${quote.workerNote}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Service Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                quote.problemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                'Location: ${quote.address}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
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
              // ADDED: View full details button
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
        String bookingId =
            await QuoteService.acceptInvoice(quoteId: quote.quoteId);
        _showSuccessSnackBar('Booking started successfully! ID: $bookingId');
      } catch (e) {
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
