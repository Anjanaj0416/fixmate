// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_manage_users_screen.dart';
import 'admin_manage_reviews_screen.dart';
import 'admin_settings_screen.dart';
import 'welcome_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalWorkers': 0,
    'totalBookings': 0,
    'pendingBookings': 0,
    'completedBookings': 0,
    'totalReviews': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      // Count customers
      QuerySnapshot customersSnapshot =
          await FirebaseFirestore.instance.collection('customers').get();

      // Count workers
      QuerySnapshot workersSnapshot =
          await FirebaseFirestore.instance.collection('workers').get();

      // Count bookings
      QuerySnapshot bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      // Count pending bookings
      QuerySnapshot pendingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'BookingStatus.requested')
          .get();

      // Count completed bookings
      QuerySnapshot completedSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'BookingStatus.completed')
          .get();

      // Count reviews
      QuerySnapshot reviewsSnapshot =
          await FirebaseFirestore.instance.collection('reviews').get();

      setState(() {
        _stats['totalUsers'] = customersSnapshot.docs.length;
        _stats['totalWorkers'] = workersSnapshot.docs.length;
        _stats['totalBookings'] = bookingsSnapshot.docs.length;
        _stats['pendingBookings'] = pendingSnapshot.docs.length;
        _stats['completedBookings'] = completedSnapshot.docs.length;
        _stats['totalReviews'] = reviewsSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardHome(),
          AdminManageUsersScreen(),
          AdminManageReviewsScreen(),
          AdminSettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHome() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Users',
                  _stats['totalUsers'].toString(),
                  Icons.person,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Total Workers',
                  _stats['totalWorkers'].toString(),
                  Icons.engineering,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Bookings',
                  _stats['totalBookings'].toString(),
                  Icons.book,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Pending',
                  _stats['pendingBookings'].toString(),
                  Icons.pending,
                  Colors.amber,
                ),
                _buildStatCard(
                  'Completed',
                  _stats['completedBookings'].toString(),
                  Icons.check_circle,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Total Reviews',
                  _stats['totalReviews'].toString(),
                  Icons.star,
                  Colors.purple,
                ),
              ],
            ),

            SizedBox(height: 30),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            _buildQuickActionButton(
              'Manage Users',
              Icons.people,
              () => setState(() => _currentIndex = 1),
            ),
            SizedBox(height: 12),
            _buildQuickActionButton(
              'Manage Reviews',
              Icons.star,
              () => setState(() => _currentIndex = 2),
            ),
            SizedBox(height: 12),
            _buildQuickActionButton(
              'View All Bookings',
              Icons.book,
              () {
                // Navigate to bookings view (to be implemented)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bookings view coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF2196F3)),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
