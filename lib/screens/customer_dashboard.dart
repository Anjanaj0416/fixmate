// lib/screens/customer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/service_constants.dart';
import 'service_request_flow.dart';
import 'customer_profile_screen.dart';
import 'customer_bookings_screen.dart';

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  String _selectedLocation = 'gampaha';

  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'id': 'ac_repair',
      'name': 'Ac Repair',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
      'serviceCount': 5,
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
      'color': Colors.lightGreen,
      'serviceCount': 4,
      'description': 'Landscaping and garden care',
    },
    {
      'id': 'general_maintenance',
      'name': 'General Maintenance',
      'icon': Icons.handyman,
      'color': Colors.grey,
      'serviceCount': 5,
      'description': 'General repair and maintenance',
    },
    {
      'id': 'masonry',
      'name': 'Masonry',
      'icon': Icons.foundation,
      'color': Colors.blueGrey,
      'serviceCount': 5,
      'description': 'Stone and brick work',
    },
    {
      'id': 'painting',
      'name': 'Painting',
      'icon': Icons.format_paint,
      'color': Colors.purple,
      'serviceCount': 6,
      'description': 'Interior and exterior painting',
    },
    {
      'id': 'plumbing',
      'name': 'Plumbing',
      'icon': Icons.plumbing,
      'color': Colors.blue,
      'serviceCount': 7,
      'description': 'Professional plumbing services',
    },
    {
      'id': 'roofing',
      'name': 'Roofing',
      'icon': Icons.roofing,
      'color': Colors.red,
      'serviceCount': 5,
      'description': 'Roof installation and repair',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          _buildBookingsScreen(),
          _buildInboxScreen(),
          _buildProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
    );
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            expandedHeight: 120,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  _selectedLocation
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _showEmergencyDialog,
                              icon: Icon(Icons.warning,
                                  color: Colors.red, size: 28),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.notifications_outlined,
                                  color: Colors.grey[700], size: 28),
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

          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
              ),
            ),
          ),

          // Emergency Banner
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Need urgent help? Get 24/7 assistance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showEmergencyDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Call Now'),
                  ),
                ],
              ),
            ),
          ),

          // Services Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
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
                      final service = _serviceCategories[index];
                      return _buildServiceCard(service);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          'Schedule Service',
                          Icons.schedule,
                          Colors.blue,
                          _scheduleService,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          'View Bookings',
                          Icons.list_alt,
                          Colors.green,
                          () => setState(() => _currentIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
              SizedBox(height: 4),
              Text(
                service['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
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

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
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
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsScreen() {
    return CustomerBookingsScreen();
  }

  Widget _buildInboxScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Messages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return CustomerProfileScreen();
  }

  void _showServiceOptions(
      String serviceId, String serviceName, IconData icon, Color color) {
    // Get categories for the selected service
    List<String> categories = ServiceTypes.getCategories(serviceId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
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
                          'Choose a category',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Categories list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryTile(
                      serviceId, categories[index], serviceName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      String serviceId, String category, String serviceName) {
    IconData icon = _getCategoryIcon(serviceId, category);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          _navigateToServiceRequest(serviceId, category, serviceName);
        },
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        title: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  IconData _getCategoryIcon(String serviceId, String category) {
    // Return appropriate icons based on service and category - using only standard Flutter icons
    switch (serviceId) {
      case 'ac_repair':
        switch (category.toLowerCase()) {
          case 'window units':
            return Icons.window;
          case 'central ac':
            return Icons.ac_unit;
          case 'split systems':
            return Icons.view_column; // Fixed: replaced split_screen
          case 'maintenance':
            return Icons.build;
          case 'installation':
            return Icons.construction;
          default:
            return Icons.ac_unit;
        }
      case 'appliance_repair':
        switch (category.toLowerCase()) {
          case 'refrigerator':
            return Icons.kitchen;
          case 'dishwasher':
            return Icons.local_laundry_service;
          case 'microwave':
            return Icons.microwave;
          case 'washing machine':
            return Icons.local_laundry_service;
          case 'oven & stove':
            return Icons.soup_kitchen;
          case 'dryer':
            return Icons.dry_cleaning;
          case 'emergency service':
            return Icons.emergency;
          default:
            return Icons.kitchen;
        }
      case 'carpentry':
        switch (category.toLowerCase()) {
          case 'custom furniture':
            return Icons.chair;
          case 'restoration':
            return Icons.restore;
          case 'repairs':
            return Icons.build;
          case 'decorative':
            return Icons.palette;
          case 'cabinet making':
            return Icons.kitchen;
          case 'wooden flooring':
            return Icons.layers;
          default:
            return Icons.carpenter;
        }
      case 'cleaning':
        switch (category.toLowerCase()) {
          case 'deep cleaning':
            return Icons.cleaning_services;
          case 'post-construction':
            return Icons.construction;
          case 'regular maintenance':
            return Icons.schedule;
          case 'carpet cleaning':
            return Icons.cleaning_services;
          case 'upholstery cleaning':
            return Icons.weekend;
          default:
            return Icons.cleaning_services;
        }
      case 'electrical':
        switch (category.toLowerCase()) {
          case 'installation':
            return Icons.electrical_services;
          case 'wiring':
            return Icons.cable;
          case 'safety inspection':
            return Icons.security;
          case 'emergency service':
            return Icons.emergency;
          case 'lighting systems':
            return Icons.lightbulb;
          case 'solar panel setup':
            return Icons.solar_power;
          case 'maintenance':
            return Icons.build;
          default:
            return Icons.electrical_services;
        }
      case 'gardening':
        switch (category.toLowerCase()) {
          case 'landscaping':
            return Icons.landscape;
          case 'lawn care':
            return Icons.grass;
          case 'tree trimming':
            return Icons.park;
          case 'irrigation systems':
            return Icons.water_drop;
          default:
            return Icons.grass;
        }
      case 'general_maintenance':
        switch (category.toLowerCase()) {
          case 'property upkeep':
            return Icons.home_repair_service;
          case 'preventive maintenance':
            return Icons.schedule;
          case 'multiple repairs':
            return Icons.build;
          case 'furniture assembly':
            return Icons.chair;
          case 'small fixture replacements':
            return Icons.settings;
          default:
            return Icons.handyman;
        }
      case 'masonry':
        switch (category.toLowerCase()) {
          case 'stone work':
            return Icons.foundation;
          case 'brick work':
            return Icons.apartment;
          case 'concrete':
            return Icons.layers; // Fixed: replaced concrete
          case 'tile setting':
            return Icons.grid_on;
          case 'wall finishing':
            return Icons.format_paint;
          default:
            return Icons.foundation;
        }
      case 'painting':
        switch (category.toLowerCase()) {
          case 'interior':
            return Icons.home;
          case 'exterior':
            return Icons.home_outlined;
          case 'commercial':
            return Icons.business;
          case 'decorative':
            return Icons.palette;
          case 'waterproofing':
            return Icons.water_drop;
          case 'wall textures':
            return Icons.texture;
          default:
            return Icons.format_paint;
        }
      case 'plumbing':
        switch (category.toLowerCase()) {
          case 'installation':
            return Icons.plumbing;
          case 'water heater service':
            return Icons.hot_tub;
          case 'emergency repairs':
            return Icons.emergency;
          case 'maintenance':
            return Icons.build;
          case 'drain cleaning':
            return Icons.cleaning_services;
          case 'pipe replacement':
            return Icons.straighten;
          case 'bathroom fittings':
            return Icons.bathroom;
          default:
            return Icons.plumbing;
        }
      case 'roofing':
        switch (category.toLowerCase()) {
          case 'roof installation':
            return Icons.roofing;
          case 'leak repair':
            return Icons.water_drop;
          case 'tile replacement':
            return Icons.grid_on;
          case 'waterproofing':
            return Icons.umbrella;
          case 'gutter maintenance':
            return Icons.stairs;
          default:
            return Icons.roofing;
        }
      default:
        return Icons.build;
    }
  }

  void _navigateToServiceRequest(
      String serviceType, String subService, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceRequestFlow(
          serviceType: serviceType,
          subService: subService,
          serviceName: serviceName,
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Service'),
          ],
        ),
        content: Text(
          'Need immediate assistance? Our emergency service team is available 24/7 for urgent repairs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement emergency service request
            },
            child: Text('Request'),
          ),
        ],
      ),
    );
  }

  void _scheduleService() {
    // TODO: Navigate to schedule service screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule service feature coming soon!')),
    );
  }
}
