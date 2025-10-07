// lib/screens/admin_dashboard_screen.dart
// UPDATED VERSION - Beautiful UI with gradient background, animations, and modern design
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

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadStats();

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
      appBar: _currentIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              title: null,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.lightGreen.shade50],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green.shade700),
                  onPressed: _loadStats,
                  tooltip: 'Refresh Stats',
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.green.shade700),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            )
          : AppBar(
              title: Text(_getAppBarTitle()),
              backgroundColor: Colors.green.shade700,
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
        selectedItemColor: Colors.green.shade700,
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

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Users Management';
      case 2:
        return 'Reviews Management';
      case 3:
        return 'Support Inbox';
      case 4:
        return 'Admin Settings';
      default:
        return 'Admin Panel';
    }
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
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.lightGreen.shade50],
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: Colors.green.shade700),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.lightGreen.shade50],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.orange.shade400,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Welcome Back, Admin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildAnimatedStatCard(
                    'Total Customers',
                    _stats['totalUsers'].toString(),
                    Icons.people_rounded,
                    Colors.blue.shade400,
                    Colors.blue.shade50,
                    100,
                  ),
                  _buildAnimatedStatCard(
                    'Total Workers',
                    _stats['totalWorkers'].toString(),
                    Icons.engineering_rounded,
                    Colors.green.shade500,
                    Colors.green.shade50,
                    200,
                  ),
                  _buildAnimatedStatCard(
                    'Total Bookings',
                    _stats['totalBookings'].toString(),
                    Icons.book_rounded,
                    Colors.orange.shade400,
                    Colors.orange.shade50,
                    300,
                  ),
                  _buildAnimatedStatCard(
                    'Pending',
                    _stats['pendingBookings'].toString(),
                    Icons.pending_actions_rounded,
                    Colors.amber.shade600,
                    Colors.amber.shade50,
                    400,
                  ),
                  _buildAnimatedStatCard(
                    'Completed',
                    _stats['completedBookings'].toString(),
                    Icons.check_circle_rounded,
                    Colors.teal.shade500,
                    Colors.teal.shade50,
                    500,
                  ),
                  _buildAnimatedStatCard(
                    'Total Reviews',
                    _stats['totalReviews'].toString(),
                    Icons.star_rounded,
                    Colors.purple.shade400,
                    Colors.purple.shade50,
                    600,
                  ),
                ],
              ),

              SizedBox(height: 35),

              // Quick Actions Header
              Row(
                children: [
                  Icon(
                    Icons.flash_on_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Quick Actions Grid (Matching the image structure)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Manage Users',
                      'View and manage customers and workers',
                      Icons.people_rounded,
                      Colors.blue.shade500,
                      Colors.blue.shade50,
                      () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Manage Reviews',
                      'Monitor and manage user reviews',
                      Icons.star_rounded,
                      Colors.pink.shade400,
                      Colors.pink.shade50,
                      () => setState(() => _currentIndex = 2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Support Inbox',
                      'Handle customer support requests',
                      Icons.inbox_rounded,
                      Colors.green.shade500,
                      Colors.green.shade50,
                      () => setState(() => _currentIndex = 3),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Settings',
                      'Manage admin settings and profile',
                      Icons.settings_rounded,
                      Colors.orange.shade500,
                      Colors.orange.shade50,
                      () => setState(() => _currentIndex = 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Opacity(
            opacity: animValue,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.15),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: iconColor),
                    ),
                    SizedBox(height: 14),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [iconColor, iconColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
              Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
