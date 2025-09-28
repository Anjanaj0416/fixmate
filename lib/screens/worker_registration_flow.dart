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

  // Form data
  String _selectedServiceType = '';
  String _businessName = '';
  String _experienceYears = '';
  String _bio = '';
  List<String> _selectedSpecializations = [];
  String _workingHoursStart = '08:00';
  String _workingHoursEnd = '17:00';
  bool _availableWeekends = false;
  bool _emergencyService = false;
  bool _toolsOwned = false;
  bool _vehicleAvailable = false;
  bool _certified = false;
  bool _insurance = false;
  List<String> _selectedLanguages = [];
  String _dailyWage = '';
  String _halfDayRate = '';
  String _minimumCharge = '';
  String _overtimeRate = '';
  String _serviceRadius = '';
  String _city = '';
  String _postalCode = '';
  String _website = '';
  bool _whatsappAvailable = false;

  final List<String> _steps = [
    'Service Type',
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

  void _nextStep() {
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

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedServiceType.isNotEmpty;
      case 1:
        return _businessName.isNotEmpty && _experienceYears.isNotEmpty;
      case 2:
        return _bio.isNotEmpty && _selectedSpecializations.isNotEmpty;
      case 3:
        return true; // Always valid, has defaults
      case 4:
        return _dailyWage.isNotEmpty && _minimumCharge.isNotEmpty;
      case 5:
        return _city.isNotEmpty && _serviceRadius.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submitWorkerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw Exception('User document not found');

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Generate worker ID
      String workerId =
          'HM_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Calculate half day rate if not provided
      double dailyWageValue = double.tryParse(_dailyWage) ?? 0.0;
      double halfDayRateValue = _halfDayRate.isNotEmpty
          ? double.tryParse(_halfDayRate) ?? 0.0
          : dailyWageValue * 0.6;

      // Calculate overtime rate if not provided
      double overtimeRateValue = _overtimeRate.isNotEmpty
          ? double.tryParse(_overtimeRate) ?? 0.0
          : dailyWageValue / 8 * 1.5;

      // Create worker model
      WorkerModel worker = WorkerModel(
        workerId: workerId,
        workerName: userData['name'] ?? '',
        firstName: userData['name']?.split(' ')[0] ?? '',
        lastName: userData['name']?.split(' ').skip(1).join(' ') ?? '',
        serviceType: _selectedServiceType,
        serviceCategory: ServiceTypes.getServiceName(_selectedServiceType),
        businessName: _businessName,
        location: WorkerLocation(
          latitude: 6.9271, // Default to Colombo
          longitude: 79.8612,
          city: _city,
          state: 'Sri Lanka',
          postalCode: _postalCode,
        ),
        rating: 0.0,
        experienceYears: int.tryParse(_experienceYears) ?? 0,
        jobsCompleted: 0,
        successRate: 0.0,
        pricing: WorkerPricing(
          dailyWageLkr: dailyWageValue,
          halfDayRateLkr: halfDayRateValue,
          minimumChargeLkr: double.tryParse(_minimumCharge) ?? 0.0,
          emergencyRateMultiplier: _emergencyService ? 1.5 : 1.0,
          overtimeHourlyLkr: overtimeRateValue,
        ),
        availability: WorkerAvailability(
          availableToday: true,
          availableWeekends: _availableWeekends,
          emergencyService: _emergencyService,
          workingHours: '$_workingHoursStart-$_workingHoursEnd',
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
          phoneNumber: userData['phone'] ?? '',
          whatsappAvailable: _whatsappAvailable,
          email: userData['email'] ?? '',
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

      // Update user document with worker reference
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountType': 'service_provider',
        'workerId': workerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Worker profile created successfully!');

      // Navigate to worker dashboard
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
            ),
          ),

          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildServiceTypeStep(),
                _buildBusinessInfoStep(),
                _buildExperienceSkillsStep(),
                _buildAvailabilityStep(),
                _buildPricingStep(),
                _buildLocationContactStep(),
              ],
            ),
          ),

          // Bottom Navigation
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
                  child: ElevatedButton(
                    onPressed:
                        _isCurrentStepValid() && !_isLoading ? _nextStep : null,
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
              final isSelected = _selectedServiceType == service['key'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedServiceType = service['key'];
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFFFF9800).withOpacity(0.1)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected ? Color(0xFFFF9800) : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        service['icon'],
                        style: TextStyle(fontSize: 32),
                      ),
                      SizedBox(height: 8),
                      Text(
                        service['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Color(0xFFFF9800) : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        service['description'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
            'Tell us about your business',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildTextField(
            label: 'Business Name',
            hint: 'e.g., John\'s Electrical Services',
            value: _businessName,
            onChanged: (value) => setState(() => _businessName = value),
            icon: Icons.business,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Years of Experience',
            hint: 'e.g., 5',
            value: _experienceYears,
            onChanged: (value) => setState(() => _experienceYears = value),
            icon: Icons.calendar_today,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Bio/Description',
            hint: 'Tell customers about yourself and your services...',
            value: _bio,
            onChanged: (value) => setState(() => _bio = value),
            icon: Icons.description,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

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
          _buildSwitchTile(
            title: 'Available on Weekends',
            subtitle: 'Work on Saturdays and Sundays',
            value: _availableWeekends,
            onChanged: (value) => setState(() => _availableWeekends = value),
            icon: Icons.weekend,
          ),
          _buildSwitchTile(
            title: 'Emergency Services',
            subtitle: 'Available for urgent repairs',
            value: _emergencyService,
            onChanged: (value) => setState(() => _emergencyService = value),
            icon: Icons.emergency,
          ),
          SizedBox(height: 24),
          Text(
            'Equipment & Capabilities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildSwitchTile(
            title: 'Own Tools',
            subtitle: 'I have my own tools and equipment',
            value: _toolsOwned,
            onChanged: (value) => setState(() => _toolsOwned = value),
            icon: Icons.build,
          ),
          _buildSwitchTile(
            title: 'Vehicle Available',
            subtitle: 'I have transportation',
            value: _vehicleAvailable,
            onChanged: (value) => setState(() => _vehicleAvailable = value),
            icon: Icons.directions_car,
          ),
          _buildSwitchTile(
            title: 'Certified Professional',
            subtitle: 'I have relevant certifications',
            value: _certified,
            onChanged: (value) => setState(() => _certified = value),
            icon: Icons.verified,
          ),
          _buildSwitchTile(
            title: 'Insured',
            subtitle: 'I have professional insurance',
            value: _insurance,
            onChanged: (value) => setState(() => _insurance = value),
            icon: Icons.security,
          ),
        ],
      ),
    );
  }

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
            hint: 'e.g., 5000',
            value: _dailyWage,
            onChanged: (value) => setState(() => _dailyWage = value),
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Half Day Rate (LKR) - Optional',
            hint: 'Leave empty to auto-calculate',
            value: _halfDayRate,
            onChanged: (value) => setState(() => _halfDayRate = value),
            icon: Icons.schedule,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Minimum Charge (LKR)',
            hint: 'e.g., 1000',
            value: _minimumCharge,
            onChanged: (value) => setState(() => _minimumCharge = value),
            icon: Icons.money,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Overtime Hourly Rate (LKR) - Optional',
            hint: 'Leave empty to auto-calculate',
            value: _overtimeRate,
            onChanged: (value) => setState(() => _overtimeRate = value),
            icon: Icons.access_time,
            keyboardType: TextInputType.number,
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
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pricing Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Research market rates in your area\n• Consider your experience level\n• Factor in travel time and costs\n• Emergency services typically cost 1.5x normal rate',
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            'Complete your profile setup',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          _buildDropdownField(
            label: 'City',
            value: _city,
            items: Cities.sriLankanCities,
            onChanged: (value) => setState(() => _city = value ?? ''),
            icon: Icons.location_city,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Postal Code',
            hint: 'e.g., 10400',
            value: _postalCode,
            onChanged: (value) => setState(() => _postalCode = value),
            icon: Icons.local_post_office,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Service Radius (km)',
            hint: 'How far are you willing to travel? e.g., 20',
            value: _serviceRadius,
            onChanged: (value) => setState(() => _serviceRadius = value),
            icon: Icons.radio_button_checked,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          _buildTextField(
            label: 'Website (Optional)',
            hint: 'https://yourwebsite.com',
            value: _website,
            onChanged: (value) => setState(() => _website = value),
            icon: Icons.web,
          ),
          SizedBox(height: 16),
          _buildSwitchTile(
            title: 'WhatsApp Available',
            subtitle: 'Customers can contact you via WhatsApp',
            value: _whatsappAvailable,
            onChanged: (value) => setState(() => _whatsappAvailable = value),
            icon: Icons.chat,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Color(0xFFFF9800)),
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
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
          value: value.isEmpty ? null : value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFFF9800)),
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
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
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
