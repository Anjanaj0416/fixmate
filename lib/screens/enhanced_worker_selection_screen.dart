// lib/screens/enhanced_worker_selection_screen.dart
// MODIFIED VERSION - Added Location Filter Dropdown

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../constants/service_constants.dart';
import 'customer_bookings_screen.dart';
import 'customer_dashboard.dart';
import '../services/quote_service.dart';

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

  // Initialize filters to show ALL workers
  double _maxDistance = 100.0;
  double _minRating = 0.0;
  RangeValues _experienceRange = RangeValues(0, 20);
  RangeValues _priceRange = RangeValues(0, 100000);

  // ✅ NEW: Location filter with default value 'all'
  String _selectedLocationFilter = 'all';
  List<String> _availableLocations = ['all']; // Will be populated from workers

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

      // ✅ NEW: Extract unique locations from workers
      Set<String> locationSet = {};
      for (var worker in workers) {
        if (worker.location.city.isNotEmpty) {
          locationSet.add(worker.location.city);
        }
      }
      List<String> locations = locationSet.toList()..sort();

      // Update state with ALL workers and available locations
      setState(() {
        _allWorkers = workers;
        _filteredWorkers = workers; // Show ALL workers initially
        _availableLocations = [
          'all',
          ...locations
        ]; // Add 'all' as first option
        _isLoading = false;
      });

      print('DEBUG: Successfully loaded ${workers.length} workers');
      print('DEBUG: Available locations: $_availableLocations');
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
    print('DEBUG: Selected location filter: $_selectedLocationFilter');

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

      // ✅ MODIFIED: Location filter - only filter if not 'all'
      if (_selectedLocationFilter != 'all' &&
          worker.location.city.toLowerCase() !=
              _selectedLocationFilter.toLowerCase()) {
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
      _selectedLocationFilter = 'all'; // ✅ MODIFIED: Reset location to 'all'
      _filteredWorkers = List.from(_allWorkers);
    });
    print('DEBUG: Filters cleared, showing ${_filteredWorkers.length} workers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Select ${widget.serviceType.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(
                  RegExp(r'^[a-z]'),
                  (match) => match.group(0)!.toUpperCase(),
                )} Professional'),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // White at top
              Color(0xFFE3F2FD), // Soft light blue at bottom
            ],
          ),
        ),
        child: Column(
          children: [
            // Sort and Filter Bar
            _buildSortAndFilterBar(),

            // Location Filter Dropdown
            _buildLocationFilterBar(),

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
                  ? Center(child: CircularProgressIndicator(color: Colors.blue))
                  : _filteredWorkers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadWorkers,
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _filteredWorkers.length,
                            itemBuilder: (context, index) {
                              return _buildWorkerCard(_filteredWorkers[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Location Filter Bar Widget
  Widget _buildLocationFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[700], size: 20),
          SizedBox(width: 8),
          Text(
            'Location:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocationFilter,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  items: _availableLocations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(
                        location == 'all' ? 'All Locations' : location,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: location == _selectedLocationFilter
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLocationFilter = newValue;
                      });
                      _applySortingAndFilters();
                      print('DEBUG: Location filter changed to: $newValue');
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortAndFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Sort Dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSortBy,
                      isExpanded: true,
                      icon: Icon(Icons.sort, size: 20),
                      items: [
                        DropdownMenuItem(
                            value: 'rating', child: Text('Sort: Rating')),
                        DropdownMenuItem(
                            value: 'price', child: Text('Sort: Price')),
                        DropdownMenuItem(
                            value: 'experience',
                            child: Text('Sort: Experience')),
                        DropdownMenuItem(
                            value: 'jobs', child: Text('Sort: Jobs Completed')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedSortBy = value!);
                        _applySortingAndFilters();
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Filter Button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showFilters = !_showFilters);
                },
                icon: Icon(Icons.filter_list, size: 18),
                label: Text('Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _showFilters ? Colors.blue : Colors.grey[200],
                  foregroundColor:
                      _showFilters ? Colors.white : Colors.grey[800],
                  elevation: 0,
                ),
              ),
            ],
          ),

          // Filter Panel
          if (_showFilters) ...[
            SizedBox(height: 16),
            _buildFilterPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Filter
          Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}⭐',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: Colors.blue,
            onChanged: (value) {
              setState(() => _minRating = value);
              _applySortingAndFilters();
            },
          ),
          SizedBox(height: 12),

          // Experience Filter
          Text(
              'Experience: ${_experienceRange.start.round()}-${_experienceRange.end.round()} years',
              style: TextStyle(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _experienceRange,
            min: 0,
            max: 20,
            divisions: 20,
            activeColor: Colors.blue,
            onChanged: (values) {
              setState(() => _experienceRange = values);
              _applySortingAndFilters();
            },
          ),
          SizedBox(height: 12),

          // Price Filter
          Text(
              'Price Range: LKR ${_priceRange.start.round()}-${_priceRange.end.round()}',
              style: TextStyle(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 100000,
            divisions: 100,
            activeColor: Colors.blue,
            onChanged: (values) {
              setState(() => _priceRange = values);
              _applySortingAndFilters();
            },
          ),
          SizedBox(height: 16),

          // Clear Filters Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearAllFilters,
              icon: Icon(Icons.clear_all),
              label: Text('Clear All Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No workers found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or changing the location',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: Icon(Icons.refresh),
              label: Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: worker.profilePictureUrl != null &&
                          worker.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(worker.profilePictureUrl!)
                      : null,
                  child: worker.profilePictureUrl == null ||
                          worker.profilePictureUrl!.isEmpty
                      ? Icon(Icons.person, size: 30, color: Colors.blue)
                      : null,
                ),
                SizedBox(width: 12),
                // Worker Info
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
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            worker.rating > 0
                                ? '${worker.rating.toStringAsFixed(1)}'
                                : 'New',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.work, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('${worker.jobsCompleted} jobs'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(height: 24),

            // Location
            Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${worker.location.city}, ${worker.location.state}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Experience
            Row(
              children: [
                Icon(Icons.work_history, size: 18, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '${worker.experienceYears} years experience',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Pricing
            Row(
              children: [
                Icon(Icons.payments, size: 18, color: Colors.green[700]),
                SizedBox(width: 8),
                Text(
                  'From LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWorkerDetailsDialog(worker),
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewsDialog(worker),
                    icon: Icon(Icons.rate_review, size: 18),
                    label: Text('Reviews'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Select Worker Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectWorker(worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Select Worker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerDetailsDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orange[100],
                        backgroundImage: worker.profilePictureUrl != null &&
                                worker.profilePictureUrl!.isNotEmpty
                            ? NetworkImage(worker.profilePictureUrl!)
                            : null,
                        child: worker.profilePictureUrl == null ||
                                worker.profilePictureUrl!.isEmpty
                            ? Icon(Icons.person, size: 40, color: Colors.orange)
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.workerName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              worker.businessName,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Bio
                  if (worker.profile.bio.isNotEmpty) ...[
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      worker.profile.bio,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Contact Info
                  Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(Icons.phone, worker.contact.phoneNumber),
                  _buildDetailRow(Icons.email, worker.contact.email),
                  if (worker.contact.whatsappAvailable)
                    _buildDetailRow(Icons.message, 'WhatsApp Available'),
                  SizedBox(height: 16),

                  // Location
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(Icons.location_city,
                      '${worker.location.city}, ${worker.location.state}'),
                  _buildDetailRow(Icons.map,
                      'Service Radius: ${worker.profile.serviceRadiusKm} km'),
                  SizedBox(height: 16),

                  // Specializations
                  if (worker.profile.specializations.isNotEmpty) ...[
                    Text(
                      'Specializations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: worker.profile.specializations.map((spec) {
                        return Chip(
                          label: Text(spec, style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(color: Colors.blue[700]),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Capabilities
                  Text(
                    'Capabilities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (worker.capabilities.toolsOwned)
                    _buildCapabilityChip('Owns Tools', Icons.build),
                  if (worker.capabilities.vehicleAvailable)
                    _buildCapabilityChip(
                        'Vehicle Available', Icons.directions_car),
                  if (worker.capabilities.certified)
                    _buildCapabilityChip('Certified', Icons.verified),
                  if (worker.capabilities.insurance)
                    _buildCapabilityChip('Insured', Icons.shield),
                  SizedBox(height: 16),

                  // Pricing
                  Text(
                    'Pricing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildPriceRow('Minimum Charge',
                      'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}'),
                  _buildPriceRow('Daily Wage',
                      'LKR ${worker.pricing.dailyWageLkr.toStringAsFixed(0)}'),
                  _buildPriceRow('Half Day',
                      'LKR ${worker.pricing.halfDayRateLkr.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReviewsDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${worker.workerName} - Reviews'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 32),
                  SizedBox(width: 8),
                  Text(
                    worker.rating > 0
                        ? worker.rating.toStringAsFixed(1)
                        : 'New',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Text('/ 5.0', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Based on ${worker.jobsCompleted} completed jobs',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              if (worker.rating == 0)
                Text(
                  'No reviews yet. This worker is new to the platform.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green[700]),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleBookWorker(WorkerModel worker) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar('Please login to request a quote');
      return;
    }

    final confirmed = await _showQuoteConfirmationDialog(worker);
    if (!confirmed) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating quote request...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print('\n========== QUOTE CREATION START ==========');

      // Get customer data
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) {
        throw Exception('Customer profile not found');
      }

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;
      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // Get worker_id from WorkerModel
      String? nullableWorkerId = worker.workerId;

      if (nullableWorkerId == null || nullableWorkerId.isEmpty) {
        throw Exception('Worker ID is missing');
      }

      String workerId = nullableWorkerId;

      print('📋 Quote details:');
      print('   Customer ID: $customerId');
      print('   Worker ID: $workerId');
      print('   Service: ${widget.serviceType}');

      // Verify workerId format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX format)');
      }

      // Create quote using QuoteService
      String quoteId = await QuoteService.createQuote(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
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

      print('✅ Quote created successfully!');
      print('   Quote ID: $quoteId');

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 32),
              SizedBox(width: 12),
              Text('Quote Request Sent!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your quote request has been sent successfully.'),
              SizedBox(height: 12),
              Text('Quote ID: $quoteId',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Worker: ${worker.workerName}'),
              Text('Service: ${widget.serviceType.replaceAll('_', ' ')}'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Next Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. The worker will review your quote',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                    Text(
                      '2. You\'ll get notified when they respond',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                    Text(
                      '3. Check the Quotes tab in Bookings',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to Customer Dashboard with Bookings tab (Quotes)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDashboard(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('View Quotes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      print('✅ Quote dialog shown');
      print('========== QUOTE CREATION END ==========\n');
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      print('❌ Error creating quote: $e');
      print('========== QUOTE CREATION END ==========\n');
      _showErrorSnackBar('Failed to create quote: ${e.toString()}');
    }
  }

// Add this new confirmation dialog method:
  Future<bool> _showQuoteConfirmationDialog(WorkerModel worker) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Request Quote from ${worker.workerName}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to send a quote request to:'),
                SizedBox(height: 12),
                Text('Worker: ${worker.workerName}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Service: ${widget.serviceType.replaceAll('_', ' ')}'),
                Text('Rating: ${worker.rating} ⭐'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'The worker will review your request and send you a quote with pricing.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                  ),
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
                child: Text('Send Quote Request',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // MODIFIED: Changed booking flow to quote flow
// Only modify the _selectWorker method - replace the existing method with this:

  Future<void> _selectWorker(WorkerModel worker) async {
    // Show confirmation dialog for QUOTE REQUEST (not booking)
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Quote Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to send a quote request to:'),
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
            SizedBox(height: 12),
            // Information box about quote process
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Quote Request Process:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Worker will review your request',
                    style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  ),
                  Text(
                    '• You\'ll receive a quote with pricing',
                    style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  ),
                  Text(
                    '• You can accept or decline the quote',
                    style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                  ),
                ],
              ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Send Quote Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // If confirmed, call _createQuote instead of _createBooking
    if (confirmed == true) {
      await _createQuote(
          worker); // CHANGED: Call quote method instead of booking
    }
  }

// MODIFIED: Updated loading dialog message
  Future<void> _createQuote(WorkerModel worker) async {
    try {
      print('\n========== QUOTE CREATION START ==========');

      // Show loading dialog with quote-specific message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(width: 16),
              Text('Sending quote request...'), // CHANGED: Updated message
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

      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // Get worker_id from WorkerModel
      String? nullableWorkerId = worker.workerId;

      if (nullableWorkerId == null || nullableWorkerId.isEmpty) {
        throw Exception('Worker ID is missing');
      }

      String workerId = nullableWorkerId;

      print('📋 Quote details:');
      print('   Customer ID: $customerId');
      print('   Worker ID: $workerId');
      print('   Service: ${widget.serviceType}');

      // Verify workerId format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX format)');
      }

      // Create quote using QuoteService
      String quoteId = await QuoteService.createQuote(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
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

      print('✅ Quote created successfully!');
      print('   Quote ID: $quoteId');

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with "View Quotes" button
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 32),
              SizedBox(width: 12),
              Text('Quote Request Sent!'), // CHANGED: Updated title
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your quote request has been sent successfully.'),
              SizedBox(height: 12),
              Text('Quote ID: $quoteId',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Worker: ${worker.workerName}'),
              Text('Service: ${widget.serviceType.replaceAll('_', ' ')}'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Next Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1. The worker will review your quote',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                    Text(
                      '2. You\'ll get notified when they respond',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                    Text(
                      '3. Check the Quotes tab in Bookings',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to Customer Dashboard with Bookings tab (Quotes)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDashboard(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('View Quotes',
                  style:
                      TextStyle(color: Colors.white)), // CHANGED: Button text
            ),
          ],
        ),
      );

      print('✅ Quote dialog shown');
      print('========== QUOTE CREATION END ==========\n');
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      print('❌ Error creating quote: $e');
      print('========== QUOTE CREATION END ==========\n');
      _showErrorSnackBar('Failed to create quote: ${e.toString()}');
    }
  }

  Future<void> _createBooking(WorkerModel worker) async {
    try {
      print('\n========== BOOKING CREATION START ==========');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.blue),
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

      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // Get worker_id from WorkerModel and handle null
      String? nullableWorkerId = worker.workerId;

      if (nullableWorkerId == null || nullableWorkerId.isEmpty) {
        throw Exception('Worker ID is missing');
      }

      String workerId = nullableWorkerId;

      print('📋 Booking details:');
      print('   Customer ID: $customerId');
      print('   Worker ID: $workerId');
      print('   Service: ${widget.serviceType}');

      // Verify workerId format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX format)');
      }

      // Create booking using BookingService with named parameters
      String bookingId = await BookingService.createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId,
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

      print('✅ Booking created successfully!');
      print('   Booking ID: $bookingId');

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 32),
              SizedBox(width: 12),
              Text('Booking Created!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your booking has been created successfully.'),
              SizedBox(height: 12),
              Text('Booking ID: $bookingId',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Worker: ${worker.workerName}'),
              Text('Service: ${widget.serviceType.replaceAll('_', ' ')}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // FIXED: Navigate to CustomerDashboard with Bookings tab (index 1)
                Navigator.pop(context); // Close dialog

                // Navigate to Customer Dashboard with Bookings tab selected
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDashboard(
                        initialIndex: 1), // Open on Bookings tab
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child:
                  Text('View Bookings', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      print('✅ Booking dialog shown');
      print('========== BOOKING CREATION END ==========\n');
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);

      print('❌ Error creating booking: $e');
      print('========== BOOKING CREATION END ==========\n');
      _showErrorSnackBar('Failed to create booking: ${e.toString()}');
    }
  }
}
