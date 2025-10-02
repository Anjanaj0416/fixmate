// lib/screens/admin_dashboard_screen.dart
// UPDATED VERSION - Added Inbox tab for support chats
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_manage_users_screen.dart';
import 'admin_manage_reviews_screen.dart';
import 'admin_inbox_screen.dart';
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
        _stats = {
          'totalUsers': customersSnapshot.size,
          'totalWorkers': workersSnapshot.size,
          'totalBookings': bookingsSnapshot.size,
          'pendingBookings': pendingSnapshot.size,
          'completedBookings': completedSnapshot.size,
          'totalReviews': reviewsSnapshot.size,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
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
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return AdminManageUsersScreen();
      case 2:
        return AdminManageReviewsScreen();
      case 3:
        return AdminInboxScreen();
      case 4:
        return AdminSettingsScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Customers',
                _stats['totalUsers'].toString(),
                Icons.people,
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
            'Support Inbox',
            Icons.inbox,
            () => setState(() => _currentIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
            Icon(icon, color: Colors.deepPurple),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (route) => false,
      );
    }
  }
}
