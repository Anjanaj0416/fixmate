// lib/screens/service_request_flow.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Form data
  String? _selectedIssueType;
  String? _selectedLocation;
  String _problemDescription = '';
  String? _waterSupplyStatus;
  String _urgency = 'Same day';
  String _budgetRange = 'LKR 10000-LKR 15000';
  List<File> _selectedImages = [];

  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.serviceName} Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStepTitle(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Issue Details';
      case 1:
        return 'Location & Details';
      case 2:
        return 'Additional Information';
      case 3:
        return 'Review & Confirm';
      default:
        return 'Service Request';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIssueDetailsStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildAdditionalInfoStep();
      case 3:
        return _buildReviewStep();
      default:
        return Container();
    }
  }

  Widget _buildIssueDetailsStep() {
    List<Map<String, String>> issueTypes = _getIssueTypes();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of ${widget.serviceName.toLowerCase()} issue are you experiencing? *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          ...issueTypes.map((issue) => _buildRadioOption(
                issue['value']!,
                issue['label']!,
                _selectedIssueType,
                (value) => setState(() => _selectedIssueType = value),
              )),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    List<Map<String, String>> locations = [
      {'value': 'kitchen', 'label': 'Kitchen'},
      {'value': 'bathroom', 'label': 'Bathroom'},
      {'value': 'basement', 'label': 'Basement'},
      {'value': 'laundry_room', 'label': 'Laundry room'},
      {'value': 'outdoor', 'label': 'Outdoor'},
      {'value': 'multiple_locations', 'label': 'Multiple locations'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where is the ${widget.serviceName.toLowerCase()} problem located? *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          ...locations.map((location) => _buildRadioOption(
                location['value']!,
                location['label']!,
                _selectedLocation,
                (value) => setState(() => _selectedLocation = value),
              )),
          SizedBox(height: 24),
          Text(
            'Please describe the ${widget.serviceName.toLowerCase()} problem in detail *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Include any sounds, visible damage, water pressure issues, how long it\'s been happening, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _problemDescription = value),
          ),
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
          if (widget.serviceType == 'plumbing') ...[
            Text(
              'Water Supply Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            _buildDropdown(
              value: _waterSupplyStatus,
              hint: 'Select water supply status',
              items: [
                'Normal water supply',
                'Low water pressure',
                'No water supply',
                'Not sure how to turn it off',
              ],
              onChanged: (value) => setState(() => _waterSupplyStatus = value),
            ),
            SizedBox(height: 24),
          ],
          Text(
            'Urgency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildDropdown(
            value: _urgency,
            hint: 'Select urgency',
            items: [
              'Emergency (ASAP)',
              'Same day',
              'Within 2-3 days',
              'Within a week',
              'Flexible timing',
            ],
            onChanged: (value) => setState(() => _urgency = value),
          ),
          SizedBox(height: 24),
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
              'Under LKR 5000',
              'LKR 5000-LKR 10000',
              'LKR 10000-LKR 15000',
              'LKR 15000-LKR 25000',
              'Above LKR 25000',
              'Get quotes first',
            ],
            onChanged: (value) => setState(() => _budgetRange = value),
          ),
          SizedBox(height: 24),
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          _buildImageUploadSection(),
          SizedBox(height: 16),
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildSummaryContainer(),
          SizedBox(height: 24),
          _buildInfoBox(),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canProceed() ? _submitRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm & Get Quotes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContainer() {
    return Container(
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
          _buildSummaryRow('Issue Type:',
              _selectedIssueType?.replaceAll('_', ' ') ?? 'Not specified'),
          _buildSummaryRow('Location:',
              _selectedLocation?.replaceAll('_', ' ') ?? 'Not specified'),
          _buildSummaryRow(
              'Description:',
              _problemDescription.isNotEmpty
                  ? _problemDescription
                  : 'No description provided'),
          if (widget.serviceType == 'plumbing' && _waterSupplyStatus != null)
            _buildSummaryRow('Water Supply Status:', _waterSupplyStatus!),
          _buildSummaryRow('Urgency:', _urgency),
          _buildSummaryRow('Budget:', _budgetRange),
          if (_selectedImages.isNotEmpty)
            _buildSummaryRow('Photos:', '${_selectedImages.length} uploaded'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
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
          {'value': 'leaky_faucet_pipe', 'label': 'Leaky faucet/pipe'},
          {'value': 'clogged_drain_toilet', 'label': 'Clogged drain/toilet'},
          {'value': 'water_heater_problem', 'label': 'Water heater problem'},
          {
            'value': 'installation_replacement',
            'label': 'Installation/replacement'
          },
          {'value': 'emergency_leak', 'label': 'Emergency leak'},
          {'value': 'other', 'label': 'Other'},
        ];
      case 'electrical':
        return [
          {'value': 'power_outage', 'label': 'Power outage'},
          {'value': 'faulty_wiring', 'label': 'Faulty wiring'},
          {'value': 'outlet_issues', 'label': 'Outlet issues'},
          {'value': 'light_fixture_problem', 'label': 'Light fixture problem'},
          {
            'value': 'circuit_breaker_issues',
            'label': 'Circuit breaker issues'
          },
          {'value': 'installation_new', 'label': 'New installation'},
          {'value': 'other', 'label': 'Other'},
        ];
      default:
        return [
          {'value': 'repair_needed', 'label': 'Repair needed'},
          {'value': 'installation_required', 'label': 'Installation required'},
          {'value': 'maintenance_service', 'label': 'Maintenance service'},
          {'value': 'consultation_needed', 'label': 'Consultation needed'},
          {'value': 'other', 'label': 'Other'},
        ];
    }
  }

  Widget _buildRadioOption(String value, String label, String? selectedValue,
      Function(String) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedValue,
        onChanged: (value) => onChanged(value!),
        title: Text(label),
        activeColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.white,
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildImageUploadCard(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildImageUploadCard(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 16),
          _buildSelectedImagesGrid(),
        ],
      ],
    );
  }

  Widget _buildImageUploadCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagesGrid() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we ask these questions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'These details help us match you with the right service provider and ensure they come prepared with the right tools and knowledge.',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Back & Edit'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _goToNextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep < _totalSteps - 1 ? 'Next' : 'Submit Request',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedIssueType != null;
      case 1:
        return _selectedLocation != null && _problemDescription.isNotEmpty;
      case 2:
        return true; // All fields in this step are optional or have defaults
      case 3:
        return true; // Review step
      default:
        return false;
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitRequest();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
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

  Future<void> _submitRequest() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Submitting your request...'),
            ],
          ),
        ),
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create service request data
      Map<String, dynamic> requestData = {
        'customer_id': user.uid,
        'service_type': widget.serviceType,
        'sub_service': widget.subService,
        'service_name': widget.serviceName,
        'issue_type': _selectedIssueType,
        'location': _selectedLocation,
        'description': _problemDescription,
        'urgency': _urgency,
        'budget_range': _budgetRange,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add service-specific fields
      if (widget.serviceType == 'plumbing' && _waterSupplyStatus != null) {
        requestData['water_supply_status'] = _waterSupplyStatus;
      }

      // Add image count (actual image upload would be implemented separately)
      if (_selectedImages.isNotEmpty) {
        requestData['images_count'] = _selectedImages.length;
        requestData['has_images'] = true;
      }

      // Save to Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('service_requests')
          .add(requestData);

      // Update with generated ID
      await docRef.update({'request_id': docRef.id});

      // Hide loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: Text('Request Submitted!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your service request has been submitted successfully.'),
              SizedBox(height: 8),
              Text(
                'Request ID: ${docRef.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Service providers will review your request and send quotes soon.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.popUntil(
                    context, (route) => route.isFirst); // Go back to dashboard
              },
              child: Text('Go to Dashboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.popUntil(
                    context, (route) => route.isFirst); // Go back to dashboard
                // TODO: Navigate to bookings tab
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('View My Requests',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Hide loading dialog if it's showing
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Additional service request model for better organization
class ServiceRequest {
  final String requestId;
  final String customerId;
  final String serviceType;
  final String subService;
  final String serviceName;
  final String? issueType;
  final String? location;
  final String description;
  final String? waterSupplyStatus;
  final String urgency;
  final String budgetRange;
  final int imagesCount;
  final bool hasImages;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRequest({
    required this.requestId,
    required this.customerId,
    required this.serviceType,
    required this.subService,
    required this.serviceName,
    this.issueType,
    this.location,
    required this.description,
    this.waterSupplyStatus,
    required this.urgency,
    required this.budgetRange,
    this.imagesCount = 0,
    this.hasImages = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ServiceRequest(
      requestId: doc.id,
      customerId: data['customer_id'] ?? '',
      serviceType: data['service_type'] ?? '',
      subService: data['sub_service'] ?? '',
      serviceName: data['service_name'] ?? '',
      issueType: data['issue_type'],
      location: data['location'],
      description: data['description'] ?? '',
      waterSupplyStatus: data['water_supply_status'],
      urgency: data['urgency'] ?? 'Same day',
      budgetRange: data['budget_range'] ?? '',
      imagesCount: data['images_count'] ?? 0,
      hasImages: data['has_images'] ?? false,
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customer_id': customerId,
      'service_type': serviceType,
      'sub_service': subService,
      'service_name': serviceName,
      'issue_type': issueType,
      'location': location,
      'description': description,
      'water_supply_status': waterSupplyStatus,
      'urgency': urgency,
      'budget_range': budgetRange,
      'images_count': imagesCount,
      'has_images': hasImages,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
