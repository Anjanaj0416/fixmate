// lib/screens/worker_dashboard_screen.dart
// ENHANCED VERSION - Beautiful UI with welcome header, no app bar
// All existing functionality preserved

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

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with TickerProviderStateMixin {
  WorkerModel? _worker;
  bool _isLoading = true;
  bool _isAvailable = true;
  Map<String, dynamic> _ratingStats = {};
  int _completedJobsCount = 0;
  int _unreadNotificationCount = 0;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
    _loadNotificationCount();

    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationCount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      QuerySnapshot unreadNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('worker_id', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      setState(() {
        _unreadNotificationCount = unreadNotifications.docs.length;
      });
    } catch (e) {
      print('❌ Error loading notification count: $e');
    }
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

        await _loadCompletedJobsCount();
      } else {
        print('❌ Worker document not found');
        throw Exception(
            'Worker profile not found. Please complete registration.');
      }
    } catch (e) {
      print('❌ Error loading worker data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCompletedJobsCount() async {
    if (_worker == null || _worker!.workerId == null) {
      print('⚠️ Cannot load completed jobs - worker ID is null');
      _completedJobsCount = 0;
      return;
    }

    try {
      QuerySnapshot completedJobs = await FirebaseFirestore.instance
          .collection('bookings')
          .where('worker_id', isEqualTo: _worker!.workerId)
          .where('status', isEqualTo: 'completed')
          .get();

      setState(() {
        _completedJobsCount = completedJobs.docs.length;
      });

      print('✅ Loaded ${_completedJobsCount} completed jobs');
    } catch (e) {
      print('❌ Error loading completed jobs count: $e');
      _completedJobsCount = 0;
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => _isLoading = true);

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

      setState(() => _isAvailable = newAvailability);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newAvailability
              ? '✅ You are now available for bookings'
              : '⏸️ You are now unavailable for bookings'),
          backgroundColor: newAvailability ? Colors.green : Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error toggling availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToCustomerAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No customer account found. Please create one.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error switching to customer account: $e');
    }
  }

  Future<void> _handleSignOut() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFE5CC)],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9800)),
          ),
        ),
      );
    }

    if (_worker == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFE5CC)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Worker profile not found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadWorkerData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFE5CC)],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadWorkerData,
              color: Color(0xFFFF9800),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    SizedBox(height: 20),
                    _buildWelcomeHeader(),
                    SizedBox(height: 20),
                    _buildProfileHeader(),
                    SizedBox(height: 16),
                    _buildAvailabilityCard(),
                    SizedBox(height: 16),
                    _buildStatsCard(),
                    SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Notification Icon
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, size: 28),
              color: Color(0xFFFF9800),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerNotificationsScreen(),
                  ),
                ).then((_) => _loadNotificationCount());
              },
            ),
            if (_unreadNotificationCount > 0)
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
                    _unreadNotificationCount > 9
                        ? '9+'
                        : _unreadNotificationCount.toString(),
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
        ),
        SizedBox(width: 8),
        // Sign Out Icon
        IconButton(
          icon: Icon(Icons.exit_to_app, size: 28),
          color: Color(0xFFF44336),
          onPressed: _handleSignOut,
          tooltip: 'Sign Out',
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF2C3E50),
              ),
              children: [
                TextSpan(text: 'Welcome back, '),
                TextSpan(
                  text: _worker!.workerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
                TextSpan(text: ' 🔧'),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your bookings, reviews, and performance\neverything you need in one place. ⚡',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
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

    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFFFF4E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkerProfileScreen(worker: _worker!),
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        _loadWorkerData();
                      }
                    });
                  },
                  child: Hero(
                    tag: 'worker_profile_${_worker!.workerId}',
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF9800).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Color(0xFFFF9800),
                            backgroundImage:
                                profileUrl != null && profileUrl.isNotEmpty
                                    ? NetworkImage(profileUrl)
                                    : null,
                            child: profileUrl == null || profileUrl.isEmpty
                                ? Icon(Icons.person,
                                    size: 35, color: Colors.white)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF9800),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child:
                                Icon(Icons.edit, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
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
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.work, size: 16, color: Color(0xFFFF9800)),
                          SizedBox(width: 4),
                          Text(
                            _worker!.serviceType,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                Icon(Icons.arrow_forward_ios,
                    color: Color(0xFFFF9800), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAvailable
                ? [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]
                : [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAvailable ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAvailable ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Availability Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isAvailable
                              ? Colors.green[800]
                              : Colors.red[800],
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
                activeTrackColor: Colors.green[200],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    int totalReviews = _ratingStats['total_reviews'] ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Color(0xFFFF9800), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Performance Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Jobs',
                    _completedJobsCount.toString(),
                    Icons.work,
                    Color(0xFFFF9800),
                  ),
                  _buildStatItem(
                    'Rating',
                    _worker!.rating > 0
                        ? _worker!.rating.toStringAsFixed(1)
                        : 'N/A',
                    Icons.star,
                    Color(0xFFFFC107),
                  ),
                  _buildStatItem(
                    'Reviews',
                    totalReviews.toString(),
                    Icons.rate_review,
                    Color(0xFF4CAF50),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
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
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        _buildActionCard(
          icon: Icons.calendar_today,
          title: 'My Bookings',
          subtitle: 'View and manage your service bookings',
          color: Color(0xFF2196F3),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkerBookingsScreen()),
          ),
        ),
        SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.favorite,
          title: 'Reviews',
          subtitle: 'Check your ratings and customer reviews',
          color: Color(0xFFE91E63),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerReviewsScreen(
                workerId: _worker!.workerId!,
                workerName: _worker!.workerName,
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.chat,
          title: 'Messages',
          subtitle: 'Chat with your customers',
          color: Color(0xFF4CAF50),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WorkerChatsScreen()),
          ),
        ),
        SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.swap_horiz,
          title: 'Switch to Customer',
          subtitle: 'Access your customer account',
          color: Color(0xFF9C27B0),
          onTap: _switchToCustomerAccount,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
