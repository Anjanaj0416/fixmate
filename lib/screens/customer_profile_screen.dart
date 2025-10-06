// lib/screens/customer_profile_screen.dart
// FIXED VERSION - Resolves LateInitializationError and initState issues

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerProfileScreen extends StatefulWidget {
  @override
  _CustomerProfileScreenState createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  CustomerModel? _customer;

  // CRITICAL FIX: Initialize controllers as nullable or with default controllers
  TextEditingController? _firstNameController;
  TextEditingController? _lastNameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  TextEditingController? _addressController;
  TextEditingController? _cityController;
  TextEditingController? _postalCodeController;

  // Store error message to show after build
  String? _pendingErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
  }

  Future<void> _loadCustomerProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      CustomerModel? customer =
          await CustomerService.getCustomerByUserId(user.uid);

      if (customer != null) {
        setState(() {
          _customer = customer;
          _initializeControllers();
          _isLoading = false;
        });
      } else {
        // Handle case where customer profile doesn't exist
        setState(() {
          _isLoading = false;
          _pendingErrorMessage = 'Customer profile not found';
        });

        // CRITICAL FIX: Show error after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pendingErrorMessage != null && mounted) {
            _showErrorSnackBar(_pendingErrorMessage!);
            _pendingErrorMessage = null;
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _pendingErrorMessage = 'Error loading profile: ${e.toString()}';
      });

      // CRITICAL FIX: Show error after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pendingErrorMessage != null && mounted) {
          _showErrorSnackBar(_pendingErrorMessage!);
          _pendingErrorMessage = null;
        }
      });
    }
  }

  void _initializeControllers() {
    _firstNameController =
        TextEditingController(text: _customer?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: _customer?.lastName ?? '');
    _emailController = TextEditingController(text: _customer?.email ?? '');
    _phoneController =
        TextEditingController(text: _customer?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: _customer?.location?.address ?? '');
    _cityController =
        TextEditingController(text: _customer?.location?.city ?? '');
    _postalCodeController =
        TextEditingController(text: _customer?.location?.postalCode ?? '');
  }

  @override
  void dispose() {
    // CRITICAL FIX: Safely dispose controllers only if they were initialized
    _firstNameController?.dispose();
    _lastNameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    _addressController?.dispose();
    _cityController?.dispose();
    _postalCodeController?.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_validateInputs()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare update data
      Map<String, dynamic> updates = {
        'first_name': _firstNameController!.text.trim(),
        'last_name': _lastNameController!.text.trim(),
        'customer_name':
            '${_firstNameController!.text.trim()} ${_lastNameController!.text.trim()}',
        'email': _emailController!.text.trim(),
        'phone_number': _phoneController!.text.trim(),
      };

      // Add location data if provided
      if (_addressController!.text.trim().isNotEmpty ||
          _cityController!.text.trim().isNotEmpty ||
          _postalCodeController!.text.trim().isNotEmpty) {
        updates['location'] = {
          'address': _addressController!.text.trim(),
          'city': _cityController!.text.trim(),
          'postal_code': _postalCodeController!.text.trim(),
        };
      }

      // Update in database
      await CustomerService.updateCustomer(user.uid, updates);

      // Reload profile to get updated data
      await _loadCustomerProfile();

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Error saving profile: ${e.toString()}');
    }
  }

  bool _validateInputs() {
    if (_firstNameController == null ||
        _firstNameController!.text.trim().isEmpty) {
      _showErrorSnackBar('First name is required');
      return false;
    }
    if (_lastNameController == null ||
        _lastNameController!.text.trim().isEmpty) {
      _showErrorSnackBar('Last name is required');
      return false;
    }
    if (_emailController == null || _emailController!.text.trim().isEmpty) {
      _showErrorSnackBar('Email is required');
      return false;
    }
    if (_phoneController == null || _phoneController!.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    // CRITICAL FIX: Only show snackbar if widget is still mounted
    if (!mounted) return;

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
    // CRITICAL FIX: Only show snackbar if widget is still mounted
    if (!mounted) return;

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isEditing && _customer != null)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else if (_isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reload original values
                  _initializeControllers();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _customer == null
              ? _buildProfileNotFound()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      SizedBox(height: 16),
                      _buildPersonalInfoSection(),
                      SizedBox(height: 16),
                      _buildContactInfoSection(),
                      SizedBox(height: 16),
                      _buildLocationSection(),
                      SizedBox(height: 16),
                      _buildAccountInfoSection(),
                      SizedBox(height: 32),
                      if (_isEditing) _buildSaveButton(),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Profile not found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please contact support for assistance',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[700],
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customer?.customerName ?? 'Customer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customer ID: ${_customer?.customerId ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _customer?.verified == true
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _customer?.verified == true
                        ? 'Verified'
                        : 'Pending Verification',
                    style: TextStyle(
                      color: _customer?.verified == true
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    if (_customer?.customerName != null && _customer!.customerName.isNotEmpty) {
      List<String> names = _customer!.customerName.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    }
    return 'C';
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      'Personal Information',
      [
        _buildInfoTile(
          'First Name',
          _isEditing ? null : _customer?.firstName,
          _isEditing ? _firstNameController : null,
          Icons.person,
        ),
        _buildInfoTile(
          'Last Name',
          _isEditing ? null : _customer?.lastName,
          _isEditing ? _lastNameController : null,
          Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      'Contact Information',
      [
        _buildInfoTile(
          'Email',
          _isEditing ? null : _customer?.email,
          _isEditing ? _emailController : null,
          Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        _buildInfoTile(
          'Phone Number',
          _isEditing ? null : _customer?.phoneNumber,
          _isEditing ? _phoneController : null,
          Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      'Location',
      [
        _buildInfoTile(
          'Address',
          _isEditing ? null : _customer?.location?.address,
          _isEditing ? _addressController : null,
          Icons.home,
        ),
        _buildInfoTile(
          'City',
          _isEditing ? null : _customer?.location?.city,
          _isEditing ? _cityController : null,
          Icons.location_city,
        ),
        _buildInfoTile(
          'Postal Code',
          _isEditing ? null : _customer?.location?.postalCode,
          _isEditing ? _postalCodeController : null,
          Icons.pin_drop,
        ),
      ],
    );
  }

  Widget _buildAccountInfoSection() {
    return _buildSection(
      'Account Information',
      [
        _buildReadOnlyTile(
          'Customer ID',
          _customer?.customerId ?? 'N/A',
          Icons.badge,
        ),
        _buildReadOnlyTile(
          'Member Since',
          _customer?.createdAt != null
              ? _formatDate(_customer!.createdAt!)
              : 'N/A',
          Icons.calendar_today,
        ),
        _buildReadOnlyTile(
          'Verification Status',
          _customer?.verified == true ? 'Verified' : 'Pending',
          Icons.verified_user,
          valueColor:
              _customer?.verified == true ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String? value,
    TextEditingController? controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          _isEditing && controller != null
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                )
              : Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? 'Not provided',
                        style: TextStyle(
                          fontSize: 16,
                          color: value != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTile(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Customer Service class (if not defined elsewhere)
class CustomerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<CustomerModel?> getCustomerByUserId(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('customers').doc(userId).get();

      if (doc.exists) {
        return CustomerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  static Future<void> updateCustomer(
      String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('customers').doc(userId).update(updates);
    } catch (e) {
      print('Error updating customer: $e');
      throw e;
    }
  }
}
