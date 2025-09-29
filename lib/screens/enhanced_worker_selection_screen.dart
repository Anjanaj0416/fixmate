// lib/screens/enhanced_worker_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../constants/service_constants.dart';

class EnhancedWorkerSelectionScreen extends StatefulWidget {
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

  const EnhancedWorkerSelectionScreen({
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
  _EnhancedWorkerSelectionScreenState createState() =>
      _EnhancedWorkerSelectionScreenState();
}

class _EnhancedWorkerSelectionScreenState
    extends State<EnhancedWorkerSelectionScreen> {
  List<WorkerModel> _allWorkers = [];
  List<WorkerModel> _filteredWorkers = [];
  bool _isLoading = true;
  String _selectedSortBy = 'rating';
  bool _showFilters = false;

  // Filter options
  double _maxDistance = 10.0;
  double _minRating = 3.0;
  RangeValues _experienceRange = RangeValues(0, 20);
  RangeValues _priceRange = RangeValues(5000, 50000);
  String _locationFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      setState(() => _isLoading = true);

      // Search workers by service type/category using the correct method
      List<WorkerModel> workers = await WorkerService.searchWorkers(
        serviceType: widget.serviceType,
        serviceCategory: widget.subService,
        userLat:
            6.9271, // Default Colombo coordinates - replace with actual user location
        userLng: 79.8612,
        maxDistance: 50.0, // Initial load with larger radius
      );

      setState(() {
        _allWorkers = workers;
        _filteredWorkers = workers;
        _isLoading = false;
      });

      _applySortingAndFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load workers: ${e.toString()}');
    }
  }

  void _applySortingAndFilters() {
    List<WorkerModel> filtered = List.from(_allWorkers);

    // Apply filters
    filtered = filtered.where((worker) {
      // Rating filter
      if (worker.rating < _minRating) return false;

      // Experience filter
      if (worker.experienceYears < _experienceRange.start ||
          worker.experienceYears > _experienceRange.end) return false;

      // Price filter (using minimum charge from pricing)
      double basePrice = worker.pricing.minimumChargeLkr;
      if (basePrice < _priceRange.start || basePrice > _priceRange.end)
        return false;

      // Location filter
      if (_locationFilter != 'all' &&
          !worker.location.city
              .toLowerCase()
              .contains(_locationFilter.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_selectedSortBy) {
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price':
        filtered.sort((a, b) =>
            a.pricing.minimumChargeLkr.compareTo(b.pricing.minimumChargeLkr));
        break;
      case 'experience':
        filtered.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
        break;
      case 'distance':
        // For demo, using random distance. In production, calculate actual distance
        filtered.shuffle();
        break;
      case 'jobs':
        filtered.sort((a, b) => b.jobsCompleted.compareTo(a.jobsCompleted));
        break;
    }

    setState(() {
      _filteredWorkers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Select ${widget.serviceType.toUpperCase()} Professional'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : Column(
              children: [
                _buildSortingOptions(),
                if (_showFilters) _buildFilterOptions(),
                _buildResultsHeader(),
                Expanded(child: _buildWorkersList()),
              ],
            ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text('Finding the best professionals for you...'),
        ],
      ),
    );
  }

  Widget _buildSortingOptions() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('Rating', 'rating', Icons.star),
                SizedBox(width: 8),
                _buildSortChip('Price', 'price', Icons.attach_money),
                SizedBox(width: 8),
                _buildSortChip('Experience', 'experience', Icons.work),
                SizedBox(width: 8),
                _buildSortChip('Distance', 'distance', Icons.location_on),
                SizedBox(width: 8),
                _buildSortChip(
                    'Jobs Completed', 'jobs', Icons.assignment_turned_in),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    bool isSelected = _selectedSortBy == value;
    return FilterChip(
      avatar: Icon(icon,
          size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSortBy = value);
        _applySortingAndFilters();
      },
      selectedColor: Colors.orange,
      backgroundColor: Colors.grey[100],
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),

          // Rating filter
          Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
          Slider(
            value: _minRating,
            min: 1.0,
            max: 5.0,
            divisions: 8,
            onChanged: (value) {
              setState(() => _minRating = value);
              _applySortingAndFilters();
            },
            activeColor: Colors.orange,
          ),

          // Experience filter
          Text(
              'Experience: ${_experienceRange.start.round()} - ${_experienceRange.end.round()} years'),
          RangeSlider(
            values: _experienceRange,
            min: 0,
            max: 20,
            divisions: 20,
            onChanged: (values) {
              setState(() => _experienceRange = values);
              _applySortingAndFilters();
            },
            activeColor: Colors.orange,
          ),

          // Price filter
          Text(
              'Price Range: LKR ${_priceRange.start.round()} - LKR ${_priceRange.end.round()}'),
          RangeSlider(
            values: _priceRange,
            min: 1000,
            max: 100000,
            divisions: 50,
            onChanged: (values) {
              setState(() => _priceRange = values);
              _applySortingAndFilters();
            },
            activeColor: Colors.orange,
          ),

          // Location filter
          Row(
            children: [
              Text('Location: '),
              SizedBox(width: 8),
              DropdownButton<String>(
                value: _locationFilter,
                onChanged: (value) {
                  setState(() => _locationFilter = value!);
                  _applySortingAndFilters();
                },
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All Areas')),
                  DropdownMenuItem(value: 'colombo', child: Text('Colombo')),
                  DropdownMenuItem(value: 'gampaha', child: Text('Gampaha')),
                  DropdownMenuItem(value: 'kalutara', child: Text('Kalutara')),
                  DropdownMenuItem(value: 'kandy', child: Text('Kandy')),
                  DropdownMenuItem(value: 'galle', child: Text('Galle')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredWorkers.length} professionals found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          if (_filteredWorkers.isNotEmpty)
            Text(
              'Tap to select',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkersList() {
    if (_filteredWorkers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        return _buildWorkerCard(_filteredWorkers[index]);
      },
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
            'No professionals found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _minRating = 1.0;
                _experienceRange = RangeValues(0, 20);
                _priceRange = RangeValues(1000, 100000);
                _locationFilter = 'all';
              });
              _applySortingAndFilters();
            },
            child: Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _selectWorker(worker),
        borderRadius: BorderRadius.circular(12),
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
                    backgroundColor: Colors.orange[100],
                    child: Text(
                      worker.firstName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
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
                              '${worker.rating.toStringAsFixed(1)}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.location_on,
                                color: Colors.grey, size: 16),
                            SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${worker.location.city}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (worker.verified)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16),

              // Worker stats
              Row(
                children: [
                  _buildStatItem(Icons.work_outline,
                      '${worker.experienceYears} years', 'Experience'),
                  SizedBox(width: 16),
                  _buildStatItem(Icons.assignment_turned_in,
                      '${worker.jobsCompleted}', 'Jobs Done'),
                  SizedBox(width: 16),
                  _buildStatItem(Icons.trending_up,
                      '${worker.successRate.toStringAsFixed(0)}%', 'Success'),
                ],
              ),

              SizedBox(height: 16),

              // Skills/Specializations
              if (worker.profile.specializations.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: worker.profile.specializations.take(3).map((skill) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              SizedBox(height: 16),

              // Price and availability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting from',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _selectWorker(worker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Select',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectWorker(WorkerModel worker) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to select:'),
            SizedBox(height: 12),
            Text(
              worker.workerName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(worker.businessName),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text('${worker.rating.toStringAsFixed(1)} rating'),
                SizedBox(width: 16),
                Text(
                    'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}'),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'for your ${widget.serviceType} service?',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
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
              CircularProgressIndicator(color: Colors.orange),
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
        customerId: customerData['customer_id'] ?? user.uid,
        customerName: customerData['customer_name'] ??
            customerData['first_name'] + ' ' + customerData['last_name'],
        customerPhone: customerData['phone_number'] ?? '',
        customerEmail: customerData['email'] ?? user.email ?? '',
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

      // Show success dialog and navigate
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your booking has been created successfully.'),
              SizedBox(height: 8),
              Text('Booking ID: $bookingId'),
              SizedBox(height: 8),
              Text('Worker: ${worker.workerName}'),
              SizedBox(height: 16),
              Text(
                'The service provider will contact you shortly to confirm the appointment.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/customer_home',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
