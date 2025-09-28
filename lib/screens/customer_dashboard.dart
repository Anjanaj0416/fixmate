// lib/screens/customer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/service_constants.dart';
import 'service_request_flow.dart';
import 'customer_profile_screen.dart';

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  String _selectedLocation = 'gampaha';

  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'id': 'plumbing',
      'name': 'Plumbing',
      'icon': Icons.plumbing,
      'color': Colors.blue,
      'serviceCount': 6,
      'description': 'Professional plumbing services',
    },
    {
      'id': 'electrical',
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Colors.orange,
      'serviceCount': 6,
      'description': 'Expert electrical solutions',
    },
    {
      'id': 'house_cleaning',
      'name': 'House Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.green,
      'serviceCount': 5,
      'description': 'Professional cleaning services',
    },
    {
      'id': 'handyman',
      'name': 'Handyman',
      'icon': Icons.handyman,
      'color': Colors.brown,
      'serviceCount': 8,
      'description': 'General repair and maintenance',
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
      'id': 'ac_repair',
      'name': 'AC Repair',
      'icon': Icons.ac_unit,
      'color': Colors.cyan,
      'serviceCount': 3,
      'description': 'AC installation and repair',
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
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
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
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServicesSection(),
                  SizedBox(height: 24),
                  _buildQuickActionsSection(),
                  SizedBox(height: 24),
                  _buildRecentBookingsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocation,
                onChanged: (value) =>
                    setState(() => _selectedLocation = value!),
                items: [
                  DropdownMenuItem(value: 'gampaha', child: Text('Gampaha')),
                  DropdownMenuItem(value: 'colombo', child: Text('Colombo')),
                  DropdownMenuItem(value: 'kandy', child: Text('Kandy')),
                  DropdownMenuItem(value: 'galle', child: Text('Galle')),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue[100],
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for services or workers...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onTap: () {
          // TODO: Navigate to search screen
        },
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _serviceCategories.length,
          itemBuilder: (context, index) {
            final service = _serviceCategories[index];
            return _buildServiceCard(service);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => _selectService(service),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
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

  void _selectService(Map<String, dynamic> service) {
    // Show service selection modal similar to your plumbing example
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildServiceSelectionModal(service),
    );
  }

  Widget _buildServiceSelectionModal(Map<String, dynamic> service) {
    List<String> subServices = ServiceTypes.getSubServices(service['id']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  service['name'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select a specific service:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: subServices.length,
              itemBuilder: (context, index) {
                return _buildSubServiceTile(
                  service['id'],
                  subServices[index],
                  service['name'],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubServiceTile(
      String serviceId, String subService, String serviceName) {
    IconData icon;
    switch (subService.toLowerCase()) {
      case 'general plumbing':
        icon = Icons.plumbing;
        break;
      case 'pipe installation':
        icon = Icons.pipe;
        break;
      case 'leak repair':
        icon = Icons.water_drop;
        break;
      case 'drain cleaning':
        icon = Icons.cleaning_services;
        break;
      case 'water heater service':
        icon = Icons.hot_tub;
        break;
      case 'toilet repair':
        icon = Icons.wc;
        break;
      case 'faucet installation':
        icon = Icons.tap;
        break;
      default:
        icon = Icons.build;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          _navigateToServiceRequest(serviceId, subService, serviceName);
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
          subService,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subService == 'General Plumbing'
            ? Text('Not sure? Get a general consultation')
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  void _navigateToServiceRequest(
      String serviceId, String subService, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceRequestFlow(
          serviceType: serviceId,
          subService: subService,
          serviceName: serviceName,
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Emergency Service',
                Icons.emergency,
                Colors.red,
                () => _requestEmergencyService(),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                'Schedule Later',
                Icons.schedule,
                Colors.green,
                () => _scheduleService(),
              ),
            ),
          ],
        ),
      ],
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
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Placeholder for recent bookings
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.bookmark_border, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No recent bookings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Book your first service to see it here',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsScreen() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Bookings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your service bookings will appear here',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() => _currentIndex = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Book a Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxScreen() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Messages with service providers will appear here',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return CustomerProfileScreen();
  }

  void _requestEmergencyService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Service'),
        content: Text('Call emergency services or book urgent assistance?'),
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

// Extension to ServiceTypes for getting sub-services
extension ServiceTypesExtension on ServiceTypes {
  static List<String> getSubServices(String serviceType) {
    switch (serviceType) {
      case 'plumbing':
        return [
          'General Plumbing',
          'Pipe Installation',
          'Leak Repair',
          'Drain Cleaning',
          'Water Heater Service',
          'Toilet Repair',
          'Faucet Installation',
        ];
      case 'electrical':
        return [
          'General Electrical',
          'Wiring Installation',
          'Circuit Repair',
          'Outlet Installation',
          'Light Fixture Setup',
          'Panel Upgrade',
          'Emergency Electrical',
        ];
      case 'house_cleaning':
        return [
          'Regular Cleaning',
          'Deep Cleaning',
          'Post-Construction Cleanup',
          'Window Cleaning',
          'Carpet Cleaning',
        ];
      case 'handyman':
        return [
          'General Repairs',
          'Furniture Assembly',
          'Wall Mounting',
          'Door/Window Repair',
          'Painting Touch-ups',
          'Minor Installations',
          'Maintenance Work',
          'Shelf Installation',
        ];
      case 'painting':
        return [
          'Interior Painting',
          'Exterior Painting',
          'Wall Preparation',
          'Touch-up Work',
        ];
      case 'ac_repair':
        return [
          'AC Installation',
          'AC Repair',
          'AC Maintenance',
        ];
      default:
        return ['General Service'];
    }
  }
}
