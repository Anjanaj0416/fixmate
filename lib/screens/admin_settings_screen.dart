// lib/screens/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  User? _currentUser;
  Map<String, dynamic>? _adminData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = FirebaseAuth.instance.currentUser;

      if (_currentUser != null) {
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (adminDoc.exists) {
          setState(() {
            _adminData = adminDoc.data() as Map<String, dynamic>?;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),

          // Admin Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Email',
                    _currentUser?.email ?? 'N/A',
                    Icons.email,
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    'User ID',
                    _currentUser?.uid ?? 'N/A',
                    Icons.fingerprint,
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    'Role',
                    _adminData?['role'] ?? 'admin',
                    Icons.admin_panel_settings,
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    'Account Type',
                    _adminData?['accountType'] ?? 'admin',
                    Icons.account_circle,
                  ),
                  if (_adminData?['displayName'] != null) ...[
                    Divider(height: 24),
                    _buildInfoRow(
                      'Display Name',
                      _adminData!['displayName'],
                      Icons.person,
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Account Actions
          Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          _buildActionButton(
            'Change Password',
            Icons.lock,
            Colors.blue,
            _changePassword,
          ),
          SizedBox(height: 12),
          _buildActionButton(
            'Update Profile',
            Icons.edit,
            Colors.orange,
            _updateProfile,
          ),
          SizedBox(height: 12),
          _buildActionButton(
            'View Activity Log',
            Icons.history,
            Colors.purple,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Activity log coming soon')),
              );
            },
          ),

          SizedBox(height: 24),

          // System Info
          Text(
            'System Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'App Version',
                    '1.0.0',
                    Icons.info,
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    'Database',
                    'Firebase Firestore',
                    Icons.storage,
                  ),
                  Divider(height: 24),
                  _buildInfoRow(
                    'Authentication',
                    'Firebase Auth',
                    Icons.security,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF2196F3), size: 24),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
              }
            },
            child: Text('Change'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _currentUser?.updatePassword(newPasswordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    TextEditingController displayNameController = TextEditingController(
      text: _adminData?['displayName'] ?? '',
    );

    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Profile'),
        content: TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({
          'displayName': displayNameController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _loadAdminData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
