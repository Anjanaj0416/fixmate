// lib/screens/customer_dashboard.dart
// ENHANCED VERSION - Beautiful UI with animations, gradients, and modern design
// All existing functionality preserved, only visual enhancements
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
import 'customer_favorites_screen.dart';
import 'admin_support_chat_screen.dart';

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _userLocation = 'Loading...';
  String _userName = 'User';
  String _userInitials = 'U';
  int _unreadNotificationCount = 0;
  String? _customerId;
  StreamSubscription? _notificationSubscription;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadCustomerIdAndListenToNotifications();
    _loadUserName();

    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
    _notificationSubscription?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
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
          String fullName = customerData['full_name'] ??
              customerData['name'] ??
              customerData['customer_name'] ??
              'User';

          if (mounted) {
            setState(() {
              _userName = fullName.split(' ').first;
              _userInitials = _getInitials(fullName);
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
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

  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
      'color': Color(0xFF00BCD4),
      'serviceCount': 4,
      'description': 'AC installation, repair and maintenance',
    },
    {
      'id': 'appliance_repair',
      'name': 'Appliance Repair',
      'icon': Icons.kitchen,
      'color': Color(0xFFFF6F00),
      'serviceCount': 7,
      'description': 'Repair for all home appliances',
    },
    {
      'id': 'carpentry',
      'name': 'Carpentry',
      'icon': Icons.carpenter,
      'color': Color(0xFF795548),
      'serviceCount': 6,
      'description': 'Custom furniture and woodwork',
    },
    {
      'id': 'cleaning',
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
      'color': Color(0xFF4CAF50),
      'serviceCount': 5,
      'description': 'Professional cleaning services',
    },
    {
      'id': 'electrical',
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Color(0xFFFFC107),
      'serviceCount': 7,
      'description': 'Expert electrical solutions',
    },
    {
      'id': 'gardening',
      'name': 'Gardening',
      'icon': Icons.grass,
      'color': Color(0xFF8BC34A),
      'serviceCount': 5,
      'description': 'Garden maintenance and landscaping',
    },
    {
      'id': 'painting',
      'name': 'Painting',
      'icon': Icons.format_paint,
      'color': Color(0xFF9C27B0),
      'serviceCount': 4,
      'description': 'Interior and exterior painting',
    },
    {
      'id': 'plumbing',
      'name': 'Plumbing',
      'icon': Icons.plumbing,
      'color': Color(0xFF2196F3),
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

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xFF2196F3),
            unselectedItemColor: Colors.grey[400],
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.book_outlined, Icons.book, 1),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.message_outlined, Icons.message, 2),
                label: 'Inbox',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline, Icons.person, 3),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    bool isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF2196F3).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: 24,
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFE3F2FD),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildEnhancedAppBar(),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    _buildEnhancedAIBanner(),
                    SizedBox(height: 28),
                    _buildSectionHeader('Popular Services', onSeeAll: () {}),
                    SizedBox(height: 16),
                    _buildEnhancedServiceGrid(),
                    SizedBox(height: 28),
                    _buildSectionHeader('Quick Actions'),
                    SizedBox(height: 16),
                    _buildEnhancedQuickActions(),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fix for _buildEnhancedAppBar() method in customer_dashboard.dart
// Replace the existing _buildEnhancedAppBar() method with this fixed version

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      expandedHeight: 160, // ✅ INCREASED from 145 to 160 to fix overflow
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.fromLTRB(20, 50, 20, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF5F7FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ REDUCED font sizes slightly to prevent overflow
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hi ',
                            style: TextStyle(
                              fontSize: 20, // ✅ REDUCED from 22
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: '$_userName,',
                            style: TextStyle(
                              fontSize: 20, // ✅ REDUCED from 22
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'How can I help you today?',
                      style: TextStyle(
                        fontSize: 22, // ✅ REDUCED from 24
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4), // ✅ REDUCED from 6
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color(0xFF2196F3),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _userLocation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNotificationButton(),
                  SizedBox(height: 4),
                  _buildSignOutButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined),
            color: Color(0xFF1A1A1A),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerNotificationsScreen(),
                ),
              );
            },
          ),
        ),
        if (_unreadNotificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4444), Color(0xFFFF1744)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
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
          ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.logout_outlined),
        color: Color(0xFFFF4444),
        tooltip: 'Sign Out',
        onPressed: _handleSignOut,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: Color(0xFF2196F3)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAIBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AIChatScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7B2CBF),
                  Color(0xFF9D4EDD),
                  Color(0xFFC77DFF)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF7B2CBF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant 🤖',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Upload a photo or chat to identify your issue instantly',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedServiceGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _serviceCategories.length,
        itemBuilder: (context, index) {
          return _buildEnhancedServiceCard(_serviceCategories[index], index);
        },
      ),
    );
  }

  Widget _buildEnhancedServiceCard(Map<String, dynamic> service, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () => _showServiceOptions(
                service['id'],
                service['name'],
                service['icon'],
                service['color'],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: service['color'].withOpacity(0.15),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            service['color'],
                            service['color'].withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: service['color'].withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        service['icon'],
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      service['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: service['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${service['serviceCount']} services',
                        style: TextStyle(
                          fontSize: 12,
                          color: service['color'],
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildEnhancedQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'My Bookings',
        'subtitle': 'View and manage your service bookings',
        'icon': Icons.book_online,
        'gradient': [Color(0xFF2196F3), Color(0xFF1976D2)],
        'onTap': () => setState(() => _currentIndex = 1),
      },
      {
        'title': 'Favorites',
        'subtitle': 'Your saved workers and services',
        'icon': Icons.favorite,
        'gradient': [Color(0xFFE91E63), Color(0xFFC2185B)],
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CustomerFavoritesScreen()),
            ),
      },
      {
        'title': 'Support',
        'subtitle': 'Get help with any issues or questions',
        'icon': Icons.help_outline,
        'gradient': [Color(0xFF4CAF50), Color(0xFF388E3C)],
        'onTap': () => _navigateToAdminSupport(),
      },
      {
        'title': 'Worker Account',
        'subtitle': 'Switch to your worker dashboard',
        'icon': Icons.work_outline,
        'gradient': [Color(0xFFFF9800), Color(0xFFF57C00)],
        'onTap': _handleWorkerAccountSwitch,
      },
    ];

    return Column(
      children: actions.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> action = entry.value;
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildEnhancedQuickActionCard(action),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedQuickActionCard(Map<String, dynamic> action) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action['onTap'],
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: action['gradient'],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: action['gradient'][0].withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    action['icon'],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action['title'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        action['subtitle'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAdminSupport() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to contact support'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String customerName = 'Customer';
    try {
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(currentUser.uid)
          .get();

      if (customerDoc.exists) {
        Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
        customerName = data['full_name'] ??
            data['name'] ??
            data['customer_name'] ??
            'Customer';
      }
    } catch (e) {
      print('Error getting customer name: $e');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSupportChatScreen(
          userId: currentUser.uid,
          userName: customerName,
          userType: 'customer',
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
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
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
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(24),
                children: [
                  _buildServiceOption(
                    'Find Workers',
                    'Browse and book skilled workers',
                    Icons.search,
                    Color(0xFF2196F3),
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
                  SizedBox(height: 16),
                  _buildServiceOption(
                    'AI Assistant',
                    'Get instant help with our AI',
                    Icons.smart_toy,
                    Color(0xFF9C27B0),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
