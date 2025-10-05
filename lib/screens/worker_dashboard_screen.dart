// lib/screens/worker_dashboard_screen.dart
// ENHANCED VERSION - Added Customer Account Switch + Chat/Messages navigation
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../screens/worker_profile_screen.dart';
import '../screens/worker_bookings_screen.dart';
import '../screens/worker_reviews_screen.dart';
import '../screens/worker_chats_screen.dart';
import '../services/rating_service.dart';
import 'worker_notifications_screen.dart';
import 'customer_dashboard.dart'; // NEW: Import customer dashboard

class WorkerDashboardScreen extends StatefulWidget {
  @override
  _WorkerDashboardScreenState createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  WorkerModel? _worker;
  bool _isLoading = true;
  bool _isAvailable = true;
  Map<String, dynamic> _ratingStats = {};

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      print('📊 Loading worker data for user: ${user.uid}');

      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      if (workerDoc.exists) {
        print('✅ Found worker by UID');
        _worker = WorkerModel.fromFirestore(workerDoc);
        _isAvailable = _worker!.availability.availableToday;

        _ratingStats = await RatingService.getWorkerRatingStats(
          _worker!.workerId!,
        );

        setState(() => _isLoading = false);
        return;
      }

      print('⚠️ Worker not found by UID, trying email query...');

      QuerySnapshot workerQuery = await FirebaseFirestore.instance
          .collection('workers')
          .where('contact.email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (workerQuery.docs.isNotEmpty) {
        print('✅ Found worker by email');
        _worker = WorkerModel.fromFirestore(workerQuery.docs.first);
        _isAvailable = _worker!.availability.availableToday;

        _ratingStats = await RatingService.getWorkerRatingStats(
          _worker!.workerId!,
        );
      } else {
        print('❌ Worker document not found');
        throw Exception(
            'Worker profile not found. Please complete registration.');
      }
    } catch (e) {
      print('❌ Error loading worker data: $e');
      _showErrorSnackBar('Failed to load worker data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool newAvailability = !_isAvailable;

      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update({
        'availability.available_today': newAvailability,
        'last_active': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isAvailable = newAvailability;
      });

      _showSuccessSnackBar(
        newAvailability ? 'You are now available' : 'You are now unavailable',
      );
    } catch (e) {
      print('❌ Error toggling availability: $e');
      _showErrorSnackBar('Failed to update availability');
    }
  }

  // NEW METHOD: Check if user has a customer account, create if needed, then switch
  Future<void> _handleCustomerAccountSwitch() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Check if customer account exists
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        // Customer account exists - switch to it
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switching to your customer account...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(Duration(seconds: 1));

        // Navigate to customer dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDashboard(),
          ),
        );
      } else {
        // No customer account exists - create it now
        await _createCustomerAccount(user);

        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer account created! Switching...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(Duration(seconds: 1));

        // Navigate to customer dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDashboard(),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('❌ Error switching to customer account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW METHOD: Create customer account for the worker
  Future<void> _createCustomerAccount(User user) async {
    try {
      // Get user data from users collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      // Generate customer ID
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String customerId = 'CUST_${timestamp}_${_generateRandomSuffix()}';

      // Get worker's name and contact info
      String customerName =
          _worker?.workerName ?? userData?['name'] ?? 'Customer';
      String firstName =
          _worker?.firstName ?? userData?['name']?.split(' ')[0] ?? '';
      String lastName = _worker?.lastName ??
          userData?['name']?.split(' ').skip(1).join(' ') ??
          '';
      String email = _worker?.contact.email ?? user.email ?? '';
      String phone = _worker?.contact.phoneNumber ?? userData?['phone'] ?? '';

      // Create customer document
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .set({
        'customer_id': customerId,
        'customer_name': customerName,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'location': null,
        'preferred_services': [],
        'preferences': {
          'notifications_enabled': true,
          'email_notifications': true,
          'sms_notifications': false,
        },
        'verified': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user document - Keep accountType as 'worker' since worker was primary
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'both', // User has both accounts now
        'customerId': customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Customer account created: $customerId');
    } catch (e) {
      print('❌ Error creating customer account: $e');
      throw Exception('Failed to create customer account: $e');
    }
  }

  // Helper method to generate random suffix for customer ID
  String _generateRandomSuffix() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return chars[(random % chars.length)];
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Worker Dashboard'),
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'Worker profile not found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadWorkerData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Dashboard'),
        backgroundColor: Color(0xFFFF9800),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
        color: Color(0xFFFF9800),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 16),
              _buildAvailabilityCard(),
              SizedBox(height: 16),
              _buildStatsCard(),
              SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // lib/screens/worker_dashboard_screen.dart
// MODIFICATION: Update _buildProfileHeader() method only
// Replace the existing _buildProfileHeader() method with this updated version

  // lib/screens/worker_dashboard_screen.dart
// MODIFICATION: Update _buildProfileHeader() method only
// Replace the existing _buildProfileHeader() method with this updated version

  // lib/screens/worker_dashboard_screen.dart
// REPLACE the _buildProfileHeader() method with this updated version
// This ensures profile pictures display correctly with proper error handling

  Widget _buildProfileHeader() {
    String? profileUrl = _worker!.profilePictureUrl;

    // Add cache-busting to prevent stale images
    if (profileUrl != null && profileUrl.isNotEmpty) {
      if (!profileUrl.contains('&t=')) {
        profileUrl = '$profileUrl&t=${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // ✅ Profile picture with error handling
            GestureDetector(
              onTap: () {
                // Navigate to edit profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                ).then((updated) {
                  // ✅ Reload data when returning from profile screen
                  if (updated == true) {
                    _loadWorkerData();
                  }
                });
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFFF9800),
                    backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                        ? NetworkImage(profileUrl) as ImageProvider
                        : null,
                    onBackgroundImageError:
                        profileUrl != null && profileUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                print(
                                    '⚠️ Error loading profile picture: $exception');
                              }
                            : null,
                    child: profileUrl == null || profileUrl.isEmpty
                        ? Text(
                            _worker!.workerName.isNotEmpty
                                ? _worker!.workerName[0].toUpperCase()
                                : 'W',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  // Small camera icon to indicate it's tappable
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFFF9800), width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 12,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _worker!.workerName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _worker!.serviceType,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${_worker!.rating.toStringAsFixed(1)} (${_worker!.jobsCompleted} jobs)',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFFFF9800)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                ).then((updated) {
                  // ✅ Reload data when returning from profile screen
                  if (updated == true) {
                    _loadWorkerData();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _isAvailable ? Icons.check_circle : Icons.cancel,
                  color: _isAvailable ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability Status',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: _isAvailable,
              onChanged: (value) => _toggleAvailability(),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Jobs',
                  _worker!.jobsCompleted.toString(),
                  Icons.work,
                  Color(0xFFFF9800),
                ),
                _buildStatItem(
                  'Rating',
                  _worker!.rating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
                _buildStatItem(
                  'Reviews',
                  (_ratingStats['totalRatings'] ?? 0).toString(),
                  Icons.rate_review,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'My Bookings',
              Icons.calendar_today,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerBookingsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Notifications',
              Icons.notifications,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerNotificationsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Reviews',
              Icons.star,
              Colors.amber,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerReviewsScreen(
                      workerId: _worker!.workerId!,
                      workerName: _worker!.workerName,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Chats',
              Icons.chat_bubble,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerChatsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Profile',
              Icons.person,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                );
              },
            ),
            // NEW: Customer Account button
            _buildActionCard(
              'Customer Account',
              Icons.shopping_bag,
              Colors.teal,
              _handleCustomerAccountSwitch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
