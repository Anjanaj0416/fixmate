// lib/screens/service_request_flow.dart
// COMPLETE FIXED VERSION - Works on Flutter Web with Firebase Storage Emulator
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ml_service.dart';
import '../services/storage_service.dart';
import 'worker_results_screen.dart';

class ServiceRequestFlow extends StatefulWidget {
  final String serviceType;
  final String subService;
  final String serviceName;

  const ServiceRequestFlow({
    Key? key,
    required this.serviceType,
    required this.subService,
    required this.serviceName,
  }) : super(key: key);

  @override
  _ServiceRequestFlowState createState() => _ServiceRequestFlowState();
}

class _ServiceRequestFlowState extends State<ServiceRequestFlow> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  bool _isLoading = false;
  String _currentAddress = '';

  // Form data
  String? _selectedIssueType;
  String? _selectedLocation;
  String _problemDescription = '';
  String? _waterSupplyStatus;
  String _urgency = 'Same day';
  String _budgetRange = 'LKR 10000-LKR 15000';
  final List<XFile> _selectedImages = []; // ✅ Changed to XFile
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedIssueType != null;
      case 1:
        return _selectedLocation != null;
      case 2:
        return _problemDescription.trim().isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_canProceed() && _currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading photos and finding workers...'),
                ],
              ),
            )
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(child: _buildStepContent()),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: List.generate(_totalSteps, (index) {
          bool isCompleted = index < _currentStep;
          bool isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? Colors.blue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1) SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIssueTypeStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildDescriptionStep();
      case 3:
        return _buildAdditionalInfoStep();
      default:
        return Container();
    }
  }

  Widget _buildIssueTypeStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of issue are you experiencing?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ..._getIssueTypes().map((issue) => _buildRadioOption(
                issue['label']!,
                issue['value']!,
                _selectedIssueType,
                (value) => setState(() => _selectedIssueType = value),
              )),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where is the issue located?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ..._getLocationOptions().map((location) => _buildRadioOption(
                location['label']!,
                location['value']!,
                _selectedLocation,
                (value) => setState(() => _selectedLocation = value),
              )),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe the Problem',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                border: InputBorder.none,
              ),
              onChanged: (value) => setState(() => _problemDescription = value),
            ),
          ),
          if (widget.serviceType == 'plumbing') ...[
            SizedBox(height: 20),
            Text(
              'Water Supply Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            _buildDropdown(
              value: _waterSupplyStatus,
              hint: 'Select water supply status',
              items: ['Normal', 'Low pressure', 'No water', 'Intermittent'],
              onChanged: (value) => setState(() => _waterSupplyStatus = value),
            ),
          ],
          SizedBox(height: 16),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            'Service Urgency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildDropdown(
            value: _urgency,
            hint: 'Select urgency',
            items: ['Same day', 'Within 2-3 days', 'Within a week', 'Flexible'],
            onChanged: (value) =>
                setState(() => _urgency = value ?? 'Same day'),
          ),
          SizedBox(height: 20),
          Text(
            'Budget Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildDropdown(
            value: _budgetRange,
            hint: 'Select budget range',
            items: [
              'LKR 5000-LKR 10000',
              'LKR 10000-LKR 15000',
              'LKR 15000-LKR 25000',
              'LKR 25000-LKR 50000',
              'LKR 50000+',
            ],
            onChanged: (value) =>
                setState(() => _budgetRange = value ?? 'LKR 10000-LKR 15000'),
          ),
          SizedBox(height: 20),
          Text(
            'Upload photos (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Photos help service providers understand your needs better',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          SizedBox(height: 12),
          _buildPhotoUploadSection(),
        ],
      ),
    );
  }

  // ✅ FIXED: Photo upload section that works on Web
  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showImageSourceDialog(),
          icon: Icon(Icons.add_photo_alternate),
          label: Text('Choose from Gallery'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue,
            elevation: 0,
          ),
        ),
        SizedBox(height: 12),
        if (_selectedImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_selectedImages.length, (index) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // ✅ For Web, use FutureBuilder to read bytes
                                return FutureBuilder<Uint8List>(
                                  future: _selectedImages[index].readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );
                              },
                            )
                          : Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }

  void _showImageSourceDialog() {
    if (kIsWeb) {
      // On web, only gallery is available
      _pickImage(ImageSource.gallery);
    } else {
      // On mobile, show both options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ✅ FIXED: Upload photos using XFile (works with emulator)
  Future<void> _submitRequest() async {
    if (!_canProceed()) return;

    setState(() {
      _isLoading = true;
    });

    List<String> uploadedImageUrls = [];

    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please login to continue');
      }

      // ✅ STEP 1: Upload photos to Firebase Storage (Emulator)
      if (_selectedImages.isNotEmpty) {
        print(
            '📸 Uploading ${_selectedImages.length} photos to Firebase Storage Emulator...');

        for (XFile imageFile in _selectedImages) {
          try {
            // Upload to Firebase Storage (will use emulator if configured)
            String downloadUrl = await StorageService.uploadIssuePhoto(
              imageFile: imageFile,
            );

            uploadedImageUrls.add(downloadUrl);
            print('✅ Photo uploaded: $downloadUrl');
          } catch (e) {
            print('❌ Failed to upload photo: $e');
            // Continue with other photos even if one fails
          }
        }

        print('✅ Successfully uploaded ${uploadedImageUrls.length} photos');
      }

      // ✅ STEP 2: Get user's location from database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String userLocation = 'colombo'; // Default
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userLocation =
            (userData['nearestTown'] ?? 'colombo').toString().toLowerCase();
      }

      print('\n========== MANUAL BOOKING ML SEARCH ==========');
      print('📝 Description: $_problemDescription');
      print('📍 Location: $userLocation');
      print('🔧 Category: ${widget.serviceType}');
      print('📸 Photos: ${uploadedImageUrls.length} uploaded');

      // ✅ STEP 3: Call ML service to get worker recommendations
      MLRecommendationResponse mlResponse = await MLService.searchWorkers(
        description: _problemDescription,
        location: userLocation,
      );

      print('✅ ML Analysis complete!');
      print('📊 Found ${mlResponse.workers.length} workers');
      print('========== MANUAL BOOKING ML SEARCH END ==========\n');

      setState(() {
        _isLoading = false;
      });

      // ✅ STEP 4: Navigate to worker results screen WITH uploaded photos
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerResultsScreen(
            workers: mlResponse.workers,
            aiAnalysis: mlResponse.aiAnalysis,
            problemDescription: _problemDescription,
            problemImageUrls: uploadedImageUrls, // ✅ Pass uploaded photos
          ),
        ),
      );
    } catch (e) {
      print('❌ Error in manual booking flow: $e');
      _showErrorSnackBar('Failed to process request: ${e.toString()}');

      setState(() {
        _isLoading = false;
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

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.blue),
                ),
                child: Text('Back & Edit'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed()
                  ? (_currentStep == _totalSteps - 1
                      ? _submitRequest
                      : _nextStep)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Next' : 'Next',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint),
        isExpanded: true,
        underline: SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    String? groupValue,
    Function(String?) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: groupValue == value ? Colors.blue : Colors.grey.shade300,
            width: groupValue == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: groupValue == value ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: Colors.blue,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      groupValue == value ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Provide as much detail as possible to help us match you with the right service provider.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getIssueTypes() {
    switch (widget.serviceType) {
      case 'plumbing':
        return [
          {'label': 'Leak or drip', 'value': 'leak_or_drip'},
          {'label': 'Blocked drain', 'value': 'blocked_drain'},
          {'label': 'Installation needed', 'value': 'installation_needed'},
          {'label': 'Repair needed', 'value': 'repair_needed'},
          {'label': 'Emergency issue', 'value': 'emergency_issue'},
          {'label': 'Other', 'value': 'other'},
        ];
      case 'electrical':
        return [
          {'label': 'Power outage', 'value': 'power_outage'},
          {'label': 'Faulty wiring', 'value': 'faulty_wiring'},
          {'label': 'Installation needed', 'value': 'installation_needed'},
          {'label': 'Repair needed', 'value': 'repair_needed'},
          {'label': 'Emergency issue', 'value': 'emergency_issue'},
          {'label': 'Other', 'value': 'other'},
        ];
      default:
        return [
          {'label': 'Installation needed', 'value': 'installation_needed'},
          {'label': 'Repair needed', 'value': 'repair_needed'},
          {'label': 'Maintenance required', 'value': 'maintenance_required'},
          {'label': 'Emergency issue', 'value': 'emergency_issue'},
          {'label': 'Other', 'value': 'other'},
        ];
    }
  }

  List<Map<String, String>> _getLocationOptions() {
    return [
      {'label': 'Kitchen', 'value': 'kitchen'},
      {'label': 'Bathroom', 'value': 'bathroom'},
      {'label': 'Living room', 'value': 'living_room'},
      {'label': 'Bedroom', 'value': 'bedroom'},
      {'label': 'Garage', 'value': 'garage'},
      {'label': 'Basement', 'value': 'basement'},
      {'label': 'Outdoor area', 'value': 'outdoor_area'},
      {'label': 'Other', 'value': 'other'},
    ];
  }
}
