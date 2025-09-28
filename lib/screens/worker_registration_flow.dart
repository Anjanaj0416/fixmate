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
  String _selectedServiceCategory =
      ''; // No longer nullable, automatically set to match service type
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
        return _selectedServiceType != null && _selectedServiceType!.isNotEmpty;
      // Removed category check since it's automatically set
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
    print('Current step: $_currentStep');
    print('Selected service type: $_selectedServiceType');
    print('Selected service category: $_selectedServiceCategory');
    print('Can proceed: $_canProceedToNextStep');

    // Validate the current form
    if (_formKey.currentState?.validate() ?? false) {
      // Check if we can proceed to next step
      if (_canProceedToNextStep) {
        if (_currentStep < _steps.length - 1) {
          setState(() {
            _currentStep++;
          });

          // Animate to next page
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          // Final step - submit registration
          _submitRegistration();
        }
      } else {
        // Show validation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getValidationMessage()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper method to get validation message for current step
  String _getValidationMessage() {
    switch (_currentStep) {
      case 0:
        return 'Please select a service type to continue.';
      case 1:
        return 'Please fill in all personal information fields.';
      case 2:
        return 'Please fill in all business information fields.';
      case 3:
        return 'Please select at least one specialization.';
      case 4:
        return 'Please select your working days.';
      case 5:
        return 'Please fill in your pricing information.';
      case 6:
        return 'Please fill in your location and service radius.';
      default:
        return 'Please complete all required fields.';
    }
  }

// Also update the _previousStep method for completeness
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });

      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // If on first step, go back to previous screen
      Navigator.pop(context);
    }
  }

  // Helper method to get appropriate icons for each service type
  IconData _getServiceIcon(String serviceKey) {
    switch (serviceKey) {
      case 'ac_repair':
        return Icons.ac_unit;
      case 'appliance_repair':
        return Icons.kitchen;
      case 'carpentry':
        return Icons.carpenter;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'electrical':
        return Icons.electrical_services;
      case 'gardening':
        return Icons.yard;
      case 'general_maintenance':
        return Icons.handyman;
      case 'masonry':
        return Icons.foundation;
      case 'painting':
        return Icons.format_paint;
      case 'plumbing':
        return Icons.plumbing;
      case 'roofing':
        return Icons.roofing;
      default:
        return Icons.build;
    }
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
          onPressed:
              _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Registration',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            Text(
              'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
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
                _buildExperienceStep(),
                _buildAvailabilityStep(),
                _buildPricingStep(),
                _buildLocationStep(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(color: Colors.black),
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
    );
  }

  // Step 1: Service Type Selection - UPDATED WITHOUT CATEGORY DROPDOWN
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
                    // Automatically set the category to be the same as the service name
                    _selectedServiceCategory =
                        ServiceTypes.getCategory(serviceKey);
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
                        _getServiceIcon(serviceKey),
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

          // Show selected service information
          if (_selectedServiceType != null &&
              _selectedServiceType!.isNotEmpty) ...[
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFFF9800).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFFFF9800),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Selected Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    ServiceTypes.getServiceName(_selectedServiceType!),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Category: ${ServiceTypes.getCategory(_selectedServiceType!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
            icon: Icons.work_history,
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
            icon: Icons.mail,
          ),
        ],
      ),
    );
  }

  // Step 4: Experience & Skills
  Widget _buildExperienceStep() {
    final availableSpecializations =
        ServiceTypes.getSpecializations(_selectedServiceType);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience & Skills',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Tell us about your expertise',
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
          SizedBox(height: 24),
          _buildTextField(
            label: 'Bio',
            value: _bio,
            onChanged: (value) => setState(() => _bio = value),
            icon: Icons.description,
            maxLines: 3,
            hint: 'Tell customers about your experience and approach to work',
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
            'Set your working schedule',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          Row(
            children: [
              Expanded(
                child:
                    _buildTimeField('Start Time', _workingHoursStart, (value) {
                  setState(() => _workingHoursStart = value);
                }),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTimeField('End Time', _workingHoursEnd, (value) {
                  setState(() => _workingHoursEnd = value);
                }),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildSwitchTile(
            'Available on Weekends',
            _availableWeekends,
            (value) => setState(() => _availableWeekends = value),
          ),
          _buildSwitchTile(
            'Emergency Service Available',
            _emergencyService,
            (value) => setState(() => _emergencyService = value),
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
            label: 'Daily Wage (LKR)',
            value: _dailyWage,
            onChanged: (value) => setState(() => _dailyWage = value),
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Half Day Rate (LKR)',
            value: _halfDayRate,
            onChanged: (value) => setState(() => _halfDayRate = value),
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Minimum Charge (LKR)',
            value: _minimumCharge,
            onChanged: (value) => setState(() => _minimumCharge = value),
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Overtime Rate (LKR/hour)',
            value: _overtimeRate,
            onChanged: (value) => setState(() => _overtimeRate = value),
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // Step 7: Location & Contact
  Widget _buildLocationStep() {
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
            'Final details',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            label: 'Service Radius (km)',
            value: _serviceRadius,
            onChanged: (value) => setState(() => _serviceRadius = value),
            icon: Icons.location_searching,
            keyboardType: TextInputType.number,
            hint: 'How far are you willing to travel?',
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Website (Optional)',
            value: _website,
            onChanged: (value) => setState(() => _website = value),
            icon: Icons.web,
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 24),
          _buildSwitchTile(
            'I own tools for my work',
            _toolsOwned,
            (value) => setState(() => _toolsOwned = value),
          ),
          _buildSwitchTile(
            'I have a vehicle',
            _vehicleAvailable,
            (value) => setState(() => _vehicleAvailable = value),
          ),
          _buildSwitchTile(
            'I am certified/licensed',
            _certified,
            (value) => setState(() => _certified = value),
          ),
          _buildSwitchTile(
            'I have insurance',
            _insurance,
            (value) => setState(() => _insurance = value),
          ),
          _buildSwitchTile(
            'WhatsApp available',
            _whatsappAvailable,
            (value) => setState(() => _whatsappAvailable = value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType? keyboardType,
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

  Widget _buildTimeField(
      String label, String value, Function(String) onChanged) {
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
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.access_time, color: Color(0xFFFF9800)),
            hintText: 'HH:MM',
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
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFFFF9800),
      ),
    );
  }

  // Updated _submitRegistration method with correct parameter names
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create worker model with correct parameter names
      final WorkerModel worker = WorkerModel(
        workerId: user.uid,
        // Remove userId parameter - it doesn't exist in WorkerModel
        workerName: '$_firstName $_lastName',
        firstName: _firstName,
        lastName: _lastName,
        serviceType: _selectedServiceType!,
        serviceCategory: _selectedServiceCategory,
        businessName: _businessName,
        location: WorkerLocation(
          latitude: 0.0, // You'll need to get actual coordinates
          longitude: 0.0,
          // Remove address parameter - it doesn't exist in WorkerLocation
          city: _city,
          state: _state,
          postalCode: _postalCode,
        ),
        rating: 0.0,
        experienceYears: int.tryParse(_experienceYears) ?? 0,
        jobsCompleted: 0,
        successRate: 0.0,
        pricing: WorkerPricing(
          // Fix parameter names for WorkerPricing
          dailyWageLkr: double.tryParse(_dailyWage) ?? 0.0,
          halfDayRateLkr: double.tryParse(_halfDayRate) ?? 0.0,
          minimumChargeLkr: double.tryParse(_minimumCharge) ?? 0.0,
          emergencyRateMultiplier: _emergencyService ? 1.5 : 1.0,
          overtimeHourlyLkr: double.tryParse(_overtimeRate) ?? 0.0,
        ),
        availability: WorkerAvailability(
          // Fix parameter names for WorkerAvailability
          availableToday: true, // Default value
          availableWeekends: _availableWeekends,
          emergencyService: _emergencyService,
          workingHours: '$_workingHoursStart - $_workingHoursEnd',
          responseTimeMinutes: 30, // Default value
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
          website: _website.isEmpty ? null : _website,
        ),
        profile: WorkerProfile(
          bio: _bio,
          specializations: _selectedSpecializations,
          serviceRadiusKm: double.tryParse(_serviceRadius) ?? 10.0,
        ),
        // Remove these parameters as they don't exist in WorkerModel constructor
        // isVerified: false,
        // isActive: true,
        // rating: 0.0, // already set above
        // reviewCount: 0,
        // completedJobs: 0,
        // joinedDate: DateTime.now(),
        // lastActive: DateTime.now(),
        verified: false,
      );

      // Save worker to database - you'll need to implement this method
      // await WorkerService.saveWorker(worker);

      // Alternative: Save directly to Firestore
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
        'workerId': worker.workerId,
        'serviceType': _selectedServiceType,
        'serviceCategory': _selectedServiceCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to worker dashboard
      Navigator.pushNamedAndRemoveUntil(
          context, '/worker_dashboard', (route) => false);
    } catch (e) {
      print('Registration error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  } // Updated worker data creation and save method
}
