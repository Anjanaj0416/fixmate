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

  // FIXED: Updated navigation logic with proper validation
  bool get _canProceedToNextStep {
    switch (_currentStep) {
      case 0: // Service Type
        bool hasServiceType =
            _selectedServiceType != null && _selectedServiceType!.isNotEmpty;
        print('Service type check: $hasServiceType');
        return hasServiceType; // Category is automatically set
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

  // FIXED: Updated _nextStep method to handle service type step separately
  void _nextStep() {
    print('Current step: $_currentStep');
    print('Selected service type: $_selectedServiceType');
    print('Selected service category: $_selectedServiceCategory');
    print('Can proceed: $_canProceedToNextStep');

    // FIXED: Handle service type step (step 0) separately - no form validation needed
    if (_currentStep == 0) {
      if (_selectedServiceType != null && _selectedServiceType!.isNotEmpty) {
        setState(() {
          _currentStep++;
        });

        // Animate to next page
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Show validation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a service type to continue.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // Exit early for step 0
    }

    // For other steps, validate the form first
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
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  NeverScrollableScrollPhysics(), // Disable swipe navigation
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
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Color(0xFFFF9800)),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(color: Color(0xFFFF9800)),
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStep,
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

  // FIXED: Step 1 - Service Type Selection with proper state management
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
                  print('Tapped on service: $serviceKey');
                  setState(() {
                    _selectedServiceType = serviceKey;
                    _selectedServiceCategory =
                        ServiceTypes.getCategory(serviceKey);
                  });
                  print(
                      'Updated - Service: $_selectedServiceType, Category: $_selectedServiceCategory');
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

  // Placeholder methods for other steps - you'll need to implement these
  Widget _buildPersonalInfoStep() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            // Add your personal info form fields here
            TextFormField(
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _firstName = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _lastName = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _phone = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return Center(child: Text('Business Info Step - Implement form fields'));
  }

  Widget _buildExperienceStep() {
    return Center(child: Text('Experience Step - Implement form fields'));
  }

  Widget _buildAvailabilityStep() {
    return Center(child: Text('Availability Step - Implement form fields'));
  }

  Widget _buildPricingStep() {
    return Center(child: Text('Pricing Step - Implement form fields'));
  }

  Widget _buildLocationStep() {
    return Center(child: Text('Location Step - Implement form fields'));
  }

  // Placeholder for registration submission
  void _submitRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Implement your registration logic here
      print('Submitting registration...');

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back or to success page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
