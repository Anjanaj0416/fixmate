// lib/screens/worker_dashboard_screen.dart
// FIXED VERSION - Added Sign Out option, removed back button, fixed performance stats counts
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
import 'customer_dashboard.dart';

class WorkerDashboardScreen extends StatefulWidget {
  @override
  _WorkerDashboardScreenState createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  WorkerModel? _worker;
  bool _isLoading = true;
  bool _isAvailable = true;
  Map<String, dynamic> _ratingStats = {};
  int _completedJobsCount = 0; // NEW: Track completed jobs count

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

        // Load rating stats with correct counts
        _ratingStats = await RatingService.getWorkerRatingStats(
          _worker!.workerId!,
        );

        // NEW: Load completed jobs count from bookings
        await _loadCompletedJobsCount();

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

        // NEW: Load completed jobs count
        await _loadCompletedJobsCount();
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

  // NEW: Load completed jobs count from bookings collection
  Future<void> _loadCompletedJobsCount() async {
    try {
      if (_worker?.workerId == null) return;

      QuerySnapshot completedBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('worker_id', isEqualTo: _worker!.workerId)
          .where('status', isEqualTo: 'BookingStatus.completed')
          .get();

      setState(() {
        _completedJobsCount = completedBookings.docs.length;
      });

      print('✅ Completed jobs count: $_completedJobsCount');
    } catch (e) {
      print('❌ Error loading completed jobs count: $e');
      _completedJobsCount = 0;
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
      });

      setState(() {
        _isAvailable = newAvailability;
      });

      _showSuccessSnackBar(
          _isAvailable ? 'Now available for work' : 'Marked as unavailable');
    } catch (e) {
      print('Error updating availability: $e');
      _showErrorSnackBar('Failed to update availability');
    }
  }

  // NEW: Handle sign out
  Future<void> _handleSignOut() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        await FirebaseAuth.instance.signOut();

        Navigator.pop(context); // Remove loading dialog

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Remove loading dialog
        _showErrorSnackBar('Error signing out: ${e.toString()}');
      }
    }
  }

  // NEW: Switch to customer account
  Future<void> _switchToCustomerAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      Navigator.pop(context);

      if (customerDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
      } else {
        bool? registerCustomer = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No Customer Account'),
            content: Text(
                'You don\'t have a customer account yet. Would you like to register as a customer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Register'),
              ),
            ],
          ),
        );

        if (registerCustomer == true) {
          // Create customer account
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(user.uid)
              .set({
            'customer_id': 'CUST_${user.uid.substring(0, 8)}',
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CustomerDashboard()),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      print('❌ Error switching account: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    }
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

    // FIXED: Wrap with WillPopScope to disable back button
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar: AppBar(
          title: Text('Worker Dashboard'),
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // FIXED: Remove back button
          actions: [
            // NEW: Add Sign Out option in menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'switch_account') {
                  _switchToCustomerAccount();
                } else if (value == 'sign_out') {
                  _handleSignOut();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'switch_account',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Switch to Customer'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sign_out',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
      ),
    );
  }

  Widget _buildProfileHeader() {
    String? profileUrl = _worker!.profilePictureUrl;

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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                ).then((updated) {
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
                        ? NetworkImage(profileUrl)
                        : null,
                    child: profileUrl == null || profileUrl.isEmpty
                        ? Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.edit, size: 12, color: Colors.white),
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
                  SizedBox(height: 4),
                  Text(
                    _worker!.serviceType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        _worker!.location.city,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                ).then((updated) {
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
    // FIXED: Use correct counts from Firebase
    int totalReviews = _ratingStats['total_reviews'] ?? 0;

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
                  _completedJobsCount
                      .toString(), // FIXED: Use completed jobs count from bookings
                  Icons.work,
                  Color(0xFFFF9800),
                ),
                _buildStatItem(
                  'Rating',
                  _worker!.rating > 0
                      ? _worker!.rating.toStringAsFixed(1)
                      : '0.0',
                  Icons.star,
                  Colors.amber,
                ),
                _buildStatItem(
                  'Reviews',
                  totalReviews
                      .toString(), // FIXED: Use reviews count from rating stats
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
                ).then((updated) {
                  if (updated == true) {
                    _loadWorkerData();
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
