import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../services/id_generator_service.dart';
import '../constants/service_constants.dart';

class WorkerRegistrationFlow extends StatefulWidget {
  @override
  _WorkerRegistrationFlowState createState() => _WorkerRegistrationFlowState();
}

class _WorkerRegistrationFlowState extends State<WorkerRegistrationFlow> {
  PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _userDataLoaded = false;

  // Form keys for each step
  final _serviceTypeFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _businessInfoFormKey = GlobalKey<FormState>();
  final _experienceFormKey = GlobalKey<FormState>();
  final _availabilityFormKey = GlobalKey<FormState>();
  final _pricingFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();

  // Form data - pre-filled from user collection
  String? _selectedServiceType;
  String _selectedServiceCategory = '';
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _nearestTown = '';

  // Additional worker-specific data
  String _businessName = '';
  String _experienceYears = '';
  String _bio = '';
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
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user data from Firestore to pre-fill form
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          // Pre-fill personal information from user signup
          _firstName = userData['name']?.split(' ')[0] ?? '';
          _lastName = userData['name']?.split(' ').skip(1).join(' ') ?? '';
          _email = userData['email'] ?? '';
          _phone = userData['phone'] ?? '';
          _address = userData['address'] ?? '';
          _nearestTown = userData['nearest_town'] ?? '';

          // Set location data if available
          if (userData['location'] != null) {
            _city = userData['location']['city'] ?? _nearestTown;
          } else {
            _city = _nearestTown;
          }

          _userDataLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    bool isValid = false;

    switch (_currentStep) {
      case 0:
        isValid = _serviceTypeFormKey.currentState?.validate() ?? false;
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

    if (isValid) {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitRegistration();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

      // Generate structured worker ID: HM_0001
      String workerId = await IDGeneratorService.generateWorkerId();

      // Get user document for location data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic>? userLocation = userData['location'];

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
          latitude: userLocation?['latitude'] ?? 0.0,
          longitude: userLocation?['longitude'] ?? 0.0,
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
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .set(worker.toFirestore());

      // Update user document with worker reference
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'service_provider',
        'worker_id': workerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to worker dashboard
      await Future.delayed(Duration(seconds: 1));
      Navigator.pushNamedAndRemoveUntil(
          context, '/worker_dashboard', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    if (!_userDataLoaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title:
            Text('Worker Registration', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFF9800),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
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
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Color(0xFFFF9800)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
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
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Color(0xFFFF9800)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: Color(0xFFFF9800)),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _currentStep < _steps.length - 1
                          ? 'Next'
                          : 'Complete Registration',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Service Type Selection
  Widget _buildServiceTypeStep() {
    final serviceTypes = ServiceTypes.allServiceKeys;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _serviceTypeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Primary Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose the main service you provide',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Service type dropdown
            DropdownButtonFormField<String>(
              value: _selectedServiceType,
              decoration: InputDecoration(
                labelText: 'Service Type *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: serviceTypes.map((serviceKey) {
                return DropdownMenuItem(
                  value: serviceKey,
                  child: Text(ServiceTypes.getServiceName(serviceKey)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServiceType = value;
                  _selectedServiceCategory = ServiceTypes.getCategory(value);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a service type';
                }
                return null;
              },
            ),

            if (_selectedServiceType != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFFF9800).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category: $_selectedServiceCategory',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Step 2: Personal Info (Pre-filled)
  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _personalInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
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
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your basic details are pre-filled from registration',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // First Name (Pre-filled, read-only)
            TextFormField(
              initialValue: _firstName,
              decoration: InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
            SizedBox(height: 16),

            // Last Name (Pre-filled, read-only)
            TextFormField(
              initialValue: _lastName,
              decoration: InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
            SizedBox(height: 16),

            // Email (Pre-filled, read-only)
            TextFormField(
              initialValue: _email,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
            SizedBox(height: 16),

            // Phone (Pre-filled, read-only)
            TextFormField(
              initialValue: _phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Business Info
  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _businessInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextFormField(
              initialValue: _businessName,
              decoration: InputDecoration(
                labelText: 'Business Name (Optional)',
                prefixIcon: Icon(Icons.business_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => _businessName = value,
            ),
          ],
        ),
      ),
    );
  }

  // Step 4: Experience & Skills
  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _experienceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experience & Skills',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            TextFormField(
              initialValue: _experienceYears,
              decoration: InputDecoration(
                labelText: 'Years of Experience *',
                prefixIcon: Icon(Icons.work_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _experienceYears = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your years of experience';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            TextFormField(
              initialValue: _bio,
              decoration: InputDecoration(
                labelText: 'Professional Bio *',
                prefixIcon: Icon(Icons.description_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                hintText: 'Describe your skills and experience',
              ),
              maxLines: 4,
              onChanged: (value) => _bio = value,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your professional bio';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Capabilities
            Text(
              'Capabilities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),

            CheckboxListTile(
              title: Text('Own Tools & Equipment'),
              value: _toolsOwned,
              onChanged: (value) =>
                  setState(() => _toolsOwned = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text('Vehicle Available'),
              value: _vehicleAvailable,
              onChanged: (value) =>
                  setState(() => _vehicleAvailable = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text('Certified Professional'),
              value: _certified,
              onChanged: (value) => setState(() => _certified = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text('Insured'),
              value: _insurance,
              onChanged: (value) => setState(() => _insurance = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // Step 5: Availability
  Widget _buildAvailabilityStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _availabilityFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),

            // Working Hours
            Text(
              'Working Hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _workingHoursStart,
                    decoration: InputDecoration(
                      labelText: 'Start Time',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => _workingHoursStart = value,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _workingHoursEnd,
                    decoration: InputDecoration(
                      labelText: 'End Time',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => _workingHoursEnd = value,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            CheckboxListTile(
              title: Text('Available on Weekends'),
              value: _availableWeekends,
              onChanged: (value) =>
                  setState(() => _availableWeekends = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text('Emergency Service Available'),
              value: _emergencyService,
              onChanged: (value) =>
                  setState(() => _emergencyService = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text('WhatsApp Available'),
              value: _whatsappAvailable,
              onChanged: (value) =>
                  setState(() => _whatsappAvailable = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // Step 6: Pricing
  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _pricingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            TextFormField(
              initialValue: _dailyWage,
              decoration: InputDecoration(
                labelText: 'Daily Wage (LKR) *',
                prefixIcon: Icon(Icons.payments_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyWage = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your daily wage';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _halfDayRate,
              decoration: InputDecoration(
                labelText: 'Half Day Rate (LKR)',
                prefixIcon: Icon(Icons.payments_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _halfDayRate = value,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _minimumCharge,
              decoration: InputDecoration(
                labelText: 'Minimum Charge (LKR)',
                prefixIcon: Icon(Icons.payments_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _minimumCharge = value,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _overtimeRate,
              decoration: InputDecoration(
                labelText: 'Overtime Hourly Rate (LKR)',
                prefixIcon: Icon(Icons.payments_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _overtimeRate = value,
            ),
          ],
        ),
      ),
    );
  }

  // Step 7: Location & Contact
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _locationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location & Contact',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
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
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your address and location are pre-filled from registration',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Address (Pre-filled, read-only)
            TextFormField(
              initialValue: _address,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 2,
              readOnly: true,
            ),
            SizedBox(height: 16),

            // City (Pre-filled from nearest town, read-only)
            TextFormField(
              initialValue: _city,
              decoration: InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
            SizedBox(height: 16),

            // Service Radius
            TextFormField(
              initialValue: _serviceRadius,
              decoration: InputDecoration(
                labelText: 'Service Radius (km) *',
                prefixIcon: Icon(Icons.radar_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g., 10',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _serviceRadius = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your service radius';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Postal Code (Optional)
            TextFormField(
              initialValue: _postalCode,
              decoration: InputDecoration(
                labelText: 'Postal Code (Optional)',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _postalCode = value,
            ),
            SizedBox(height: 16),

            // Website (Optional)
            TextFormField(
              initialValue: _website,
              decoration: InputDecoration(
                labelText: 'Website (Optional)',
                prefixIcon: Icon(Icons.language_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) => _website = value,
            ),
          ],
        ),
      ),
    );
  }
}

  // Continue with remaining steps in Part 2...