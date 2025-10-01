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

      // FIXED: Generate customer ID with proper length
      // Use full timestamp + random suffix for unique, longer ID
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
        location: null, // Will be set later when user searches for services
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

  // Generate random 4-digit suffix for uniqueness
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
      appBar: AppBar(
        title: Text('Select Account Type'),
        backgroundColor: Color(0xFF2196F3),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Choose Your Account Type',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  _buildAccountTypeCard(
                    type: 'customer',
                    title: 'Customer',
                    icon: Icons.person,
                    description: 'Find and book service professionals',
                    color: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  _buildAccountTypeCard(
                    type: 'service_provider',
                    title: 'Service Provider',
                    icon: Icons.handyman,
                    description: 'Offer your services to customers',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    bool isSelected = _selectedType == type;

    return InkWell(
      onTap: () => _selectAccountType(type),
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 60, color: color),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
