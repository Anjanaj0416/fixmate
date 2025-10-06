// lib/screens/customer_dashboard.dart
// MINIMAL CHANGES - Only added Sign Out option and removed back button
// NO other interface changes
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/service_constants.dart';
import 'service_request_flow.dart';
import 'customer_profile_screen.dart';
import 'customer_bookings_screen.dart';
import 'ai_chat_screen.dart';
import 'customer_chats_screen.dart';
import 'customer_notifications_screen.dart';
import 'worker_registration_flow.dart';
import 'worker_dashboard_screen.dart';
import 'dart:async';

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  String _userLocation = 'Loading...';
  int _unreadNotificationCount = 0;
  String? _customerId;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadCustomerIdAndListenToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomerIdAndListenToNotifications() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              _customerId = customerData['customer_id'] ?? user.uid;
            });
          }

          _notificationSubscription = FirebaseFirestore.instance
              .collection('notifications')
              .where('recipient_type', isEqualTo: 'customer')
              .where('read', isEqualTo: false)
              .snapshots()
              .listen((snapshot) {
            int count = snapshot.docs.where((doc) {
              var data = doc.data();
              String? customerId = data['customer_id'];
              String? recipientId = data['recipient_id'];
              return customerId == _customerId || recipientId == _customerId;
            }).length;

            if (mounted) {
              setState(() {
                _unreadNotificationCount = count;
              });
            }
          });
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String? nearestTown = userData['nearestTown'];

          if (nearestTown != null && nearestTown.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userLocation = nearestTown;
              });
            }
            return;
          }
        }

        DocumentSnapshot customerDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(user.uid)
            .get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;

          if (customerData['location'] != null) {
            String? city = customerData['location']['city'];
            if (city != null && city.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _userLocation = city;
                });
              }
              return;
            }
          }
        }

        if (mounted) {
          setState(() {
            _userLocation = 'Location not set';
          });
        }
      }
    } catch (e) {
      print('Error loading user location: $e');
      if (mounted) {
        setState(() {
          _userLocation = 'Location unavailable';
        });
      }
    }
  }

  // EXISTING METHOD - No changes
  Future<void> _handleWorkerAccountSwitch() async {
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

      if (customerDoc.exists) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switching to your customer account...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(Duration(seconds: 1));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDashboard(),
          ),
        );
      } else {
        DocumentSnapshot workerDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .get();

        if (workerDoc.exists) {
          Navigator.pop(context);

          bool? switchAccount = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Worker Account Found'),
              content: Text(
                  'You have a worker account. Would you like to switch to it?'),
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
                  child: Text('Switch'),
                ),
              ],
            ),
          );

          if (switchAccount == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => WorkerDashboardScreen(),
              ),
            );
          }
        } else {
          Navigator.pop(context);

          bool? registerWorker = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Become a Worker'),
              content: Text(
                  'You don\'t have a worker account yet. Would you like to register as a worker?'),
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

          if (registerWorker == true) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkerRegistrationFlow(),
              ),
            );
          }
        }
      }
    } catch (e) {
      Navigator.pop(context);
      print('❌ Error switching account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW METHOD: Handle sign out - ONLY NEW ADDITION
  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                await FirebaseAuth.instance.signOut();

                Navigator.pop(context);

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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'id': 'ac_repair',
      'name': 'AC Repair',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
      'serviceCount': 4,
      'description': 'AC installation, repair and maintenance',
    },
    {
      'id': 'appliance_repair',
      'name': 'Appliance Repair',
      'icon': Icons.kitchen,
      'color': Colors.orange,
      'serviceCount': 7,
      'description': 'Repair for all home appliances',
    },
    {
      'id': 'carpentry',
      'name': 'Carpentry',
      'icon': Icons.carpenter,
      'color': Colors.brown,
      'serviceCount': 6,
      'description': 'Custom furniture and woodwork',
    },
    {
      'id': 'cleaning',
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.green,
      'serviceCount': 5,
      'description': 'Professional cleaning services',
    },
    {
      'id': 'electrical',
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Colors.amber,
      'serviceCount': 7,
      'description': 'Expert electrical solutions',
    },
    {
      'id': 'gardening',
      'name': 'Gardening',
      'icon': Icons.grass,
      'color': Colors.green,
      'serviceCount': 5,
      'description': 'Garden maintenance and landscaping',
    },
    {
      'id': 'painting',
      'name': 'Painting',
      'icon': Icons.format_paint,
      'color': Colors.purple,
      'serviceCount': 4,
      'description': 'Interior and exterior painting',
    },
    {
      'id': 'plumbing',
      'name': 'Plumbing',
      'icon': Icons.plumbing,
      'color': Colors.blue,
      'serviceCount': 8,
      'description': 'Plumbing repairs and installations',
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> _screens = [
      _buildHomeScreen(),
      CustomerBookingsScreen(),
      CustomerChatsScreen(),
      CustomerProfileScreen(),
    ];

    // CHANGE 2: Wrap with WillPopScope to disable back button
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Inbox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            expandedHeight: 120,
            // CHANGE 2: Add automaticallyImplyLeading: false to remove back button
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.fromLTRB(16, 50, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Welcome back!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _userLocation,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // CHANGE 1: Add sign out button here
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.notifications_outlined),
                                  color: Colors.black87,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerNotificationsScreen(),
                                      ),
                                    );
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
                                            : _unreadNotificationCount
                                                .toString(),
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
                            // CHANGE 1: NEW - Sign out menu button
                            IconButton(
                              icon: Icon(Icons.logout),
                              color: Colors.black87,
                              tooltip: 'Sign Out',
                              onPressed: _handleSignOut,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                _buildAIAssistantBanner(),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all services
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _serviceCategories.length,
                    itemBuilder: (context, index) {
                      return _buildServiceCard(_serviceCategories[index]);
                    },
                  ),
                ),
                SizedBox(height: 24),
                _buildQuickActions(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7B2CBF).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIChatScreen(),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help? Ask AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upload a photo or chat to identify your issue',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 130,
                margin: EdgeInsets.only(right: 12),
                child: _buildQuickActionCard(
                  'My Bookings',
                  Icons.book_online,
                  Colors.blue,
                  () {
                    setState(() => _currentIndex = 1);
                  },
                ),
              ),
              Container(
                width: 130,
                margin: EdgeInsets.only(right: 12),
                child: _buildQuickActionCard(
                  'Favorites',
                  Icons.favorite,
                  Colors.red,
                  () {
                    // Navigate to favorites
                  },
                ),
              ),
              Container(
                width: 130,
                margin: EdgeInsets.only(right: 12),
                child: _buildQuickActionCard(
                  'Support',
                  Icons.help_outline,
                  Colors.green,
                  () {
                    // Navigate to support
                  },
                ),
              ),
              Container(
                width: 130,
                child: _buildQuickActionCard(
                  'Worker Account',
                  Icons.work_outline,
                  Colors.orange,
                  _handleWorkerAccountSwitch,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => _showServiceOptions(
        service['id'],
        service['name'],
        service['icon'],
        service['color'],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: service['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                service['icon'],
                size: 32,
                color: service['color'],
              ),
            ),
            SizedBox(height: 12),
            Text(
              service['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${service['serviceCount']} services',
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

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceOptions(
      String serviceId, String serviceName, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Choose how to proceed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20),
                children: [
                  _buildServiceOption(
                    'Find Workers',
                    'Browse and book skilled workers',
                    Icons.search,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceRequestFlow(
                            serviceType: serviceId,
                            subService: serviceId,
                            serviceName: serviceName,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  _buildServiceOption(
                    'AI Assistant',
                    'Get instant help with our AI',
                    Icons.smart_toy,
                    Colors.purple,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIChatScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
