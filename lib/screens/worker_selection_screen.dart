// lib/screens/worker_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../constants/service_constants.dart';

class WorkerSelectionScreen extends StatefulWidget {
  final String serviceType;
  final String subService;
  final String issueType;
  final String problemDescription;
  final List<String> problemImageUrls;
  final String location;
  final String address;
  final String urgency;
  final String budgetRange;
  final DateTime scheduledDate;
  final String scheduledTime;

  const WorkerSelectionScreen({
    Key? key,
    required this.serviceType,
    required this.subService,
    required this.issueType,
    required this.problemDescription,
    required this.problemImageUrls,
    required this.location,
    required this.address,
    required this.urgency,
    required this.budgetRange,
    required this.scheduledDate,
    required this.scheduledTime,
  }) : super(key: key);

  @override
  _WorkerSelectionScreenState createState() => _WorkerSelectionScreenState();
}

class _WorkerSelectionScreenState extends State<WorkerSelectionScreen> {
  List<WorkerModel> _workers = [];
  List<WorkerModel> _filteredWorkers = [];
  bool _isLoading = true;
  String _selectedSortBy = 'rating';
  double _maxDistance = 10.0;
  double _minRating = 3.0;
  String _availabilityFilter = 'all';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      setState(() => _isLoading = true);

      // For demo purposes, using Colombo coordinates
      // In production, get user's actual location
      double latitude = 6.9271;
      double longitude = 79.8612;

      List<WorkerModel> workers = await WorkerService.getWorkersByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: _maxDistance,
        serviceType: widget.serviceType,
      );

      setState(() {
        _workers = workers;
        _filteredWorkers = workers;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load workers: ${e.toString()}');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredWorkers = _workers.where((worker) {
        // Rating filter
        if (worker.rating < _minRating) return false;

        // Availability filter
        if (_availabilityFilter == 'today' &&
            !worker.availability.availableToday) {
          return false;
        }
        if (_availabilityFilter == 'emergency' &&
            !worker.availability.emergencyService) {
          return false;
        }

        return true;
      }).toList();

      // Sort workers
      _filteredWorkers.sort((a, b) {
        switch (_selectedSortBy) {
          case 'rating':
            return b.rating.compareTo(a.rating);
          case 'price':
            return a.pricing.dailyWageLkr.compareTo(b.pricing.dailyWageLkr);
          case 'experience':
            return b.experienceYears.compareTo(a.experienceYears);
          case 'jobs':
            return b.jobsCompleted.compareTo(a.jobsCompleted);
          default:
            return b.rating.compareTo(a.rating);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Choose ${widget.serviceType.replaceAll('_', ' ').toUpperCase()} Professional',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          _buildSortingBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredWorkers.isEmpty
                    ? _buildEmptyState()
                    : _buildWorkersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),

          // Distance filter
          Text('Maximum Distance: ${_maxDistance.toInt()} km'),
          Slider(
            value: _maxDistance,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            onChanged: (value) {
              setState(() => _maxDistance = value);
              _loadWorkers();
            },
          ),

          // Rating filter
          Text('Minimum Rating: ${_minRating.toInt()} stars'),
          Slider(
            value: _minRating,
            min: 1.0,
            max: 5.0,
            divisions: 4,
            onChanged: (value) {
              setState(() => _minRating = value);
              _applyFilters();
            },
          ),

          // Availability filter
          Text('Availability'),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('All', 'all'),
              _buildFilterChip('Available Today', 'today'),
              _buildFilterChip('Emergency Service', 'emergency'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _availabilityFilter == value,
      onSelected: (selected) {
        setState(() => _availabilityFilter = value);
        _applyFilters();
      },
    );
  }

  Widget _buildSortingBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Rating', 'rating'),
                  SizedBox(width: 8),
                  _buildSortChip('Price', 'price'),
                  SizedBox(width: 8),
                  _buildSortChip('Experience', 'experience'),
                  SizedBox(width: 8),
                  _buildSortChip('Jobs Completed', 'jobs'),
                ],
              ),
            ),
          ),
          Text('${_filteredWorkers.length} found'),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedSortBy == value,
      onSelected: (selected) {
        setState(() => _selectedSortBy = value);
        _applyFilters();
      },
    );
  }

  Widget _buildWorkersList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        return _buildWorkerCard(_filteredWorkers[index]);
      },
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    worker.firstName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.workerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        worker.businessName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${worker.rating.toStringAsFixed(1)} (${worker.jobsCompleted} jobs)',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (worker.availability.availableToday)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Available',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16),

            // Worker details
            Row(
              children: [
                _buildDetailChip(Icons.work, '${worker.experienceYears} years'),
                SizedBox(width: 8),
                _buildDetailChip(Icons.location_on, '${worker.location.city}'),
                SizedBox(width: 8),
                if (worker.capabilities.toolsOwned)
                  _buildDetailChip(Icons.build, 'Own tools'),
              ],
            ),

            SizedBox(height: 12),

            // Pricing
            Row(
              children: [
                Text(
                  'From LKR ${worker.pricing.minimumChargeLkr.toInt()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                Spacer(),
                Text(
                  'Daily: LKR ${worker.pricing.dailyWageLkr.toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewWorkerProfile(worker),
                    child: Text('View Profile'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectWorker(worker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(
                      'Select Worker',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No workers found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or expanding the search radius',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _maxDistance = 25.0;
                _minRating = 1.0;
                _availabilityFilter = 'all';
              });
              _loadWorkers();
            },
            child: Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  void _viewWorkerProfile(WorkerModel worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) =>
            _buildWorkerProfileSheet(worker, scrollController),
      ),
    );
  }

  Widget _buildWorkerProfileSheet(
      WorkerModel worker, ScrollController scrollController) {
    return Container(
      padding: EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Worker info
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue[100],
                child: Text(
                  worker.firstName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.workerName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      worker.businessName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 4),
                        Text(
                          '${worker.rating.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' (${worker.jobsCompleted} jobs completed)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Experience and capabilities
          _buildProfileSection('Experience & Skills', [
            _buildProfileItem('Experience', '${worker.experienceYears} years'),
            _buildProfileItem('Success Rate', '${worker.successRate.toInt()}%'),
            _buildProfileItem('Jobs Completed', '${worker.jobsCompleted}'),
            _buildProfileItem('Response Time',
                '${worker.availability.responseTimeMinutes} minutes'),
          ]),

          SizedBox(height: 16),

          // Capabilities
          _buildProfileSection('Capabilities', [
            if (worker.capabilities.toolsOwned)
              _buildProfileItem('Tools', 'Owns professional tools'),
            if (worker.capabilities.vehicleAvailable)
              _buildProfileItem('Transport', 'Vehicle available'),
            if (worker.capabilities.certified)
              _buildProfileItem('Certification', 'Certified professional'),
            if (worker.capabilities.insurance)
              _buildProfileItem('Insurance', 'Insured work'),
          ]),

          SizedBox(height: 16),

          // Pricing
          _buildProfileSection('Pricing', [
            _buildProfileItem('Minimum Charge',
                'LKR ${worker.pricing.minimumChargeLkr.toInt()}'),
            _buildProfileItem(
                'Daily Rate', 'LKR ${worker.pricing.dailyWageLkr.toInt()}'),
            _buildProfileItem('Half Day Rate',
                'LKR ${worker.pricing.halfDayRateLkr.toInt()}'),
            if (worker.pricing.overtimeHourlyLkr > 0)
              _buildProfileItem('Overtime Rate',
                  'LKR ${worker.pricing.overtimeHourlyLkr.toInt()}/hour'),
          ]),

          SizedBox(height: 16),

          // Availability
          _buildProfileSection('Availability', [
            _buildProfileItem(
                'Working Hours', worker.availability.workingHours),
            _buildProfileItem('Available Today',
                worker.availability.availableToday ? 'Yes' : 'No'),
            _buildProfileItem('Weekend Service',
                worker.availability.availableWeekends ? 'Yes' : 'No'),
            _buildProfileItem('Emergency Service',
                worker.availability.emergencyService ? 'Yes' : 'No'),
          ]),

          SizedBox(height: 24),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _selectWorker(worker);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Select This Worker',
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

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Column(
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
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectWorker(WorkerModel worker) async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Selection'),
        content: Text(
          'Are you sure you want to select ${worker.workerName} for your ${widget.serviceType} service?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _createBooking(worker);
    }
  }

  Future<void> _createBooking(WorkerModel worker) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating booking...'),
            ],
          ),
        ),
      );

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get customer data
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) throw Exception('Customer profile not found');

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;

      // Create booking using BookingService
      String bookingId = await BookingService.createBooking(
        customerId: customerData['customer_id'],
        customerName: customerData['customer_name'],
        customerPhone: customerData['phone_number'],
        customerEmail: customerData['email'],
        workerId: worker.workerId!,
        workerName: worker.workerName,
        workerPhone: worker.contact.phoneNumber,
        serviceType: widget.serviceType,
        subService: widget.subService,
        issueType: widget.issueType,
        problemDescription: widget.problemDescription,
        problemImageUrls: widget.problemImageUrls,
        location: widget.location,
        address: widget.address,
        urgency: widget.urgency,
        budgetRange: widget.budgetRange,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Booking Created!'),
            ],
          ),
          content: Text(
            'Your booking request has been sent to ${worker.workerName}. You will be notified when they respond.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
                Navigator.pop(context); // Go back to service flow
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      _showErrorSnackBar('Failed to create booking: ${e.toString()}');
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
}
