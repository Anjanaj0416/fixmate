// lib/screens/worker_results_screen.dart
// MODIFIED VERSION - Changed from Booking to Quote Flow
// FIXED VERSION - All compilation errors resolved

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ml_service.dart';
import '../services/quote_service.dart';
import '../models/worker_model.dart';
import 'worker_detail_screen.dart';

class WorkerResultsScreen extends StatefulWidget {
  final List<MLWorker> workers;
  final AIAnalysis aiAnalysis;
  final String problemDescription;
  final List<String> problemImageUrls;

  const WorkerResultsScreen({
    Key? key,
    required this.workers,
    required this.aiAnalysis,
    required this.problemDescription,
    this.problemImageUrls = const [],
  }) : super(key: key);

  @override
  State<WorkerResultsScreen> createState() => _WorkerResultsScreenState();
}

class _WorkerResultsScreenState extends State<WorkerResultsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Recommended Workers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Compact AI Analysis Summary
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfo(
                        Icons.location_on,
                        widget.aiAnalysis.userInputLocation,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfo(
                        Icons.build,
                        widget.aiAnalysis.servicePredictions.first.serviceType,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfo(
                        Icons.group,
                        '${widget.workers.length} workers',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfo(
                        Icons.schedule,
                        'flexible',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Expandable Issue Description
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Issue Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              _isDescriptionExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                        if (_isDescriptionExpanded) ...[
                          SizedBox(height: 8),
                          Text(
                            widget.problemDescription,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Available Workers List
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Available Workers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Workers List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.workers.length,
              itemBuilder: (context, index) {
                MLWorker worker = widget.workers[index];
                return _buildWorkerCard(worker, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(MLWorker worker, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Header
            Row(
              children: [
                // Worker Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Worker Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    worker.workerName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Worker Name and Service Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.workerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          worker.serviceType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Match Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '${(worker.aiConfidence * 100).toInt()}% Match',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Worker Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.star,
                  '${worker.rating}',
                  Colors.amber,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  Icons.work,
                  '${worker.experienceYears} yrs',
                  Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  Icons.location_on,
                  '${worker.distanceKm.toStringAsFixed(1)} km',
                  Colors.green,
                ),
              ],
            ),
            SizedBox(height: 12),

            // Bio
            Text(
              worker.bio,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16),

            // Daily Rate
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Rate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'LKR ${worker.dailyWageLkr}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                // Details Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewWorkerDetails(worker),
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Call Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callWorker(worker.phoneNumber),
                    icon: Icon(Icons.phone, size: 18),
                    label: Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // MODIFIED: Changed "Book Now" to "Create Quote"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createQuote(worker),
                icon: Icon(Icons.request_quote, color: Colors.white, size: 20),
                label: Text(
                  'Create Quote',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // FIXED: Added required problemDescription parameter
  void _viewWorkerDetails(MLWorker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDetailScreen(
          worker: worker,
          problemDescription: widget.problemDescription,
          problemImageUrls: widget.problemImageUrls,
        ),
      ),
    );
  }

  // Call worker
  void _callWorker(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // MODIFIED: Create quote instead of booking
  Future<void> _createQuote(MLWorker worker) async {
    // MODIFIED: Show confirmation dialog with "Confirm Quote" title
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Quote'), // CHANGED: Updated title
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to request a quote from:'),
            SizedBox(height: 16),
            Text('Worker: ${worker.workerName}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Service: ${worker.serviceType}'),
            Text('Rate: LKR ${worker.dailyWageLkr}/day'),
            SizedBox(height: 8),
            Text('Location: ${worker.city}',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirm Quote'), // CHANGED: Updated button text
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _sendQuoteRequest(worker);
    }
  }

  // MODIFIED: Send quote request instead of creating booking
  Future<void> _sendQuoteRequest(MLWorker worker) async {
    try {
      // MODIFIED: Show loading dialog with "Creating Quote..." message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(width: 16),
              Text('Creating Quote...'), // CHANGED: Updated message
            ],
          ),
        ),
      );

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get customer data
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) throw Exception('Customer profile not found');

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;

      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // Get worker_id - first check if worker exists in database
      QuerySnapshot workerQuery = await FirebaseFirestore.instance
          .collection('workers')
          .where('email', isEqualTo: worker.email)
          .limit(1)
          .get();

      if (workerQuery.docs.isEmpty) {
        throw Exception('Worker not found in database');
      }

      // FIXED: Handle nullable workerId properly
      String? nullableWorkerId = (workerQuery.docs.first.data()
          as Map<String, dynamic>)['worker_id'] as String?;

      if (nullableWorkerId == null || nullableWorkerId.isEmpty) {
        throw Exception('Worker ID is missing');
      }

      String workerId = nullableWorkerId;

      // FIXED: Get service details from AI analysis - ServicePrediction only has serviceType and confidence
      String serviceType =
          widget.aiAnalysis.servicePredictions.first.serviceType;

      // Use default values for subService and issueType since they don't exist in ServicePrediction
      String subService = 'General Service';
      String issueType = 'General Issue';

      // Create quote using QuoteService
      String quoteId = await QuoteService.createQuote(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
        workerName: worker.workerName,
        workerPhone: worker.phoneNumber,
        serviceType: serviceType,
        subService: subService,
        issueType: issueType,
        problemDescription: widget.problemDescription,
        problemImageUrls: widget.problemImageUrls,
        location: widget.aiAnalysis.userInputLocation,
        address: widget.aiAnalysis.userInputLocation,
        urgency: 'normal',
        budgetRange: 'LKR ${worker.dailyWageLkr}',
        scheduledDate: DateTime.now().add(Duration(days: 1)),
        scheduledTime: '09:00 AM',
      );

      // Close loading dialog
      Navigator.pop(context);

      // MODIFIED: Show success dialog with "Quote Sent Successfully!" message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Quote Sent Successfully!'), // CHANGED: Updated title
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Your quote request has been sent to the worker.'), // CHANGED: Updated message
              SizedBox(height: 12),
              Text('Quote ID: $quoteId',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Worker ID: $workerId',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Worker: ${worker.workerName}'),
              Text('Service: $serviceType'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Next Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• The worker will review your request',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                    Text(
                      '• You\'ll receive a quote with pricing',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                    Text(
                      '• Check your Quotes tab for updates',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create quote: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
