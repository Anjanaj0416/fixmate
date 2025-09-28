import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../models/user_model.dart';
import '../constants/service_constants.dart';

class WorkerRegistrationFlow extends StatefulWidget {
  @override
  _WorkerRegistrationFlowState createState() => _WorkerRegistrationFlowState();
}

class _WorkerRegistrationFlowState extends State<WorkerRegistrationFlow> {
  PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Form data - Updated with proper null handling
  String? _selectedServiceType; // Make nullable
  String? _selectedServiceCategory; // Add new variable
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _businessName = '';
  String _experienceYears = '';
  String _bio = '';
  String _address = '';
  String _city = '';
  String _state = '';
  String _postalCode = '';

  // Collections
  List<String> _selectedSpecializations = [];
  List<String> _selectedLanguages = [];
  Set<String> _selectedWorkingDays = {};

  // Time fields with default values
  String _workingHoursStart = '09:00';
  String _workingHoursEnd = '17:00';

  // Boolean fields
  bool _availableWeekends = false;
  bool _emergencyService = false;
  bool _toolsOwned = false;
  bool _vehicleAvailable = false;
  bool _certified = false;
  bool _insurance = false;
  bool _whatsappAvailable = false;

  // Pricing fields
  String _dailyWage = '';
  String _halfDayRate = '';
  String _minimumCharge = '';
  String _overtimeRate = '';

  // Location fields
  String _serviceRadius = '';
  String _website = '';

  final List<String> _steps = [
    'Service Type',
    'Personal Info',
    'Business Info',
    'Experience & Skills',
    'Availability',
    'Pricing',
    'Location & Contact',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Updated navigation logic with proper validation
  bool get _canProceedToNextStep {
    switch (_currentStep) {
      case 0: // Service Type
        return _selectedServiceType != null &&
            _selectedServiceType!.isNotEmpty &&
            _selectedServiceCategory != null &&
            _selectedServiceCategory!.isNotEmpty;
      case 1: // Personal Info
        return _firstName.isNotEmpty &&
            _lastName.isNotEmpty &&
            _email.isNotEmpty &&
            _phone.isNotEmpty;
      case 2: // Business Info
        return _businessName.isNotEmpty &&
            _address.isNotEmpty &&
            _city.isNotEmpty &&
            _state.isNotEmpty;
      case 3: // Skills
        return _selectedSpecializations.isNotEmpty;
      case 4: // Availability
        return _selectedWorkingDays.isNotEmpty;
      case 5: // Pricing
        return _dailyWage.isNotEmpty && _minimumCharge.isNotEmpty;
      case 6: // Location & Contact
        return _city.isNotEmpty && _serviceRadius.isNotEmpty;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_canProceedToNextStep) {
        if (_currentStep < _steps.length - 1) {
          setState(() {
            _currentStep++;
          });
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _submitWorkerData();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all required fields'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitWorkerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Generate worker ID
      String workerId = await _generateWorkerId();

      // Create worker model
      WorkerModel worker = WorkerModel(
        workerId: workerId,
        workerName: '$_firstName $_lastName',
        firstName: _firstName,
        lastName: _lastName,
        serviceType: _selectedServiceType!,
        serviceCategory: _selectedServiceCategory!,
        businessName: _businessName,
        location: WorkerLocation(
          latitude: 6.9271, // Default Colombo coordinates
          longitude: 79.8612,
          city: _city,
          state: _state,
          postalCode: _postalCode,
        ),
        rating: 0.0,
        experienceYears: int.tryParse(_experienceYears) ?? 0,
        jobsCompleted: 0,
        successRate: 0.0,
        pricing: WorkerPricing(
          dailyWageLkr: double.tryParse(_dailyWage) ?? 0.0,
          halfDayRateLkr: double.tryParse(_halfDayRate) ?? 0.0,
          minimumChargeLkr: double.tryParse(_minimumCharge) ?? 0.0,
          emergencyRateMultiplier: _emergencyService ? 1.5 : 1.0,
          overtimeHourlyLkr: double.tryParse(_overtimeRate) ?? 0.0,
        ),
        availability: WorkerAvailability(
          availableToday: true, // or based on your logic
          availableWeekends: _availableWeekends,
          emergencyService: _emergencyService,
          workingHours:
              '${_workingHoursStart} - ${_workingHoursEnd}', // Convert to string format
          responseTimeMinutes: 30, // or another appropriate default value
        ),
        capabilities: WorkerCapabilities(
          toolsOwned: _toolsOwned,
          vehicleAvailable: _vehicleAvailable,
          certified: _certified,
          insurance: _insurance,
          languages: _selectedLanguages,
        ),
        contact: WorkerContact(
          phoneNumber: _phone,
          whatsappAvailable: _whatsappAvailable,
          email: _email,
          website: _website.isNotEmpty ? _website : null,
        ),
        profile: WorkerProfile(
          bio: _bio,
          specializations: _selectedSpecializations,
          serviceRadiusKm: double.tryParse(_serviceRadius) ?? 20.0,
        ),
        verified: false,
      );

      // Save worker to Firestore
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .set(worker.toFirestore());

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'service_provider',
        'workerId': workerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Worker profile created successfully!');

      // Navigate to worker dashboard after delay
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushNamedAndRemoveUntil(
          context, '/worker_dashboard', (route) => false);
    } catch (e) {
      _showErrorSnackBar('Error creating worker profile: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _generateWorkerId() async {
    QuerySnapshot workerCount =
        await FirebaseFirestore.instance.collection('workers').get();
    int count = workerCount.docs.length + 1;
    return 'HM_${count.toString().padLeft(4, '0')}';
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed:
              _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
        ),
        title: Text(
          'Worker Registration',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
                  ),
                ],
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildServiceTypeStep(),
                  _buildPersonalInfoStep(),
                  _buildBusinessInfoStep(),
                  _buildExperienceSkillsStep(),
                  _buildAvailabilityStep(),
                  _buildPricingStep(),
                  _buildLocationContactStep(),
                ],
              ),
            ),
            // Navigation buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFFFF9800)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(color: Color(0xFFFF9800)),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canProceedToNextStep ? _nextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF9800),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
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
                              _currentStep == _steps.length - 1
                                  ? 'Complete Registration'
                                  : 'Next',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
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

  // Step 1: Service Type Selection
  Widget _buildServiceTypeStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What service do you provide?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Choose your primary service type',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: ServiceTypes.serviceTypesList.length,
            itemBuilder: (context, index) {
              final service = ServiceTypes.serviceTypesList[index];
              final serviceKey = service['key'] as String? ?? '';
              final serviceName =
                  service['name'] as String? ?? 'Unknown Service';

              final isSelected = _selectedServiceType == serviceKey;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedServiceType = serviceKey;
                    // Reset category when service type changes
                    _selectedServiceCategory = null;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFFFF9800).withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected ? Color(0xFFFF9800) : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build, // Default icon
                        size: 32,
                        color:
                            isSelected ? Color(0xFFFF9800) : Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        serviceName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? Color(0xFFFF9800) : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Show service category selection if service type is selected
          if (_selectedServiceType != null &&
              _selectedServiceType!.isNotEmpty) ...[
            SizedBox(height: 24),
            Text(
              'Service Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildDropdownField(
              label: 'Category',
              value: _selectedServiceCategory,
              items: ServiceTypes.getCategories(_selectedServiceType!) ?? [],
              onChanged: (value) =>
                  setState(() => _selectedServiceCategory = value),
              icon: Icons.category,
              hint: 'Select a category',
            ),
          ],
        ],
      ),
    );
  }

  // Step 2: Personal Information
  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            label: 'First Name',
            value: _firstName,
            onChanged: (value) => setState(() => _firstName = value),
            icon: Icons.person,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Last Name',
            value: _lastName,
            onChanged: (value) => setState(() => _lastName = value),
            icon: Icons.person_outline,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Email',
            value: _email,
            onChanged: (value) => setState(() => _email = value),
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number',
            value: _phone,
            onChanged: (value) => setState(() => _phone = value),
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // Step 3: Business Information
  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Provide your business details',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            label: 'Business Name',
            value: _businessName,
            onChanged: (value) => setState(() => _businessName = value),
            icon: Icons.business,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Years of Experience',
            value: _experienceYears,
            onChanged: (value) => setState(() => _experienceYears = value),
            icon: Icons.work,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            value: _address,
            onChanged: (value) => setState(() => _address = value),
            icon: Icons.location_on,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'City',
                  value: _city,
                  onChanged: (value) => setState(() => _city = value),
                  icon: Icons.location_city,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'State/Province',
                  value: _state,
                  onChanged: (value) => setState(() => _state = value),
                  icon: Icons.map,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Postal Code',
            value: _postalCode,
            onChanged: (value) => setState(() => _postalCode = value),
            icon: Icons.markunread_mailbox,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Bio',
            value: _bio,
            onChanged: (value) => setState(() => _bio = value),
            icon: Icons.description,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // Step 4: Experience & Skills
  Widget _buildExperienceSkillsStep() {
    final availableSpecializations =
        ServiceTypes.getSpecializations(_selectedServiceType);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills & Specializations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Select your areas of expertise',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            'Specializations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSpecializations.map((specialization) {
              final isSelected =
                  _selectedSpecializations.contains(specialization);
              return FilterChip(
                label: Text(specialization),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSpecializations.add(specialization);
                    } else {
                      _selectedSpecializations.remove(specialization);
                    }
                  });
                },
                selectedColor: Color(0xFFFF9800).withOpacity(0.2),
                checkmarkColor: Color(0xFFFF9800),
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          Text(
            'Languages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Languages.supportedLanguages.map((language) {
              final isSelected = _selectedLanguages.contains(language);
              return FilterChip(
                label: Text(language),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(language);
                    } else {
                      _selectedLanguages.remove(language);
                    }
                  });
                },
                selectedColor: Color(0xFFFF9800).withOpacity(0.2),
                checkmarkColor: Color(0xFFFF9800),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 5: Availability
  Widget _buildAvailabilityStep() {
    final List<String> weekDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Set your working hours and availability',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            'Working Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Start Time',
                  value: _workingHoursStart,
                  onChanged: (value) =>
                      setState(() => _workingHoursStart = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  label: 'End Time',
                  value: _workingHoursEnd,
                  onChanged: (value) =>
                      setState(() => _workingHoursEnd = value),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Working Days',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weekDays.map((day) {
              final isSelected = _selectedWorkingDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWorkingDays.add(day);
                    } else {
                      _selectedWorkingDays.remove(day);
                    }
                  });
                },
                selectedColor: Color(0xFFFF9800).withOpacity(0.2),
                checkmarkColor: Color(0xFFFF9800),
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          _buildSwitchTile(
            title: 'Emergency Service',
            subtitle: 'Available for emergency calls',
            value: _emergencyService,
            onChanged: (value) => setState(() => _emergencyService = value),
            icon: Icons.emergency,
          ),
        ],
      ),
    );
  }

  // Step 6: Pricing
  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Set your service rates',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            label: 'Daily Rate (LKR)',
            value: _dailyWage,
            onChanged: (value) => setState(() => _dailyWage = value),
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            hint: 'e.g., 5000',
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Half Day Rate (LKR) - Optional',
            value: _halfDayRate,
            onChanged: (value) => setState(() => _halfDayRate = value),
            icon: Icons.schedule,
            keyboardType: TextInputType.number,
            hint: 'Leave empty to auto-calculate',
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Minimum Charge (LKR)',
            value: _minimumCharge,
            onChanged: (value) => setState(() => _minimumCharge = value),
            icon: Icons.money,
            keyboardType: TextInputType.number,
            hint: 'e.g., 1000',
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Overtime Hourly Rate (LKR) - Optional',
            value: _overtimeRate,
            onChanged: (value) => setState(() => _overtimeRate = value),
            icon: Icons.access_time,
            keyboardType: TextInputType.number,
            hint: 'Leave empty to auto-calculate',
          ),
        ],
      ),
    );
  }

  // Step 7: Location & Contact
  Widget _buildLocationContactStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location & Contact',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Final details about your service area',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            label: 'Service Radius (km)',
            value: _serviceRadius,
            onChanged: (value) => setState(() => _serviceRadius = value),
            icon: Icons.location_searching,
            keyboardType: TextInputType.number,
            hint: 'e.g., 20',
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Website (Optional)',
            value: _website,
            onChanged: (value) => setState(() => _website = value),
            icon: Icons.web,
            keyboardType: TextInputType.url,
            hint: 'https://yourwebsite.com',
          ),
          SizedBox(height: 24),
          _buildSwitchTile(
            title: 'WhatsApp Available',
            subtitle: 'Clients can contact you via WhatsApp',
            value: _whatsappAvailable,
            onChanged: (value) => setState(() => _whatsappAvailable = value),
            icon: Icons.message,
          ),
          _buildSwitchTile(
            title: 'Tools Owned',
            subtitle: 'I have my own tools and equipment',
            value: _toolsOwned,
            onChanged: (value) => setState(() => _toolsOwned = value),
            icon: Icons.build_circle,
          ),
          _buildSwitchTile(
            title: 'Vehicle Available',
            subtitle: 'I have transportation for service calls',
            value: _vehicleAvailable,
            onChanged: (value) => setState(() => _vehicleAvailable = value),
            icon: Icons.directions_car,
          ),
          _buildSwitchTile(
            title: 'Certified',
            subtitle: 'I have relevant certifications',
            value: _certified,
            onChanged: (value) => setState(() => _certified = value),
            icon: Icons.verified,
          ),
          _buildSwitchTile(
            title: 'Insurance',
            subtitle: 'I have professional insurance coverage',
            value: _insurance,
            onChanged: (value) => setState(() => _insurance = value),
            icon: Icons.security,
          ),
        ],
      ),
    );
  }

  // Helper widget methods
  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFFF9800)),
            hintText: hint ?? 'Enter $label',
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
              borderSide: BorderSide(color: Color(0xFFFF9800)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: (value != null && value.isNotEmpty && items.contains(value))
              ? value
              : null,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFFF9800)),
            hintText: hint ?? 'Select $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFFF9800)),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: true,
          onTap: () async {
            TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(value.split(':')[0]),
                minute: int.parse(value.split(':')[1]),
              ),
            );
            if (time != null) {
              String formattedTime =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              onChanged(formattedTime);
            }
          },
          decoration: InputDecoration(
            suffixIcon: Icon(Icons.access_time, color: Color(0xFFFF9800)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFFF9800)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFFFF9800),
        secondary: Icon(icon, color: Color(0xFFFF9800)),
      ),
    );
  }
}
