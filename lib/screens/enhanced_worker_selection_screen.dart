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

  // REPLACE THE _buildWorkerCard METHOD IN enhanced_worker_selection_screen.dart
// Find the existing _buildWorkerCard method and replace it with this version

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
            // Worker Header with Profile Picture
            Row(
              children: [
                // ✅ Profile Picture with fallback to avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange[100],
                  backgroundImage: worker.profilePictureUrl != null &&
                          worker.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(worker.profilePictureUrl!)
                      : null,
                  child: worker.profilePictureUrl == null ||
                          worker.profilePictureUrl!.isEmpty
                      ? Text(
                          worker.workerName.isNotEmpty
                              ? worker.workerName[0].toUpperCase()
                              : 'W',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        )
                      : null,
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
                  worker.rating > 0
                      ? '${worker.rating.toStringAsFixed(1)}'
                      : 'New',
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

            // Minimum Charge and Location
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
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      worker.location.city,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // Availability Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: worker.availability.availableToday
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                worker.availability.availableToday
                    ? 'Available Today'
                    : 'Schedule Required',
                style: TextStyle(
                  fontSize: 12,
                  color: worker.availability.availableToday
                      ? Colors.green[700]
                      : Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),

            // ✅ Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // View Details Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showWorkerDetailsDialog(worker),
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // View Rates Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRatesDialog(worker),
                    icon: Icon(Icons.attach_money, size: 18),
                    label: Text('Rates'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // View Reviews Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewsDialog(worker),
                    icon: Icon(Icons.rate_review, size: 18),
                    label: Text('Reviews'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
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

// ✅ NEW: Show Worker Details Dialog
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
                  // Header with profile picture
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
                            ? Text(
                                worker.workerName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              )
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (worker.verified)
                              Row(
                                children: [
                                  Icon(Icons.verified,
                                      size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Professional',
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
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 16),

                  // Bio
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),

                  // Contact Information
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(Icons.phone, worker.contact.phoneNumber),
                  _buildDetailRow(Icons.email, worker.contact.email),
                  if (worker.contact.website != null)
                    _buildDetailRow(Icons.language, worker.contact.website!),
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
                        backgroundColor: Colors.orange[50],
                        labelStyle: TextStyle(color: Colors.orange[700]),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Languages
                  Text(
                    'Languages',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    worker.capabilities.languages.join(', '),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),

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
                    _buildCapabilityChip('Tools Owned', Icons.build),
                  if (worker.capabilities.vehicleAvailable)
                    _buildCapabilityChip(
                        'Vehicle Available', Icons.directions_car),
                  if (worker.capabilities.certified)
                    _buildCapabilityChip('Certified', Icons.verified),
                  if (worker.capabilities.insurance)
                    _buildCapabilityChip('Insured', Icons.shield),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// ✅ NEW: Show Rates Dialog
  void _showRatesDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.attach_money, color: Colors.green),
            SizedBox(width: 8),
            Text('Pricing Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceRow('Daily Wage',
                'LKR ${worker.pricing.dailyWageLkr.toStringAsFixed(0)}'),
            _buildPriceRow('Half Day Rate',
                'LKR ${worker.pricing.halfDayRateLkr.toStringAsFixed(0)}'),
            _buildPriceRow('Minimum Charge',
                'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}'),
            _buildPriceRow('Overtime Rate',
                'LKR ${worker.pricing.overtimeHourlyLkr.toStringAsFixed(0)}/hour'),
            if (worker.pricing.emergencyRateMultiplier > 1.0)
              _buildPriceRow('Emergency Multiplier',
                  '${worker.pricing.emergencyRateMultiplier}x'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Final price may vary based on job complexity and duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _selectWorker(worker);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Select Worker', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// ✅ NEW: Show Reviews Dialog
  // REPLACE the _showReviewsDialog method in enhanced_worker_selection_screen.dart
// This version works WITHOUT requiring a Firestore index

// ✅ FIXED: Show Reviews Dialog - No index required
  void _showReviewsDialog(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.rate_review, color: Colors.blue),
            SizedBox(width: 8),
            Text('Reviews & Ratings'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Overall Rating
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < worker.rating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 20,
                            );
                          }),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${worker.jobsCompleted} reviews',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Success Rate',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          '${worker.successRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // ✅ Load reviews WITHOUT orderBy (no index required)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('worker_id', isEqualTo: worker.workerId)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            SizedBox(height: 8),
                            Text(
                              'Error loading reviews',
                              style: TextStyle(color: Colors.red),
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                snapshot.error.toString(),
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to review this worker',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // ✅ Sort reviews manually after fetching (no index needed)
                    List<DocumentSnapshot> reviewDocs = snapshot.data!.docs;
                    reviewDocs.sort((a, b) {
                      try {
                        var aData = a.data() as Map<String, dynamic>;
                        var bData = b.data() as Map<String, dynamic>;

                        Timestamp? aTime = aData['created_at'] as Timestamp?;
                        Timestamp? bTime = bData['created_at'] as Timestamp?;

                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;

                        return bTime.compareTo(aTime); // Newest first
                      } catch (e) {
                        return 0;
                      }
                    });

                    // Display reviews
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: reviewDocs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> reviewData =
                            reviewDocs[index].data() as Map<String, dynamic>;

                        return _buildReviewCard(reviewData);
                      },
                    );
                  },
                ),
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

// ✅ Build individual review card
  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    String customerName = reviewData['customer_name'] ?? 'Anonymous';
    int rating = reviewData['rating'] ?? 0;
    String reviewText = reviewData['review'] ?? '';
    String serviceType = reviewData['service_type'] ?? 'Service';
    List<dynamic> tags = reviewData['tags'] ?? [];
    DateTime? createdAt;

    try {
      if (reviewData['created_at'] != null) {
        createdAt = (reviewData['created_at'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Customer name and rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          customerName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (createdAt != null)
                              Text(
                                _formatDate(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Star rating
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 14),
                      SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Service type badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                serviceType.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ),

            SizedBox(height: 8),

            // Review text
            if (reviewText.isNotEmpty)
              Text(
                reviewText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),

            // Tags
            if (tags.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      tag.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

// ✅ Format date helper
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

// Helper Widgets
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

  // lib/screens/enhanced_worker_selection_screen.dart
// FIND AND REPLACE the _createBooking method with this FIXED version

// ==================== FIXED BOOKING METHOD ====================
// Replace your existing _createBooking method with this:

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

      String customerId = customerData['customer_id'] ?? user.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? user.email ?? '';

      // CRITICAL FIX: Get worker_id from WorkerModel and handle null
      String? nullableWorkerId = worker.workerId;

      if (nullableWorkerId == null || nullableWorkerId.isEmpty) {
        throw Exception('Worker ID is missing');
      }

      String workerId = nullableWorkerId; // Now it's non-null

      print('📋 Booking details:');
      print('   Customer ID: $customerId');
      print('   Worker ID: $workerId'); // Should be HM_XXXX
      print('   Service: ${widget.serviceType}');

      // CRITICAL: Verify workerId format
      if (!workerId.startsWith('HM_')) {
        throw Exception(
            'Invalid worker_id format: $workerId (expected HM_XXXX format)');
      }

      // Create booking using BookingService
      String bookingId = await BookingService.createBooking(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        workerId: workerId, // ✅ This is HM_XXXX format
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
      print('   Worker ID: $workerId');
      print('========== BOOKING CREATION END ==========\n');

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text('Booking Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your booking has been created successfully!',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Booking ID: ${bookingId.length > 12 ? bookingId.substring(0, 12) + '...' : bookingId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: 12),
              Text(
                '${worker.workerName} will be notified about your request.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error creating booking: $e');
      print('========== BOOKING CREATION END ==========\n');

      // Close loading dialog if still open
      Navigator.pop(context);

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Booking Failed'),
            ],
          ),
          content: Text(
            'Failed to create booking: $e\n\nPlease try again.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
