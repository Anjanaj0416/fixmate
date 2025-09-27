import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'accountType': type,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        _showSuccessSnackBar('Account type set successfully!');

        // Navigate to main app or dashboard
        // For now, just show a success message
        await Future.delayed(Duration(seconds: 2));

        // TODO: Navigate to appropriate dashboard based on account type
        if (type == 'customer') {
          // Navigate to customer dashboard
          _showSuccessSnackBar('Welcome! You can now find skilled workers.');
        } else {
          // Navigate to service provider dashboard
          _showSuccessSnackBar('Welcome! You can now offer your services.');
        }
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
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? buttonColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? buttonColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: isSelected ? 2 : 1,
            blurRadius: isSelected ? 8 : 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 35, color: iconColor),
          ),
          SizedBox(height: 20),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20),

          // Features
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .map((feature) => _buildFeatureTag(feature))
                .toList(),
          ),
          SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_isLoading && isSelected)
                  ? null
                  : () => _selectAccountType(type),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: (_isLoading && isSelected)
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
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
    );
  }

  Widget _buildFeatureTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
