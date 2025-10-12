// lib/screens/worker_quotes_screen.dart
// MODIFIED VERSION - Added "View Details" button for worker to see booking details

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import 'package:intl/intl.dart';

class WorkerQuotesScreen extends StatefulWidget {
  @override
  State<WorkerQuotesScreen> createState() => _WorkerQuotesScreenState();
}

class _WorkerQuotesScreenState extends State<WorkerQuotesScreen> {
  String? _workerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (workerDoc.exists) {
          Map<String, dynamic> workerData =
              workerDoc.data() as Map<String, dynamic>;
          setState(() {
            _workerId = workerData['worker_id'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load worker data: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _workerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quote Requests'),
          backgroundColor: Color(0xFFFF9800),
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFE5CC)],
        ),
      ),
      child: StreamBuilder<List<QuoteModel>>(
        stream: QuoteService.getWorkerQuotes(_workerId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<QuoteModel> quotes = snapshot.data ?? [];

          if (quotes.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: quotes.length,
            itemBuilder: (context, index) => _buildQuoteCard(quotes[index]),
          );
        },
      ),
    );
  }

  Widget _buildQuoteCard(QuoteModel quote) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: _getQuoteStatusColor(quote.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _getQuoteStatusColor(quote.status)),
                  ),
                  child: Text(
                    _getQuoteStatusText(quote.status),
                    style: TextStyle(
                      color: _getQuoteStatusColor(quote.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (quote.urgency.toLowerCase() == 'urgent')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SAME DAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  child: Text(quote.customerName[0].toUpperCase()),
                  backgroundColor: Colors.blue[100],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.customerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        quote.serviceType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Problem Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              quote.problemDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    quote.location,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Budget: ${quote.budgetRange}',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ),
            SizedBox(height: 4),
            if (quote.problemImageUrls.isNotEmpty)
              Text(
                '${quote.problemImageUrls.length} image(s) attached',
                style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              ),

            // MODIFIED: Added "View Details" button for all quotes
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showQuoteDetails(quote),
              icon: Icon(Icons.visibility, size: 18),
              label: Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue),
                minimumSize: Size(double.infinity, 40),
              ),
            ),

            if (quote.status == QuoteStatus.pending) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineQuote(quote),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptQuote(quote),
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (quote.status == QuoteStatus.accepted) ...[
              SizedBox(height: 12),
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
                      '✓ Invoice sent to customer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    if (quote.finalPrice != null)
                      Text(
                        'Final Price: LKR ${quote.finalPrice?.toStringAsFixed(2) ?? 'N/A'}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    if (quote.workerNote != null &&
                        quote.workerNote!.isNotEmpty)
                      Text(
                        'Note: ${quote.workerNote}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                  ],
                ),
              ),
            ],
            if (quote.status == QuoteStatus.declined) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✗ You declined this quote',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // NEW: Show detailed quote information in a dialog
  void _showQuoteDetails(QuoteModel quote) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quote Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                Divider(),
                SizedBox(height: 8),
                _buildDetailRow('Customer', quote.customerName),
                _buildDetailRow('Phone', quote.customerPhone),
                _buildDetailRow('Email', quote.customerEmail),
                SizedBox(height: 12),
                _buildDetailRow(
                    'Service Type', quote.serviceType.replaceAll('_', ' ')),
                _buildDetailRow('Sub Service', quote.subService),
                _buildDetailRow('Issue Type', quote.issueType),
                SizedBox(height: 12),
                Text(
                  'Problem Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(quote.problemDescription),
                SizedBox(height: 12),
                _buildDetailRow('Location', quote.location),
                _buildDetailRow('Address', quote.address),
                _buildDetailRow('Urgency', quote.urgency.toUpperCase()),
                _buildDetailRow('Budget Range', quote.budgetRange),
                SizedBox(height: 12),
                _buildDetailRow(
                  'Scheduled Date',
                  DateFormat('MMM dd, yyyy').format(quote.scheduledDate),
                ),
                _buildDetailRow('Scheduled Time', quote.scheduledTime),
                SizedBox(height: 12),
                if (quote.problemImageUrls.isNotEmpty) ...[
                  Text(
                    'Attached Images (${quote.problemImageUrls.length}):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: quote.problemImageUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          quote.problemImageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No quote requests yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Quote requests from customers will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
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

  Future<void> _acceptQuote(QuoteModel quote) async {
    TextEditingController priceController = TextEditingController();
    TextEditingController noteController = TextEditingController();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Quote & Send Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Final Price (LKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Estimated time, requirements...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isEmpty) {
                _showErrorSnackBar('Please enter final price');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Send Invoice', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        double finalPrice = double.parse(priceController.text);
        String note = noteController.text.trim();

        await QuoteService.acceptQuote(
          quoteId: quote.quoteId,
          finalPrice: finalPrice,
          workerNote: note.isNotEmpty ? note : 'No additional notes',
        );
        _showSuccessSnackBar('Invoice sent to customer');
      } catch (e) {
        _showErrorSnackBar('Failed to send invoice: ${e.toString()}');
      }
    }
  }

  Future<void> _declineQuote(QuoteModel quote) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Quote?'),
        content: Text('Are you sure you want to decline this quote request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await QuoteService.declineQuote(quoteId: quote.quoteId);
        _showSuccessSnackBar('Quote declined');
      } catch (e) {
        _showErrorSnackBar('Failed to decline quote: ${e.toString()}');
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
