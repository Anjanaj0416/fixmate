// lib/screens/worker_detail_screen.dart
// COMPLETE FIXED VERSION - Replace your entire file with this

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';
import '../services/worker_storage_service.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../utils/string_utils.dart';

class WorkerDetailScreen extends StatefulWidget {
  final MLWorker worker;
  final String problemDescription;
  final List<String> problemImageUrls;

  const WorkerDetailScreen({
    Key? key,
    required this.worker,
    required this.problemDescription,
    this.problemImageUrls = const [],
  }) : super(key: key);

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  bool _isBooking = false;

  // ==================== FIXED BOOKING METHOD ====================
  Future<void> _handleBooking() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Please login to book a worker');
      return;
    }

    final confirmed = await _showBookingConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isBooking = true);

    try {
      print('\n========== BOOKING CREATION START ==========');

      // Step 1: Check if worker exists or create new one
      // CRITICAL FIX: This now returns worker_id (HM_XXXX), not Firebase UID
      String? existingWorkerId = await WorkerStorageService.getExistingWorkerId(
        email: widget.worker.email,
        phoneNumber: widget.worker.phoneNumber,
      );

      String workerId;

      if (existingWorkerId != null) {
        // Worker already exists, use existing worker_id
        workerId = existingWorkerId;
        print('✅ Using existing worker: $workerId');
        _showSnackBar('Using existing worker profile', Colors.blue);
      } else {
        // Worker doesn't exist, create new worker
        print('📝 Creating new worker account...');
        _showSnackBar('Creating worker profile...', Colors.orange);

        // CRITICAL FIX: storeWorkerFromML now returns worker_id (HM_XXXX)
        workerId = await WorkerStorageService.storeWorkerFromML(
          mlWorker: widget.worker,
        );
        print('✅ New worker created: $workerId');
        _showSnackBar('Worker profile created', Colors.green);
      }

      // CRITICAL: Verify workerId format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX format)');
      }

      print('✅ Worker ID verified: $workerId');

      // Step 2: Get customer data
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        throw Exception('Customer profile not found');
      }

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;

      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name']} ${customerData['last_name']}';
      String customerPhone =
          customerData['phone'] ?? customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      print('📋 Customer details:');
      print('   ID: $customerId');
      print('   Name: $customerName');

      // Step 3: Create booking with worker_id (HM_XXXX format)
      print('📝 Creating booking with worker_id: $workerId');

      // CRITICAL FIX: Pass worker_id (HM_XXXX), not Firebase UID
      String bookingId = await BookingService.createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId, // ✅ This is HM_XXXX format now
        workerName: widget.worker.workerName,
        workerPhone: widget.worker.phoneNumber,
        serviceType: widget.worker.serviceType,
        subService: widget.worker.serviceType,
        issueType: 'general',
        problemDescription: widget.problemDescription,
        problemImageUrls: widget.problemImageUrls,
        location: widget.worker.city,
        address: widget.worker.city,
        urgency: 'normal',
        budgetRange: 'LKR ${widget.worker.dailyWageLkr}',
        scheduledDate: DateTime.now().add(Duration(days: 1)),
        scheduledTime: '09:00 AM',
      );

      print('✅ Booking created successfully!');
      print('   Booking ID: $bookingId');
      print('   Worker ID: $workerId');
      print('========== BOOKING CREATION END ==========\n');

      setState(() => _isBooking = false);
      _showSuccessDialog(bookingId);
    } catch (e) {
      print('❌ Error creating booking: $e');
      print('========== BOOKING CREATION END ==========\n');
      setState(() => _isBooking = false);
      _showErrorDialog('Booking failed: $e');
    }
  }

  // ==================== UI METHODS ====================

  Future<bool> _showBookingConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to book:'),
                SizedBox(height: 16),
                Text('Worker: ${widget.worker.workerName}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Service: ${widget.worker.serviceType}'),
                Text('Rate: LKR ${widget.worker.dailyWageLkr}/day'),
                SizedBox(height: 8),
                Text('Location: ${widget.worker.city}',
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
                child: Text('Confirm Booking'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('Booking Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Booking ID: ${StringUtils.formatBookingId(bookingId)}...\n\n'
              'The worker will be notified about your request.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'You can now chat with ${widget.worker.workerName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _openChatWithWorker(bookingId);
            },
            icon: Icon(Icons.chat_bubble, color: Colors.white),
            label: Text('Open Chat', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

// ADD this new method to your worker_detail_screen.dart file:
  Future<void> _openChatWithWorker(String bookingId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Get customer data
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        Navigator.pop(context);
        _showErrorDialog('Customer profile not found');
        return;
      }

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;
      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name']} ${customerData['last_name']}';

      // Create or get chat room
      String chatId = await ChatService.createOrGetChatRoom(
        bookingId: bookingId,
        customerId: customerId,
        customerName: customerName,
        workerId: widget.worker.workerId,
        workerName: widget.worker.workerName,
      );

      // Close loading
      Navigator.pop(context);

      // Open chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            bookingId: bookingId,
            otherUserName: widget.worker.workerName,
            currentUserType: 'customer',
          ),
        ),
      );
    } catch (e) {
      // Close loading
      Navigator.pop(context);
      _showErrorDialog('Failed to open chat: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade700],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.worker.workerName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.worker.workerName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.worker.serviceType,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating and Experience
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
                      SizedBox(width: 4),
                      Text(
                        widget.worker.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 20),
                      Icon(Icons.work, color: Colors.blue, size: 24),
                      SizedBox(width: 4),
                      Text(
                        '${widget.worker.experienceYears} years',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Location
                  _buildInfoCard(
                    Icons.location_on,
                    'Location',
                    widget.worker.city,
                    Colors.red,
                  ),

                  // Phone
                  _buildInfoCard(
                    Icons.phone,
                    'Phone',
                    widget.worker.phoneNumber,
                    Colors.green,
                  ),

                  // Email
                  _buildInfoCard(
                    Icons.email,
                    'Email',
                    widget.worker.email,
                    Colors.orange,
                  ),

                  // Daily Rate
                  _buildInfoCard(
                    Icons.attach_money,
                    'Daily Rate',
                    'LKR ${widget.worker.dailyWageLkr}',
                    Colors.purple,
                  ),

                  SizedBox(height: 24),

                  // Problem Description
                  Text(
                    'Your Problem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.problemDescription,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),

                  SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),

      // Book Now Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isBooking ? null : _handleBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isBooking
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Creating Booking...',
                          style: TextStyle(fontSize: 16)),
                    ],
                  )
                : Text('Book Now', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
