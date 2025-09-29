// lib/screens/worker_detail_screen.dart
// COPY THIS ENTIRE FILE
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ml_service.dart';
import '../services/worker_storage_service.dart';
import '../services/booking_service.dart';

class WorkerDetailScreen extends StatefulWidget {
  final MLWorker worker;
  final String problemDescription;

  const WorkerDetailScreen({
    Key? key,
    required this.worker,
    required this.problemDescription,
  }) : super(key: key);

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  bool _isBooking = false;

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
                            color: Colors.blue),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.worker.workerName,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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
                  // Quick Stats
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(Icons.star,
                            widget.worker.rating.toString(), 'Rating'),
                        _buildQuickStat(Icons.location_on,
                            '${widget.worker.distanceKm} km', 'Distance'),
                        _buildQuickStat(Icons.verified,
                            '${widget.worker.aiConfidence.toInt()}%', 'Match'),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // About
                  Text('About',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _buildInfoCard(
                      Icons.person_outline, 'Bio', widget.worker.bio),
                  SizedBox(height: 24),

                  // Contact
                  Text('Contact Information',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _buildInfoCard(
                      Icons.phone, 'Phone', widget.worker.phoneNumber),
                  SizedBox(height: 8),
                  _buildInfoCard(
                      Icons.location_on, 'Location', widget.worker.city),
                  SizedBox(height: 24),

                  // Pricing
                  Text('Pricing & Experience',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            Icons.work_outline,
                            '${widget.worker.experienceYears} Years',
                            'Experience',
                            Colors.orange),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                            Icons.attach_money,
                            'LKR ${widget.worker.dailyWageLkr}',
                            'Daily Rate',
                            Colors.green),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Problem
                  Text('Your Problem',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(widget.problemDescription,
                        style: TextStyle(fontSize: 15, height: 1.5)),
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Book Button
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: _isBooking ? null : _handleBooking,
          backgroundColor: Colors.blue,
          icon: _isBooking
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Icon(Icons.calendar_today),
          label: Text(_isBooking ? 'Processing...' : 'Book This Worker',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                SizedBox(height: 4),
                Text(value,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

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
      // Step 1: Store worker if not exists
      String workerFirebaseUid;
      bool exists = await WorkerStorageService.checkWorkerExistsByEmail(
          widget.worker.email);

      if (!exists) {
        workerFirebaseUid = await WorkerStorageService.storeWorkerFromML(
            mlWorker: widget.worker);
        _showSnackBar('Worker profile created', Colors.green);
      } else {
        String? tempUid =
            await WorkerStorageService.getWorkerUidByEmail(widget.worker.email);
        workerFirebaseUid = tempUid ?? '';

        if (workerFirebaseUid.isEmpty) {
          throw Exception('Could not retrieve worker UID');
        }
      }

      // Step 2: Get customer data
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();
      if (!customerDoc.exists) throw Exception('Customer profile not found');

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;
      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          customerData['first_name'] ??
          'Customer';
      String customerPhone =
          customerData['phone'] ?? customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // Step 3: Create booking
      String bookingId = await BookingService.createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: widget.worker.workerId,
        workerName: widget.worker.workerName,
        workerPhone: widget.worker.phoneNumber,
        serviceType: widget.worker.serviceType,
        subService: widget.worker.serviceType,
        issueType: 'general',
        problemDescription: widget.problemDescription,
        problemImageUrls: [],
        location: widget.worker.city,
        address: widget.worker.city,
        urgency: 'normal',
        budgetRange: 'LKR ${widget.worker.dailyWageLkr}',
        scheduledDate: DateTime.now().add(Duration(days: 1)),
        scheduledTime: '09:00 AM',
      );

      setState(() => _isBooking = false);
      _showSuccessDialog(bookingId);
    } catch (e) {
      setState(() => _isBooking = false);
      _showErrorDialog('Booking failed: $e');
    }
  }

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
                Text('Rate: LKR ${widget.worker.dailyWageLkr}'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Confirm'),
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
        content: Text(
            'Booking ID: ${bookingId.substring(0, 12)}...\n\nThe worker will be notified.',
            textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Back to Chat'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
