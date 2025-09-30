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

      // Generate customer ID
      String customerId =
          'CUST_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

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
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushNamedAndRemoveUntil(
          context, '/customer_dashboard', (route) => false);
    } catch (e) {
      throw Exception('Failed to create customer profile: ${e.toString()}');
    }
  }

  Future<void> _navigateToWorkerRegistration() async {
    // Update user document to mark as service provider
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'service_provider_pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _isLoading = false;
      _selectedType = null;
    });

    // Navigate to worker registration flow
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkerRegistrationFlow()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How will you use FixMate?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Choose your primary purpose',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 20),

            // Looking for Services Card
            _buildAccountTypeCard(
              type: 'customer',
              icon: Icons.search,
              iconColor: Color(0xFF2196F3),
              title: 'Looking for Services',
              description:
                  'Find skilled professionals for your home repairs, maintenance, and improvement projects',
              features: ['Find Workers', 'Get Quotes', 'Book Services'],
              buttonText: 'I Need Services',
              buttonColor: Color(0xFF2196F3),
              isSelected: _selectedType == 'customer',
            ),

            SizedBox(height: 24),

            // Providing Services Card
            _buildAccountTypeCard(
              type: 'service_provider',
              icon: Icons.build,
              iconColor: Color(0xFFFF9800),
              title: 'Providing Services',
              description:
                  'Offer your skills and grow your business by connecting with clients who need your expertise',
              features: ['Get Clients', 'Send Quotes', 'Earn More'],
              buttonText: 'I Provide Services',
              buttonColor: Color(0xFFFF9800),
              isSelected: _selectedType == 'service_provider',
            ),

            SizedBox(height: 40),

            // Note
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can always switch between modes later in your profile',
                      style: TextStyle(color: Color(0xFF2196F3), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Skip for now button
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      // TODO: Navigate to main app without setting account type
                      _showSuccessSnackBar(
                        'You can set your account type later in settings.',
                      );
                    },
              child: Text(
                'Skip for now',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> features,
    required String buttonText,
    required Color buttonColor,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? buttonColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Features
            ...features.map((feature) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: iconColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )),

            SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading && _selectedType == type
                    ? null
                    : () => _selectAccountType(type),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading && _selectedType == type
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
