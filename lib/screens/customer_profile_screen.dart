// lib/screens/customer_profile_screen.dart
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

  // Text controllers for editing
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;

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
        });
        _showErrorSnackBar('Customer profile not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading profile: ${e.toString()}');
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
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
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'customer_name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      };

      // Add location data if provided
      if (_addressController.text.trim().isNotEmpty ||
          _cityController.text.trim().isNotEmpty ||
          _postalCodeController.text.trim().isNotEmpty) {
        updates['location'] = {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'postal_code': _postalCodeController.text.trim(),
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
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('First name is required');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Last name is required');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email is required');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return false;
    }
    return true;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _customer == null
              ? _buildNoProfileState()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      SizedBox(height: 24),
                      _buildPersonalInfoSection(),
                      SizedBox(height: 24),
                      _buildContactInfoSection(),
                      SizedBox(height: 24),
                      _buildLocationSection(),
                      SizedBox(height: 24),
                      _buildPreferencesSection(),
                      if (_isEditing) ...[
                        SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                      SizedBox(height: 100), // Extra space at bottom
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 100, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Profile not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
      padding: EdgeInsets.all(20),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[100],
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
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
      'Location Information',
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
          Icons.local_post_office,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      'Preferences',
      [
        _buildPreferenceTile(
          'Email Notifications',
          _customer?.preferences.emailNotifications ?? true,
          Icons.email_outlined,
          (value) {
            // TODO: Update preference
          },
        ),
        _buildPreferenceTile(
          'SMS Notifications',
          _customer?.preferences.smsNotifications ?? true,
          Icons.sms_outlined,
          (value) {
            // TODO: Update preference
          },
        ),
        _buildPreferenceTile(
          'Push Notifications',
          _customer?.preferences.pushNotifications ?? true,
          Icons.notifications_outlined,
          (value) {
            // TODO: Update preference
          },
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
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
              color: Colors.black87,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
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
                SizedBox(height: 4),
                _isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        keyboardType: keyboardType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                      )
                    : Text(
                        value?.isNotEmpty == true ? value! : 'Not provided',
                        style: TextStyle(
                          fontSize: 16,
                          color: value?.isNotEmpty == true
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(
    String label,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: _isEditing ? onChanged : null,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
