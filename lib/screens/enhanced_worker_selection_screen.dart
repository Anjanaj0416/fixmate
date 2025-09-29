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

  // FIXED: Initialize filters to show ALL workers
  double _maxDistance = 100.0;
  double _minRating = 0.0; // Changed from 3.0 to 0.0
  RangeValues _experienceRange = RangeValues(0, 20);
  RangeValues _priceRange = RangeValues(0, 100000);
  String _locationFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      print('DEBUG: Starting to load workers...');
      print('DEBUG: Service Type: ${widget.serviceType}');
      print('DEBUG: Sub Service: ${widget.subService}');

      setState(() => _isLoading = true);

      // First, try to get ALL workers to check if there are any in the database
      QuerySnapshot allWorkersSnapshot =
          await FirebaseFirestore.instance.collection('workers').get();

      print(
          'DEBUG: Total workers in database: ${allWorkersSnapshot.docs.length}');

      if (allWorkersSnapshot.docs.isEmpty) {
        setState(() {
          _allWorkers = [];
          _filteredWorkers = [];
          _isLoading = false;
        });
        _showErrorSnackBar('No workers found in the database.');
        return;
      }

      // Print sample worker data for debugging
      if (allWorkersSnapshot.docs.isNotEmpty) {
        var sampleDoc = allWorkersSnapshot.docs.first;
        print('DEBUG: Sample worker document ID: ${sampleDoc.id}');
        print(
            'DEBUG: Sample worker data keys: ${(sampleDoc.data() as Map<String, dynamic>).keys.toList()}');
      }

      // Try the filtered search
      List<WorkerModel> workers = await WorkerService.searchWorkers(
        serviceType: widget.serviceType,
        serviceCategory: widget.subService,
        userLat: 6.9271,
        userLng: 79.8612,
        maxDistance: 100.0,
      );

      print('DEBUG: Filtered search returned ${workers.length} workers');

      // If no workers found with filters, try without filters
      if (workers.isEmpty) {
        print(
            'DEBUG: No workers found with filters, trying without filters...');

        // Get all workers and convert them
        List<WorkerModel> allWorkers = [];
        for (var doc in allWorkersSnapshot.docs) {
          try {
            WorkerModel worker = WorkerModel.fromFirestore(doc);
            allWorkers.add(worker);
            print(
                'DEBUG: Parsed worker: ${worker.workerName} - Service: ${worker.serviceType}');
          } catch (e) {
            print('DEBUG: Error parsing worker ${doc.id}: $e');
          }
        }

        // Filter manually by service type
        workers = allWorkers.where((worker) {
          bool matches = worker.serviceType.toLowerCase() ==
              widget.serviceType.toLowerCase();
          print(
              'DEBUG: Worker ${worker.workerName} service ${worker.serviceType} matches ${widget.serviceType}: $matches');
          return matches;
        }).toList();

        print('DEBUG: Manual filtering found ${workers.length} workers');
      }

      // IMPORTANT: Update state with ALL workers - don't apply filters yet
      setState(() {
        _allWorkers = workers;
        _filteredWorkers = workers; // Show ALL workers initially
        _isLoading = false;
      });

      print('DEBUG: Successfully loaded ${workers.length} workers');
      print('DEBUG: _allWorkers.length = ${_allWorkers.length}');
      print('DEBUG: _filteredWorkers.length = ${_filteredWorkers.length}');

      if (workers.isEmpty) {
        _showErrorSnackBar(
            'No workers available for ${widget.serviceType.replaceAll('_', ' ')} service.');
      }
    } catch (e) {
      print('DEBUG: Error in _loadWorkers: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load workers: ${e.toString()}');
    }
  }

  void _applySortingAndFilters() {
    print('DEBUG: Applying sorting and filters...');
    print('DEBUG: Starting with ${_allWorkers.length} workers');
    print('DEBUG: Min rating filter: $_minRating');

    List<WorkerModel> filtered = List.from(_allWorkers);

    // Apply filters
    filtered = filtered.where((worker) {
      // Rating filter - ONLY filter if minRating > 0
      if (_minRating > 0 && worker.rating < _minRating) {
        print(
            'DEBUG: Filtering out ${worker.workerName} - rating ${worker.rating} < $_minRating');
        return false;
      }

      // Experience filter
      if (worker.experienceYears < _experienceRange.start ||
          worker.experienceYears > _experienceRange.end) {
        print(
            'DEBUG: Filtering out ${worker.workerName} - experience ${worker.experienceYears}');
        return false;
      }

      // Price filter
      double workerPrice = worker.pricing.minimumChargeLkr;
      if (workerPrice < _priceRange.start || workerPrice > _priceRange.end) {
        print('DEBUG: Filtering out ${worker.workerName} - price $workerPrice');
        return false;
      }

      // Location filter
      if (_locationFilter != 'all' &&
          worker.location.city.toLowerCase() != _locationFilter.toLowerCase()) {
        print(
            'DEBUG: Filtering out ${worker.workerName} - location ${worker.location.city}');
        return false;
      }

      print('DEBUG: Worker ${worker.workerName} passed all filters');
      return true;
    }).toList();

    print('DEBUG: After filters: ${filtered.length} workers remain');

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
        // Distance sorting would need user location
        break;
      case 'jobs':
        filtered.sort((a, b) => b.jobsCompleted.compareTo(a.jobsCompleted));
        break;
    }

    setState(() {
      _filteredWorkers = filtered;
    });

    print('DEBUG: Final _filteredWorkers.length = ${_filteredWorkers.length}');
  }

  void _clearAllFilters() {
    setState(() {
      _maxDistance = 100.0;
      _minRating = 0.0;
      _experienceRange = RangeValues(0, 20);
      _priceRange = RangeValues(0, 100000);
      _locationFilter = 'all';
      _filteredWorkers = List.from(_allWorkers);
    });
    print('DEBUG: Filters cleared, showing ${_filteredWorkers.length} workers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Select ${widget.serviceType.replaceAll('_', ' ').toUpperCase()} Professional'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Sort and Filter Bar
          _buildSortAndFilterBar(),

          // Worker Count
          if (!_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_filteredWorkers.length} professional${_filteredWorkers.length != 1 ? 's' : ''} found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Worker List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.orange))
                : _buildWorkerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort By Row
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Rating', 'rating', Icons.star),
                      _buildSortChip('Price', 'price', Icons.attach_money),
                      _buildSortChip('Experience', 'experience', Icons.work),
                      _buildSortChip(
                          'Jobs Completed', 'jobs', Icons.check_circle),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                  color: _showFilters ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
            ],
          ),

          // Filters Panel
          if (_showFilters) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            _buildFiltersPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    bool isSelected = _selectedSortBy == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSortBy = value;
          });
          _applySortingAndFilters();
        },
        selectedColor: Colors.orange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed: _clearAllFilters,
              child: Text('Clear All'),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Minimum Rating
        Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: Colors.orange,
          onChanged: (value) {
            setState(() {
              _minRating = value;
            });
          },
          onChangeEnd: (value) {
            _applySortingAndFilters();
          },
        ),

        SizedBox(height: 8),

        // Experience Range
        Text(
            'Experience: ${_experienceRange.start.round()} - ${_experienceRange.end.round()} years'),
        RangeSlider(
          values: _experienceRange,
          min: 0,
          max: 20,
          divisions: 20,
          activeColor: Colors.orange,
          onChanged: (values) {
            setState(() {
              _experienceRange = values;
            });
          },
          onChangeEnd: (values) {
            _applySortingAndFilters();
          },
        ),

        SizedBox(height: 8),

        // Price Range
        Text(
            'Price Range: LKR ${_priceRange.start.round()} - LKR ${_priceRange.end.round()}'),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 100000,
          divisions: 100,
          activeColor: Colors.orange,
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
          onChangeEnd: (values) {
            _applySortingAndFilters();
          },
        ),

        SizedBox(height: 8),

        // Apply Filters Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _applySortingAndFilters();
              setState(() {
                _showFilters = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('Apply Filters', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerList() {
    print('DEBUG: Building worker list...');
    print('DEBUG: _allWorkers.length = ${_allWorkers.length}');
    print('DEBUG: _filteredWorkers.length = ${_filteredWorkers.length}');

    // Check if we have any workers at all
    if (_allWorkers.isEmpty) {
      return _buildNoWorkersFound();
    }

    // Check if filtered list is empty but we have workers
    if (_filteredWorkers.isEmpty && _allWorkers.isNotEmpty) {
      return _buildNoWorkersMatchingFilters();
    }

    // Display the workers
    return RefreshIndicator(
      onRefresh: _loadWorkers,
      color: Colors.orange,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredWorkers.length,
        itemBuilder: (context, index) {
          print(
              'DEBUG: Building worker card for ${_filteredWorkers[index].workerName}');
          return _buildWorkerCard(_filteredWorkers[index]);
        },
      ),
    );
  }

  Widget _buildNoWorkersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Professionals Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No workers found for ${widget.serviceType.replaceAll('_', ' ')} service.\nPlease try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadWorkers,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkersMatchingFilters() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Professionals Match Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try adjusting your filters or search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearAllFilters,
            icon: Icon(Icons.clear_all),
            label: Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange[100],
                  child: Text(
                    worker.workerName.isNotEmpty
                        ? worker.workerName[0].toUpperCase()
                        : 'W',
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
                      if (worker.verified)
                        Row(
                          children: [
                            Icon(Icons.verified, size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.star,
                  worker.rating > 0 ? worker.rating.toStringAsFixed(1) : 'New',
                  'Rating',
                ),
                _buildStatItem(
                  Icons.work,
                  '${worker.experienceYears}',
                  'Years Exp',
                ),
                _buildStatItem(
                  Icons.check_circle,
                  '${worker.jobsCompleted}',
                  'Jobs',
                ),
              ],
            ),

            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),

            // Pricing and Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum Charge',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          worker.location.city,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (worker.availability.availableToday)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Available Today',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Select Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectWorker(worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Select Worker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
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
                Text(worker.rating > 0
                    ? '${worker.rating.toStringAsFixed(1)} rating'
                    : 'New worker'),
                SizedBox(width: 16),
                Text(
                    'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}'),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'for your ${widget.serviceType.replaceAll('_', ' ')} service?',
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
            '${customerData['first_name']} ${customerData['last_name']}',
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
