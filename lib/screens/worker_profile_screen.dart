import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../constants/service_constants.dart';

class WorkerProfileScreen extends StatefulWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({Key? key, required this.worker}) : super(key: key);

  @override
  _WorkerProfileScreenState createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  late WorkerModel _worker;

  // Controllers for editable fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _businessNameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _dailyWageController;
  late TextEditingController _halfDayRateController;
  late TextEditingController _minimumChargeController;
  late TextEditingController _overtimeRateController;
  late TextEditingController _experienceController;
  late TextEditingController _serviceRadiusController;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: _worker.firstName);
    _lastNameController = TextEditingController(text: _worker.lastName);
    _businessNameController = TextEditingController(text: _worker.businessName);
    _bioController = TextEditingController(text: _worker.profile.bio);
    _phoneController = TextEditingController(text: _worker.contact.phoneNumber);
    _emailController = TextEditingController(text: _worker.contact.email);
    _websiteController =
        TextEditingController(text: _worker.contact.website ?? '');
    _cityController = TextEditingController(text: _worker.location.city);
    _stateController = TextEditingController(text: _worker.location.state);
    _postalCodeController =
        TextEditingController(text: _worker.location.postalCode);
    _dailyWageController =
        TextEditingController(text: _worker.pricing.dailyWageLkr.toString());
    _halfDayRateController =
        TextEditingController(text: _worker.pricing.halfDayRateLkr.toString());
    _minimumChargeController = TextEditingController(
        text: _worker.pricing.minimumChargeLkr.toString());
    _overtimeRateController = TextEditingController(
        text: _worker.pricing.overtimeHourlyLkr.toString());
    _experienceController =
        TextEditingController(text: _worker.experienceYears.toString());
    _serviceRadiusController =
        TextEditingController(text: _worker.profile.serviceRadiusKm.toString());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _dailyWageController.dispose();
    _halfDayRateController.dispose();
    _minimumChargeController.dispose();
    _overtimeRateController.dispose();
    _experienceController.dispose();
    _serviceRadiusController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update worker model with new data
      _worker = WorkerModel(
        workerId: _worker.workerId,
        workerName:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        serviceType: _worker.serviceType,
        serviceCategory: _worker.serviceCategory,
        businessName: _businessNameController.text.trim(),
        location: WorkerLocation(
          latitude: _worker.location.latitude,
          longitude: _worker.location.longitude,
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
        ),
        rating: _worker.rating,
        experienceYears:
            int.tryParse(_experienceController.text) ?? _worker.experienceYears,
        jobsCompleted: _worker.jobsCompleted,
        successRate: _worker.successRate,
        pricing: WorkerPricing(
          dailyWageLkr: double.tryParse(_dailyWageController.text) ??
              _worker.pricing.dailyWageLkr,
          halfDayRateLkr: double.tryParse(_halfDayRateController.text) ??
              _worker.pricing.halfDayRateLkr,
          minimumChargeLkr: double.tryParse(_minimumChargeController.text) ??
              _worker.pricing.minimumChargeLkr,
          emergencyRateMultiplier: _worker.pricing.emergencyRateMultiplier,
          overtimeHourlyLkr: double.tryParse(_overtimeRateController.text) ??
              _worker.pricing.overtimeHourlyLkr,
        ),
        availability: _worker.availability,
        capabilities: _worker.capabilities,
        contact: WorkerContact(
          phoneNumber: _phoneController.text.trim(),
          whatsappAvailable: _worker.contact.whatsappAvailable,
          email: _emailController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
        ),
        profile: WorkerProfile(
          bio: _bioController.text.trim(),
          specializations: _worker.profile.specializations,
          serviceRadiusKm: double.tryParse(_serviceRadiusController.text) ??
              _worker.profile.serviceRadiusKm,
        ),
        verified: _worker.verified,
        createdAt: _worker.createdAt,
        lastActive: _worker.lastActive,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update(_worker.toFirestore());

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _showSuccessSnackBar('Profile updated successfully!');
      Navigator.pop(
          context, true); // Return true to indicate profile was updated
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _initializeControllers(); // Reset controllers to original values
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFFFF9800)),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing) ...[
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: _cancelEditing,
            ),
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: _isLoading ? null : _saveProfile,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),
            SizedBox(height: 24),

            // Personal Information
            _buildSection('Personal Information', [
              _buildTextField('First Name', _firstNameController),
              _buildTextField('Last Name', _lastNameController),
              _buildTextField('Email', _emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField('Phone Number', _phoneController,
                  keyboardType: TextInputType.phone),
            ]),
            SizedBox(height: 24),

            // Business Information
            _buildSection('Business Information', [
              _buildTextField('Business Name', _businessNameController),
              _buildTextField('Bio', _bioController, maxLines: 3),
              _buildTextField('Experience (Years)', _experienceController,
                  keyboardType: TextInputType.number),
              _buildTextField('Website (Optional)', _websiteController),
            ]),
            SizedBox(height: 24),

            // Location Information
            _buildSection('Location Information', [
              _buildTextField('City', _cityController),
              _buildTextField('State/Province', _stateController),
              _buildTextField('Postal Code', _postalCodeController),
              _buildTextField('Service Radius (km)', _serviceRadiusController,
                  keyboardType: TextInputType.number),
            ]),
            SizedBox(height: 24),

            // Pricing Information
            _buildSection('Pricing Information', [
              _buildTextField('Daily Wage (LKR)', _dailyWageController,
                  keyboardType: TextInputType.number),
              _buildTextField('Half Day Rate (LKR)', _halfDayRateController,
                  keyboardType: TextInputType.number),
              _buildTextField('Minimum Charge (LKR)', _minimumChargeController,
                  keyboardType: TextInputType.number),
              _buildTextField(
                  'Overtime Rate (LKR/hour)', _overtimeRateController,
                  keyboardType: TextInputType.number),
            ]),
            SizedBox(height: 24),

            // Specializations and Capabilities (Read-only for now)
            _buildReadOnlySection(),
            SizedBox(height: 100), // Extra space for FAB
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveProfile,
              backgroundColor: Colors.green,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFFF9800),
              child: Text(
                _worker.firstName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _worker.workerName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Worker ID: ${_worker.workerId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Chip(
              label: Text(
                _worker.serviceType,
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFFFF9800),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                    'Rating', '${_worker.rating.toStringAsFixed(1)}⭐'),
                _buildStatItem('Jobs', '${_worker.jobsCompleted}'),
                _buildStatItem(
                    'Success', '${_worker.successRate.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
            SizedBox(height: 16),
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: _isEditing ? Color(0xFFFF9800) : Colors.grey[600],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          filled: true,
          fillColor: _isEditing ? Colors.white : Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildReadOnlySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills & Capabilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
            SizedBox(height: 16),

            // Specializations
            Text(
              'Specializations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _worker.profile.specializations.map((spec) {
                return Chip(
                  label: Text(spec),
                  backgroundColor: Color(0xFFFF9800).withOpacity(0.1),
                  labelStyle: TextStyle(color: Color(0xFFFF9800)),
                );
              }).toList(),
            ),
            SizedBox(height: 16),

            // Languages
            Text(
              'Languages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _worker.capabilities.languages.map((lang) {
                return Chip(
                  label: Text(lang),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(color: Colors.blue),
                );
              }).toList(),
            ),
            SizedBox(height: 16),

            // Capabilities
            Text(
              'Capabilities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            _buildCapabilityRow('Own Tools', _worker.capabilities.toolsOwned),
            _buildCapabilityRow(
                'Vehicle Available', _worker.capabilities.vehicleAvailable),
            _buildCapabilityRow('Certified', _worker.capabilities.certified),
            _buildCapabilityRow('Insured', _worker.capabilities.insurance),
            _buildCapabilityRow(
                'WhatsApp Available', _worker.contact.whatsappAvailable),
            _buildCapabilityRow(
                'Emergency Service', _worker.availability.emergencyService),

            SizedBox(height: 16),

            // Working Hours
            Text(
              'Working Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    _worker.availability.workingHours,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Response: ${_worker.availability.responseTimeMinutes} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityRow(String title, bool value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
