import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
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

  // Form data
  String? _selectedServiceType;
  String _selectedServiceCategory = '';
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

  // Available options for dropdowns
  final Map<String, String> _serviceTypes = {
    'plumbing': 'Plumbing Services',
    'electrical': 'Electrical Services',
    'carpentry': 'Carpentry Services',
    'painting': 'Painting Services',
    'cleaning': 'Cleaning Services',
    'gardening': 'Gardening Services',
    'ac_repair': 'AC Repair',
    'appliance_repair': 'Appliance Repair',
    'masonry': 'Masonry Services',
    'roofing': 'Roofing Services',
    'general_maintenance': 'General Maintenance',
  };

  final List<String> _workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> _languages = ['Sinhala', 'Tamil', 'English'];

  // Specializations based on service type
  final Map<String, List<String>> _specializationsByService = {
    'plumbing': [
      'Pipe Installation',
      'Leak Repair',
      'Drain Cleaning',
      'Water Heater',
      'Bathroom Fitting'
    ],
    'electrical': [
      'Wiring',
      'Switch Installation',
      'Fan Installation',
      'Light Fitting',
      'Electrical Repair'
    ],
    'carpentry': [
      'Furniture Making',
      'Door Installation',
      'Window Fitting',
      'Cabinet Making',
      'Wood Repair'
    ],
    'painting': [
      'Interior Painting',
      'Exterior Painting',
      'Wall Texture',
      'Primer Application',
      'Color Consultation'
    ],
    'cleaning': [
      'House Cleaning',
      'Office Cleaning',
      'Deep Cleaning',
      'Post-Construction Cleaning',
      'Move-in/out Cleaning'
    ],
    'gardening': [
      'Lawn Care',
      'Plant Care',
      'Garden Design',
      'Tree Pruning',
      'Landscaping'
    ],
    'ac_repair': [
      'AC Installation',
      'AC Repair',
      'AC Maintenance',
      'Gas Filling',
      'Filter Cleaning'
    ],
    'appliance_repair': [
      'Washing Machine',
      'Refrigerator',
      'Microwave',
      'Dishwasher',
      'Dryer'
    ],
    'masonry': [
      'Brick Work',
      'Stone Work',
      'Concrete Work',
      'Wall Construction',
      'Foundation Work'
    ],
    'roofing': [
      'Roof Installation',
      'Roof Repair',
      'Gutter Installation',
      'Roof Cleaning',
      'Waterproofing'
    ],
    'general_maintenance': [
      'Basic Repairs',
      'Property Maintenance',
      'Fixture Installation',
      'Minor Renovations',
      'Handyman Services'
    ],
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceedToNextStep {
    switch (_currentStep) {
      case 0: // Service Type
        return _selectedServiceType != null && _selectedServiceType!.isNotEmpty;
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
        return _selectedSpecializations.isNotEmpty &&
            _experienceYears.isNotEmpty;
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
    if (_currentStep == 0) {
      if (_selectedServiceType != null && _selectedServiceType!.isNotEmpty) {
        setState(() {
          _currentStep++;
          // Set service category based on service type
          _selectedServiceCategory = _serviceTypes[_selectedServiceType] ?? '';
        });
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _showValidationError('Please select a service type to continue.');
      }
      return;
    }

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
          _submitRegistration();
        }
      } else {
        _showValidationError(_getValidationMessage());
      }
    } else {
      _showValidationError('Please fill in all required fields correctly.');
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
    } else {
      Navigator.pop(context);
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getValidationMessage() {
    switch (_currentStep) {
      case 0:
        return 'Please select a service type to continue.';
      case 1:
        return 'Please fill in all personal information fields.';
      case 2:
        return 'Please fill in all business information fields.';
      case 3:
        return 'Please select at least one specialization and enter experience years.';
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
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF9800),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text(
                            _currentStep == _steps.length - 1
                                ? 'Complete Registration'
                                : 'Next',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
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

  Widget _buildServiceTypeStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Your Service Type',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Choose the main service you provide',
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
            itemCount: _serviceTypes.length,
            itemBuilder: (context, index) {
              String serviceKey = _serviceTypes.keys.elementAt(index);
              String serviceName = _serviceTypes[serviceKey]!;
              bool isSelected = _selectedServiceType == serviceKey;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedServiceType = serviceKey;
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
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getServiceIcon(serviceKey),
                        size: 40,
                        color:
                            isSelected ? Color(0xFFFF9800) : Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        serviceName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected ? Color(0xFFFF9800) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_selectedServiceType != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFF9800).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFFFF9800)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected: ${_serviceTypes[_selectedServiceType!]}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
            TextFormField(
              decoration: InputDecoration(
                labelText: 'First Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
                labelText: 'Last Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
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
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Business Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _businessName = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Business Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business address';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _address = value;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _city = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'State/Province *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter state';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _state = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Postal Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.markunread_mailbox),
              ),
              onChanged: (value) {
                setState(() {
                  _postalCode = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Website (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.web),
              ),
              onChanged: (value) {
                setState(() {
                  _website = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceStep() {
    List<String> availableSpecializations = _selectedServiceType != null
        ? _specializationsByService[_selectedServiceType!] ?? []
        : [];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience & Skills',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Years of Experience *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter years of experience';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _experienceYears = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Bio/Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Tell customers about your expertise and approach...',
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _bio = value;
                });
              },
            ),
            SizedBox(height: 24),
            Text(
              'Specializations *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Select the services you specialize in',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSpecializations.map((specialization) {
                bool isSelected =
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((language) {
                bool isSelected = _selectedLanguages.contains(language);
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
            Text(
              'Capabilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            CheckboxListTile(
              title: Text('I have my own tools'),
              value: _toolsOwned,
              onChanged: (value) {
                setState(() {
                  _toolsOwned = value ?? false;
                });
              },
              activeColor: Color(0xFFFF9800),
            ),
            CheckboxListTile(
              title: Text('I have a vehicle'),
              value: _vehicleAvailable,
              onChanged: (value) {
                setState(() {
                  _vehicleAvailable = value ?? false;
                });
              },
              activeColor: Color(0xFFFF9800),
            ),
            CheckboxListTile(
              title: Text('I am certified/licensed'),
              value: _certified,
              onChanged: (value) {
                setState(() {
                  _certified = value ?? false;
                });
              },
              activeColor: Color(0xFFFF9800),
            ),
            CheckboxListTile(
              title: Text('I have insurance'),
              value: _insurance,
              onChanged: (value) {
                setState(() {
                  _insurance = value ?? false;
                });
              },
              activeColor: Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Text(
            'Working Days *',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _workingDays.map((day) {
              bool isSelected = _selectedWorkingDays.contains(day);
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
          Text(
            'Working Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                  ),
                  value: _workingHoursStart,
                  items: _generateTimeSlots(),
                  onChanged: (value) {
                    setState(() {
                      _workingHoursStart = value!;
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                  ),
                  value: _workingHoursEnd,
                  items: _generateTimeSlots(),
                  onChanged: (value) {
                    setState(() {
                      _workingHoursEnd = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Additional Availability Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          CheckboxListTile(
            title: Text('Available on weekends'),
            value: _availableWeekends,
            onChanged: (value) {
              setState(() {
                _availableWeekends = value ?? false;
              });
            },
            activeColor: Color(0xFFFF9800),
          ),
          CheckboxListTile(
            title: Text('Emergency service available'),
            value: _emergencyService,
            onChanged: (value) {
              setState(() {
                _emergencyService = value ?? false;
              });
            },
            activeColor: Color(0xFFFF9800),
          ),
          CheckboxListTile(
            title: Text('WhatsApp available'),
            value: _whatsappAvailable,
            onChanged: (value) {
              setState(() {
                _whatsappAvailable = value ?? false;
              });
            },
            activeColor: Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Set your service rates (in LKR)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Daily Wage (LKR) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 5000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your daily wage';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _dailyWage = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Half Day Rate (LKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 3000',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _halfDayRate = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Minimum Charge (LKR) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 1500',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter minimum charge';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _minimumCharge = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Overtime Rate per Hour (LKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 800',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _overtimeRate = value;
                });
              },
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      SizedBox(width: 8),
                      Text(
                        'Pricing Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Research market rates in your area\n'
                    '• Consider your experience level\n'
                    '• Include travel time in pricing\n'
                    '• Be competitive but fair',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location & Contact',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Service Radius (km) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_searching),
                hintText: 'e.g., 15',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter service radius';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _serviceRadius = value;
                });
              },
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      SizedBox(width: 8),
                      Text(
                        'Registration Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildSummaryItem(
                      'Service', _serviceTypes[_selectedServiceType] ?? ''),
                  _buildSummaryItem('Name', '$_firstName $_lastName'),
                  _buildSummaryItem('Business', _businessName),
                  _buildSummaryItem('Experience', '$_experienceYears years'),
                  _buildSummaryItem(
                      'Specializations', _selectedSpecializations.join(', ')),
                  _buildSummaryItem(
                      'Working Days', _selectedWorkingDays.join(', ')),
                  _buildSummaryItem('Daily Rate', 'LKR $_dailyWage'),
                  _buildSummaryItem('Location', '$_city, $_state'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _generateTimeSlots() {
    List<DropdownMenuItem<String>> items = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        String time =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        items.add(DropdownMenuItem(
          value: time,
          child: Text(time),
        ));
      }
    }
    return items;
  }

  Future<void> _submitRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate worker ID
      String workerId = await WorkerService.generateWorkerId();

      // Create worker model
      WorkerModel worker = WorkerModel(
        workerId: workerId,
        workerName: '$_firstName $_lastName',
        firstName: _firstName,
        lastName: _lastName,
        serviceType: _selectedServiceType!,
        serviceCategory: _selectedServiceCategory,
        businessName: _businessName,
        location: WorkerLocation(
          latitude: 0.0, // Will be updated when user enables location
          longitude: 0.0,
          city: _city,
          state: _state,
          postalCode: _postalCode,
        ),
        experienceYears: int.tryParse(_experienceYears) ?? 0,
        pricing: WorkerPricing(
          dailyWageLkr: double.tryParse(_dailyWage) ?? 0.0,
          halfDayRateLkr: double.tryParse(_halfDayRate) ?? 0.0,
          minimumChargeLkr: double.tryParse(_minimumCharge) ?? 0.0,
          emergencyRateMultiplier: _emergencyService ? 1.5 : 1.0,
          overtimeHourlyLkr: double.tryParse(_overtimeRate) ?? 0.0,
        ),
        availability: WorkerAvailability(
          availableToday: true,
          availableWeekends: _availableWeekends,
          emergencyService: _emergencyService,
          workingHours: '$_workingHoursStart - $_workingHoursEnd',
          responseTimeMinutes: 30,
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
          serviceRadiusKm: double.tryParse(_serviceRadius) ?? 10.0,
        ),
        verified: false,
      );

      // Save worker to database
      await WorkerService.saveWorker(worker);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to account type or main screen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
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
