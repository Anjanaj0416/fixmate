// lib/screens/worker_profile_screen.dart
// MODIFIED VERSION - Added profile picture upload functionality
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/worker_model.dart';
import '../constants/service_constants.dart';
import '../services/storage_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  final WorkerModel worker;

  const WorkerProfileScreen({Key? key, required this.worker}) : super(key: key);

  @override
  _WorkerProfileScreenState createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  late WorkerModel _worker;
  final ImagePicker _imagePicker = ImagePicker();

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

  // lib/screens/worker_profile_screen.dart
// COMPLETE FIX - Profile picture now updates and persists correctly
// Only modify the _uploadProfilePicture method in your existing file

  Future<void> _uploadProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      print('🔄 Starting profile picture upload...');

      // ✅ Step 1: Upload new profile picture to Storage
      String downloadUrl = await StorageService.uploadWorkerProfilePicture(
        imageFile: image,
      );

      print('✅ Upload complete, URL: $downloadUrl');

      // ✅ Step 2: Update Firestore with new URL
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('workers')
            .doc(user.uid)
            .update({
          'profile_picture_url': downloadUrl,
          'last_active': FieldValue.serverTimestamp(),
        });

        print('✅ Firestore updated with new profile picture URL');

        // ✅ Step 3: Wait for Firestore to propagate changes
        await Future.delayed(Duration(milliseconds: 500));
      }

      // ✅ Step 4: Force reload from Firestore to get the latest data
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot freshDoc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(currentUser.uid)
            .get();

        if (freshDoc.exists) {
          setState(() {
            _worker = WorkerModel.fromFirestore(freshDoc);
            _isUploadingImage = false;
          });

          print('✅ Worker profile refreshed from Firestore');
          print('🔗 New profile picture URL: ${_worker.profilePictureUrl}');
        } else {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }

      _showSuccessSnackBar('Profile picture updated successfully!');
      print('✅ Profile picture update complete!');
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      setState(() {
        _isUploadingImage = false;
      });
      _showErrorSnackBar('Failed to upload profile picture: ${e.toString()}');
    }
  }

// ========== SAVE PROFILE METHOD ==========
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

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
        profilePictureUrl: _worker.profilePictureUrl,
      );

      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update(_worker.toFirestore());

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      _showSuccessSnackBar('Profile updated successfully!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

// ========== HELPER METHODS ==========
  Widget _buildProfileImage() {
    if (_worker.profilePictureUrl != null &&
        _worker.profilePictureUrl!.isNotEmpty) {
      return Image.network(
        _worker.profilePictureUrl!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading profile image: $error');
          return _buildDefaultAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 50,
      color: Colors.white,
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

// Helper method to build profile image widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Profile'),
        backgroundColor: Color(0xFFFF9800),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 16),
            if (_isEditing) ...[
              _buildEditableFields(),
            ] else ...[
              _buildViewOnlyFields(),
            ],
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
            Stack(
              children: [
                // ✅ Profile Picture with better error handling
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFFF9800),
                    child: ClipOval(
                      child: _buildProfileImage(),
                    ),
                  ),
                ),
                // ✅ Upload button overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _uploadProfilePicture,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFFFF9800),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isUploadingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF9800),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Color(0xFFFF9800),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              Text(
                _worker.workerName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _worker.businessName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 8),
            Chip(
              label: Text(_worker.serviceType),
              backgroundColor: Color(0xFFFF9800).withOpacity(0.1),
              labelStyle: TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ✅ NEW: Helper method to build profile image with proper error handling

// ✅ NEW: Fallback avatar when no image
  Widget _buildFallbackAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: Color(0xFFFF9800),
      child: Center(
        child: Text(
          _worker.firstName.isNotEmpty
              ? _worker.firstName[0].toUpperCase()
              : 'W',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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

  Widget _buildEditableFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: 'Website (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _stateController,
              decoration: InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _postalCodeController,
              decoration: InputDecoration(
                labelText: 'Postal Code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Pricing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _dailyWageController,
              decoration: InputDecoration(
                labelText: 'Daily Wage (LKR)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _halfDayRateController,
              decoration: InputDecoration(
                labelText: 'Half Day Rate (LKR)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _minimumChargeController,
              decoration: InputDecoration(
                labelText: 'Minimum Charge (LKR)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _overtimeRateController,
              decoration: InputDecoration(
                labelText: 'Overtime Rate (LKR/hour)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            Text(
              'Professional Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Experience (Years)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: _serviceRadiusController,
              decoration: InputDecoration(
                labelText: 'Service Radius (KM)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewOnlyFields() {
    return Column(
      children: [
        _buildInfoCard('Personal Information', [
          _buildInfoRow('Business Name', _worker.businessName),
          _buildInfoRow('Bio', _worker.profile.bio),
        ]),
        SizedBox(height: 16),
        _buildInfoCard('Contact Information', [
          _buildInfoRow('Phone', _worker.contact.phoneNumber),
          _buildInfoRow('Email', _worker.contact.email),
          if (_worker.contact.website != null)
            _buildInfoRow('Website', _worker.contact.website!),
        ]),
        SizedBox(height: 16),
        _buildInfoCard('Location', [
          _buildInfoRow('City', _worker.location.city),
          _buildInfoRow('State', _worker.location.state),
          _buildInfoRow('Postal Code', _worker.location.postalCode),
        ]),
        SizedBox(height: 16),
        _buildInfoCard('Pricing', [
          _buildInfoRow('Daily Wage',
              'LKR ${_worker.pricing.dailyWageLkr.toStringAsFixed(0)}'),
          _buildInfoRow('Half Day Rate',
              'LKR ${_worker.pricing.halfDayRateLkr.toStringAsFixed(0)}'),
          _buildInfoRow('Minimum Charge',
              'LKR ${_worker.pricing.minimumChargeLkr.toStringAsFixed(0)}'),
          _buildInfoRow('Overtime Rate',
              'LKR ${_worker.pricing.overtimeHourlyLkr.toStringAsFixed(0)}/hour'),
        ]),
        SizedBox(height: 16),
        _buildInfoCard('Professional Details', [
          _buildInfoRow('Experience', '${_worker.experienceYears} years'),
          _buildInfoRow(
              'Service Radius', '${_worker.profile.serviceRadiusKm} km'),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
