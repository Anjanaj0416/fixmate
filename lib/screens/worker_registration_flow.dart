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

  // FIXED: Create separate form keys for each step instead of single _formKey
  final _serviceTypeFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _businessInfoFormKey = GlobalKey<FormState>();
  final _experienceFormKey = GlobalKey<FormState>();
  final _availabilityFormKey = GlobalKey<FormState>();
  final _pricingFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();

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

  // Specializations by service type
  final Map<String, List<String>> _specializationsByService = {
    'plumbing': [
      'Pipe Installation',
      'Leak Repair',
      'Drain Cleaning',
      'Water Heater Repair',
      'Bathroom Plumbing',
      'Kitchen Plumbing',
      'Emergency Plumbing',
    ],
    'electrical': [
      'Wiring Installation',
      'Circuit Breaker Repair',
      'Outlet Installation',
      'Lighting Installation',
      'Electrical Panel Upgrade',
      'Emergency Electrical',
    ],
    'carpentry': [
      'Custom Furniture',
      'Door Installation',
      'Window Installation',
      'Kitchen Cabinets',
      'Flooring',
      'Deck Building',
    ],
    'painting': [
      'Interior Painting',
      'Exterior Painting',
      'Wall Preparation',
      'Texture Work',
      'Commercial Painting',
    ],
    'cleaning': [
      'House Cleaning',
      'Office Cleaning',
      'Deep Cleaning',
      'Move-in/Move-out Cleaning',
      'Post-Construction Cleanup',
    ],
    'gardening': [
      'Lawn Maintenance',
      'Landscaping',
      'Tree Trimming',
      'Garden Design',
      'Irrigation Systems',
    ],
    'ac_repair': [
      'AC Installation',
      'AC Repair',
      'AC Maintenance',
      'Duct Cleaning',
      'Thermostat Installation',
    ],
    'appliance_repair': [
      'Refrigerator Repair',
      'Washing Machine Repair',
      'Dishwasher Repair',
      'Oven Repair',
      'Dryer Repair',
    ],
    'masonry': [
      'Brick Work',
      'Stone Work',
      'Concrete Work',
      'Tile Installation',
      'Retaining Walls',
    ],
    'roofing': [
      'Roof Repair',
      'Roof Installation',
      'Gutter Installation',
      'Roof Inspection',
      'Emergency Roof Repair',
    ],
    'general_maintenance': [
      'Preventive Maintenance',
      'Repair Work',
      'Installation Services',
      'Emergency Services',
    ],
  };

  final List<String> _availableLanguages = [
    'English',
    'Sinhala',
    'Tamil',
    'Arabic',
    'Chinese',
    'Hindi',
    'Other',
  ];

  final List<String> _workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // FIXED: Updated validation to use correct form keys
  bool get _canProceedToNextStep {
    switch (_currentStep) {
      case 0:
        return _selectedServiceType != null;
      case 1:
        return _firstName.isNotEmpty &&
            _lastName.isNotEmpty &&
            _email.isNotEmpty &&
            _phone.isNotEmpty;
      case 2:
        return _businessName.isNotEmpty &&
            _address.isNotEmpty &&
            _city.isNotEmpty &&
            _state.isNotEmpty;
      case 3:
        return _selectedSpecializations.isNotEmpty &&
            _experienceYears.isNotEmpty;
      case 4:
        return _selectedWorkingDays.isNotEmpty;
      case 5:
        return _dailyWage.isNotEmpty;
      case 6:
        return _serviceRadius.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    // FIXED: Use the appropriate form key for validation
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        isValid = _serviceTypeFormKey.currentState?.validate() ?? true;
        break;
      case 1:
        isValid = _personalInfoFormKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _businessInfoFormKey.currentState?.validate() ?? false;
        break;
      case 3:
        isValid = _experienceFormKey.currentState?.validate() ?? false;
        break;
      case 4:
        isValid = _availabilityFormKey.currentState?.validate() ?? false;
        break;
      case 5:
        isValid = _pricingFormKey.currentState?.validate() ?? false;
        break;
      case 6:
        isValid = _locationFormKey.currentState?.validate() ?? false;
        break;
    }

    if (_selectedServiceType == null && _currentStep == 0) {
      _showValidationError('Please select a service type to continue.');
      return;
    }

    if (isValid && _canProceedToNextStep) {
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
  void initState() {
    super.initState();
    _loadUserData();
  }

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
        title: Text(
          'Worker Registration',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _steps.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: PageView(
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(_currentStep == _steps.length - 1
                        ? 'Complete Registration'
                        : 'Next'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Service Type Step with separate form key
  Widget _buildServiceTypeStep() {
    return Form(
      key: _serviceTypeFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What type of service do you provide?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Select the main service category that best describes your expertise.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _serviceTypes.length,
              itemBuilder: (context, index) {
                String key = _serviceTypes.keys.elementAt(index);
                String value = _serviceTypes.values.elementAt(index);
                bool isSelected = _selectedServiceType == key;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedServiceType = key;
                      _selectedServiceCategory = value;
                      // Reset specializations when service type changes
                      _selectedSpecializations.clear();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getServiceIcon(key),
                          size: 32,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                        ),
                        SizedBox(height: 8),
                        Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Personal Info Step with separate form key

  // FIXED: Business Info Step with separate form key
  Widget _buildBusinessInfoStep() {
    return Form(
      key: _businessInfoFormKey,
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

  // FIXED: Experience Step with separate form key
  Widget _buildExperienceStep() {
    List<String> availableSpecializations = _selectedServiceType != null
        ? _specializationsByService[_selectedServiceType!] ?? []
        : [];

    return Form(
      key: _experienceFormKey,
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
                  return 'Please enter your years of experience';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _experienceYears = value;
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
              'Select all specializations that apply to your skills',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
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
                  selectedColor:
                      Theme.of(context).primaryColor.withOpacity(0.3),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            Text(
              'Languages Spoken',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableLanguages.map((language) {
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
                  selectedColor:
                      Theme.of(context).primaryColor.withOpacity(0.3),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Bio / Professional Summary',
                border: OutlineInputBorder(),
                hintText:
                    'Describe your experience and what makes you stand out...',
              ),
              maxLines: 4,
              onChanged: (value) {
                setState(() {
                  _bio = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Availability Step with separate form key
  Widget _buildAvailabilityStep() {
    return Form(
      key: _availabilityFormKey,
      child: SingleChildScrollView(
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
            SizedBox(height: 16),
            Column(
              children: _workingDays.map((day) {
                bool isSelected = _selectedWorkingDays.contains(day);
                return CheckboxListTile(
                  title: Text(day),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedWorkingDays.add(day);
                      } else {
                        _selectedWorkingDays.remove(day);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            Text(
              'Working Hours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      hintText: '09:00',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _workingHoursStart = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                      hintText: '17:00',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _workingHoursEnd = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SwitchListTile(
              title: Text('Available on Weekends'),
              subtitle: Text('Do you work on Saturday and Sunday?'),
              value: _availableWeekends,
              onChanged: (bool value) {
                setState(() {
                  _availableWeekends = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Emergency Services'),
              subtitle: Text('Available for urgent/emergency calls'),
              value: _emergencyService,
              onChanged: (bool value) {
                setState(() {
                  _emergencyService = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Own Tools'),
              subtitle: Text('I have my own tools and equipment'),
              value: _toolsOwned,
              onChanged: (bool value) {
                setState(() {
                  _toolsOwned = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Vehicle Available'),
              subtitle: Text('I have transportation to job sites'),
              value: _vehicleAvailable,
              onChanged: (bool value) {
                setState(() {
                  _vehicleAvailable = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Certified'),
              subtitle: Text('I have relevant certifications'),
              value: _certified,
              onChanged: (bool value) {
                setState(() {
                  _certified = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Insured'),
              subtitle: Text('I have liability insurance'),
              value: _insurance,
              onChanged: (bool value) {
                setState(() {
                  _insurance = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('WhatsApp Available'),
              subtitle: Text('Customers can contact me via WhatsApp'),
              value: _whatsappAvailable,
              onChanged: (bool value) {
                setState(() {
                  _whatsappAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Pricing Step with separate form key
  Widget _buildPricingStep() {
    return Form(
      key: _pricingFormKey,
      child: SingleChildScrollView(
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
              'Set your rates in Sri Lankan Rupees (LKR)',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Daily Wage (LKR) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 3000',
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
                hintText: 'e.g., 1500',
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
                labelText: 'Minimum Charge (LKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 500',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _minimumCharge = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Overtime Hourly Rate (LKR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
                hintText: 'e.g., 400',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _overtimeRate = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Location Step with separate form key

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not specified' : value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
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

      print('🔄 Starting worker registration for user: ${user.uid}');

      // Generate worker ID
      String workerId = await WorkerService.generateWorkerId();
      print('✅ Generated worker ID: $workerId');

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

      print('✅ Worker model created');

      // Save worker to database
      await WorkerService.saveWorker(worker);
      print('✅ Worker saved to Firestore');

      // CRITICAL: Wait for Firestore to propagate the write
      await Future.delayed(Duration(milliseconds: 500));

      // Verify the worker document was created
      DocumentSnapshot verifyDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      if (!verifyDoc.exists) {
        throw Exception('Worker document was not created properly');
      }

      print('✅ Verified worker document exists');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait for success message to be visible
      await Future.delayed(Duration(seconds: 1));

      print('🔄 Navigating to worker dashboard...');

      // Navigate to worker dashboard and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(
          context, '/worker_dashboard', (route) => false);
    } catch (e) {
      print('❌ Registration error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Add this new method to load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            // Pre-fill personal information from user signup data
            String fullName = userData['name'] ?? '';
            List<String> nameParts = fullName.split(' ');
            _firstName = nameParts.isNotEmpty ? nameParts[0] : '';
            _lastName =
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

            _email = userData['email'] ?? '';
            _phone = userData['phone'] ?? '';
            _address = userData['address'] ?? '';

            // Pre-fill location information from nearest town
            _city = userData['nearestTown'] ?? '';

            // Set state to empty string if not found (for Province)
            _state = ''; // User will need to provide this
            _postalCode = ''; // User will need to provide this
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not load your information. Please enter manually.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

// REPLACE the existing _buildPersonalInfoStep() method with this version:
  Widget _buildPersonalInfoStep() {
    return Form(
      key: _personalInfoFormKey,
      child: SingleChildScrollView(
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
              'Information from your account',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // First Name - Pre-filled and read-only
            TextFormField(
              initialValue: _firstName,
              decoration: InputDecoration(
                labelText: 'First Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
              enabled: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Last Name - Pre-filled and read-only
            TextFormField(
              initialValue: _lastName,
              decoration: InputDecoration(
                labelText: 'Last Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
              enabled: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Email - Pre-filled and read-only
            TextFormField(
              initialValue: _email,
              decoration: InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
              enabled: false,
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
            ),
            SizedBox(height: 16),

            // Phone - Pre-filled and read-only
            TextFormField(
              initialValue: _phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
              enabled: false,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Info message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These details are from your account and cannot be changed here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
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

// REPLACE the existing _buildLocationStep() method with this version:
  Widget _buildLocationStep() {
    return Form(
      key: _locationFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location & Service Area',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Some information is from your account',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Address - Pre-filled from signup, read-only
            TextFormField(
              initialValue: _address,
              decoration: InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
              enabled: false,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            Row(
              children: [
                // City/Town - Pre-filled from nearest town, read-only
                Expanded(
                  child: TextFormField(
                    initialValue: _city,
                    decoration: InputDecoration(
                      labelText: 'City/Town *',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon:
                          Icon(Icons.lock, size: 16, color: Colors.grey),
                    ),
                    enabled: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),

                // State/Province - User needs to provide this
                Expanded(
                  child: TextFormField(
                    initialValue: _state,
                    decoration: InputDecoration(
                      labelText: 'Province *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Western',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter province';
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

            // Postal Code - User needs to provide this
            TextFormField(
              initialValue: _postalCode,
              decoration: InputDecoration(
                labelText: 'Postal Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.markunread_mailbox),
                hintText: 'Optional',
              ),
              onChanged: (value) {
                setState(() {
                  _postalCode = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Service Radius - User needs to provide this
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Service Radius (km) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., 10',
                helperText: 'How far are you willing to travel for jobs?',
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
            SizedBox(height: 16),

            // Website - Optional
            TextFormField(
              initialValue: _website,
              decoration: InputDecoration(
                labelText: 'Website (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.web),
                hintText: 'https://yourwebsite.com',
              ),
              onChanged: (value) {
                setState(() {
                  _website = value;
                });
              },
            ),

            SizedBox(height: 16),

            // Info message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Address and City are from your account. Please provide Province and Service Radius.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
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
}
