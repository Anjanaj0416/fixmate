import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../services/id_generator_service.dart';
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

      // Generate structured customer ID: CU_0001
      String customerId = await IDGeneratorService.generateCustomerId();

      // Create customer model
      CustomerModel customer = CustomerModel(
        customerId: customerId,
        customerName: userData['name'] ?? '',
        firstName: userData['name']?.split(' ')[0] ?? '',
        lastName: userData['name']?.split(' ').skip(1).join(' ') ?? '',
        email: userData['email'] ?? '',
        phoneNumber: userData['phone'] ?? '',
        location: userData['location'], // Get location from user signup
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
        'customer_id': customerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Account created successfully!');

      // Navigate to customer dashboard
      await Future.delayed(Duration(seconds: 1));

      Navigator.pushNamedAndRemoveUntil(
          context, '/customer_dashboard', (route) => false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _navigateToWorkerRegistration() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update user document to indicate worker registration started
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'service_provider_pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Navigate to worker registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WorkerRegistrationFlow()),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text('Select Account Type', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How would you like to use FixMate?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Choose your account type to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),

              // Customer Card
              _buildAccountTypeCard(
                title: 'Customer',
                description: 'Find and hire skilled workers for your needs',
                icon: Icons.person_outline,
                color: Color(0xFF2196F3),
                onTap: () => _selectAccountType('customer'),
                isLoading: _isLoading && _selectedType == 'customer',
              ),
              SizedBox(height: 20),

              // Service Provider Card
              _buildAccountTypeCard(
                title: 'Service Provider',
                description: 'Offer your services and find work opportunities',
                icon: Icons.work_outline,
                color: Color(0xFFFF9800),
                onTap: () => _selectAccountType('service_provider'),
                isLoading: _isLoading && _selectedType == 'service_provider',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: color))
            : Column(
                children: [
                  Icon(icon, size: 64, color: color),
                  SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
