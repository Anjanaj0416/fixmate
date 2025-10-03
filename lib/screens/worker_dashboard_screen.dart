// lib/screens/worker_dashboard_screen.dart
// ENHANCED VERSION - Added Chat/Messages navigation
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../screens/worker_profile_screen.dart';
import '../screens/worker_bookings_screen.dart';
import '../screens/worker_reviews_screen.dart';
import '../screens/worker_chats_screen.dart'; // NEW IMPORT
import '../services/rating_service.dart';
import 'worker_chats_screen.dart';
import 'worker_notifications_screen.dart';

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

      setState(() => _isAvailable = !_isAvailable);

      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update({
        'availability.available_today': _isAvailable,
        'availability.updated_at': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar(
        _isAvailable ? 'You are now available' : 'You are now unavailable',
      );
    } catch (e) {
      setState(() => _isAvailable = !_isAvailable);
      _showErrorSnackBar('Failed to update availability');
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
        appBar: AppBar(
          title: Text('Worker Dashboard'),
          backgroundColor: Color(0xFFFF9800),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Worker Dashboard'),
          backgroundColor: Color(0xFFFF9800),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Failed to load worker profile'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWorkerData,
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
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('recipient_type', isEqualTo: 'worker')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;

              if (snapshot.hasData && _worker != null) {
                // Filter for this specific worker
                unreadCount = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String? workerId = data['worker_id'];
                  String? recipientId = data['recipient_id'];
                  return workerId == _worker!.workerId ||
                      recipientId == _worker!.workerId;
                }).length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWorkerData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
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
              _buildRatingsCard(),
              SizedBox(height: 16),
              _buildQuickStats(),
              SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFFF9800),
              child: Text(
                _worker!.firstName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
                      fontSize: 20,
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
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '${_worker!.rating.toStringAsFixed(1)} (${_worker!.jobsCompleted} jobs)',
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
              icon: Icon(Icons.edit, color: Color(0xFFFF9800)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxScreen() {
    // NEW: Show actual worker chat list instead of placeholder
    return WorkerChatsScreen();
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
                  size: 28,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability Status',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 18,
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

  Widget _buildRatingsCard() {
    if (_ratingStats.isEmpty) {
      return SizedBox.shrink();
    }

    double avgRating = _ratingStats['average_rating'] ?? 0.0;
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
              'Your Ratings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                SizedBox(width: 8),
                Text(
                  avgRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '($totalReviews reviews)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Completed',
                  _worker!.jobsCompleted.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Rating',
                  _worker!.rating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
                _buildStatItem(
                  'Reviews',
                  (_ratingStats['total_reviews'] ?? 0).toString(),
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
            // ADD THIS: Notifications card
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
