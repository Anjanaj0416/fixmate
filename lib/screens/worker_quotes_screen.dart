// lib/screens/worker_quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';

class WorkerQuotesScreen extends StatefulWidget {
  @override
  _WorkerQuotesScreenState createState() => _WorkerQuotesScreenState();
}

class _WorkerQuotesScreenState extends State<WorkerQuotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _workerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWorkerId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerId() async {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Quote Requests'),
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'New Requests'),
            Tab(text: 'Responded'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuotesList('pending'),
          _buildQuotesList('responded'),
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
        .where('worker_id', isEqualTo: _workerId)
        .orderBy('created_at', descending: true);

    if (statusFilter == 'pending') {
      query = query.where('status', isEqualTo: 'pending');
    } else if (statusFilter == 'responded') {
      query = query.where('status', whereIn: ['accepted', 'declined']);
    }

    return query.snapshots();
  }

  Widget _buildEmptyState(String statusFilter) {
    String message = statusFilter == 'pending'
        ? 'No new quote requests'
        : statusFilter == 'responded'
            ? 'No responded quotes'
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
            'Customers will send you quote requests',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(QuoteModel quote) {
    bool isPending = quote.status == QuoteStatus.pending;
    bool isAccepted = quote.status == QuoteStatus.accepted;
    bool isDeclined = quote.status == QuoteStatus.declined;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.customerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        quote.customerPhone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
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
            Divider(),
            SizedBox(height: 8),

            // Service details
            _buildDetailRow(
                Icons.build, 'Service', quote.serviceType.replaceAll('_', ' ')),
            _buildDetailRow(Icons.description, 'Issue',
                quote.issueType.replaceAll('_', ' ')),
            _buildDetailRow(Icons.location_on, 'Location',
                quote.location.replaceAll('_', ' ')),
            _buildDetailRow(Icons.access_time, 'Urgency', quote.urgency),
            _buildDetailRow(
                Icons.attach_money, 'Budget Range', quote.budgetRange),

            SizedBox(height: 8),

            // Problem description
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problem Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    quote.problemDescription,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Show images if any
            if (quote.problemImageUrls.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Attached Images:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: quote.problemImageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(quote.problemImageUrls[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Show response if already responded
            if (isAccepted || isDeclined) ...[
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              if (isAccepted && quote.finalPrice != null) ...[
                _buildDetailRow(Icons.money, 'Your Quoted Price',
                    'LKR ${quote.finalPrice!.toStringAsFixed(2)}',
                    highlight: true),
                if (quote.workerNote != null && quote.workerNote!.isNotEmpty)
                  _buildDetailRow(Icons.note, 'Your Note', quote.workerNote!),
              ] else if (isDeclined) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'You declined this quote',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Action buttons for pending quotes
            if (isPending) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineQuote(quote.quoteId),
                      icon: Icon(Icons.cancel, size: 18),
                      label: Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAcceptQuoteDialog(quote),
                      icon: Icon(Icons.check_circle, size: 18),
                      label: Text('Accept & Quote'),
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

  Future<void> _showAcceptQuoteDialog(QuoteModel quote) async {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Quote & Send Price'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${quote.customerName}',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Budget Range: ${quote.budgetRange}'),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Final Price (LKR) *',
                  hintText: 'Enter your quoted price',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText:
                      'Add estimated time, materials needed, or other details',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'The customer will receive your quote and can accept or cancel it.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              priceController.dispose();
              noteController.dispose();
              Navigator.pop(context, false);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a price'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Send Quote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        double finalPrice = double.parse(priceController.text);
        String note = noteController.text.trim();

        await QuoteService.acceptQuote(
          quoteId: quote.quoteId,
          finalPrice: finalPrice,
          workerNote: note.isNotEmpty ? note : 'No additional notes',
        );

        _showSuccessSnackBar('Quote sent successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to send quote: ${e.toString()}');
      }
    }

    priceController.dispose();
    noteController.dispose();
  }

  Future<void> _declineQuote(String quoteId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline Quote'),
        content: Text(
            'Are you sure you want to decline this quote request? The customer will be notified.'),
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

    if (confirm == true) {
      try {
        await QuoteService.declineQuote(quoteId: quoteId);
        _showSuccessSnackBar('Quote declined');
      } catch (e) {
        _showErrorSnackBar('Failed to decline quote: ${e.toString()}');
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
