// lib/screens/account_type_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';
import 'worker_registration_flow.dart';

class AccountTypeScreen extends StatefulWidget {
  @override
  _AccountTypeScreenState createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  bool _isLoading = false;
  String? _selectedType;

  Future<void> _selectAccountType(String type) async {
    setState(() {
      _isLoading = true;
      _selectedType = type;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (type == 'customer') {
        await _createCustomer(user);
      } else if (type == 'service_provider') {
        await _navigateToWorkerRegistration();
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _selectedType = null;
      });
    }
  }

  Future<void> _createCustomer(User user) async {
    try {
      // Get user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Generate customer ID with proper length
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String customerId = 'CUST_${timestamp}_${_generateRandomSuffix()}';

      // Create customer model
      CustomerModel customer = CustomerModel(
        customerId: customerId,
        customerName: userData['name'] ?? '',
        firstName: userData['name']?.split(' ')[0] ?? '',
        lastName: userData['name']?.split(' ').skip(1).join(' ') ?? '',
        email: userData['email'] ?? '',
        phoneNumber: userData['phone'] ?? '',
        location: null,
        preferredServices: [],
        preferences: CustomerPreferences(),
        verified: false,
      );

      // Save customer to Firestore
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .set(customer.toFirestore());

      // Update user document with customer reference
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'customer',
        'customerId': customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Account created successfully!');

      // Navigate to customer dashboard
      Navigator.pushReplacementNamed(context, '/customer_dashboard');
    } catch (e) {
      throw Exception('Failed to create customer: ${e.toString()}');
    }
  }

  String _generateRandomSuffix() {
    return (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();
  }

  Future<void> _navigateToWorkerRegistration() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkerRegistrationFlow()),
    );
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'How will you use FixMate?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your primary purpose',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildAccountTypeCard(
                      type: 'customer',
                      title: 'Looking for Services',
                      subtitle:
                          'Find skilled professionals for your home repairs, maintenance, and improvement projects',
                      icon: Icons.search,
                      iconColor: Color(0xFF2196F3),
                      iconBackgroundColor: Color(0xFFE3F2FD),
                      features: [
                        'Find Workers',
                        'Get Quotes',
                        'Book Services',
                      ],
                      buttonText: 'I Need Services',
                      buttonColor: Color(0xFF2196F3),
                    ),
                    SizedBox(height: 20),
                    _buildAccountTypeCard(
                      type: 'service_provider',
                      title: 'Providing Services',
                      subtitle:
                          'Offer your skills and grow your business by connecting with clients who need your expertise',
                      icon: Icons.handyman,
                      iconColor: Color(0xFFFF9800),
                      iconBackgroundColor: Color(0xFFFFF3E0),
                      features: [
                        'Get Clients',
                        'Send Quotes',
                        'Earn More',
                      ],
                      buttonText: 'I Provide Services',
                      buttonColor: Color(0xFFFF9800),
                    ),
                    SizedBox(height: 32),
                    Center(
                      child: Text(
                        'You can always switch between modes later in your profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required List<String> features,
    required String buttonText,
    required Color buttonColor,
  }) {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            SizedBox(height: 16),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 16),
            // Features
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: features.map((feature) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    SizedBox(width: 6),
                    Text(
                      feature,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _selectAccountType(type),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
