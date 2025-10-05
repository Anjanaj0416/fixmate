// lib/screens/enhanced_worker_selection_screen.dart
// FIXED VERSION - Location default value and navigation after booking
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../constants/service_constants.dart';
import 'customer_bookings_screen.dart';
import 'dart:math' as math;

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

  double _maxDistance = 100.0;
  double _minRating = 0.0;
  RangeValues _experienceRange = RangeValues(0, 20);
  RangeValues _priceRange = RangeValues(0, 100000);
  String _locationFilter = 'all';

  // ✨ NEW: Location input controller and suggestions
  final TextEditingController _locationController = TextEditingController();
  List<String> _availableLocations = [];
  bool _showLocationSuggestions = false;

  // ✨ NEW: User's current location coordinates for distance calculation
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _initializeUserLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // ✨ FIXED: Initialize user's location - DO NOT set location filter here
  void _initializeUserLocation() {
    _userLatitude = 6.9271;
    _userLongitude = 79.8612;

    // FIX #1: Do NOT set the location controller text here
    // Keep locationFilter as 'all' by default to show all workers
    // The text field should remain empty to indicate "All" locations
  }

  // ✨ NEW: Extract unique locations from workers
  void _extractAvailableLocations() {
    Set<String> locations = {};
    for (var worker in _allWorkers) {
      locations.add(worker.location.city);
    }
    setState(() {
      _availableLocations = locations.toList()..sort();
    });
  }

  // ✨ NEW: Calculate distance between two coordinates
  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  Future<void> _loadWorkers() async {
    try {
      print('DEBUG: Starting to load workers...');
      setState(() => _isLoading = true);

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

      List<WorkerModel> workers = [];
      for (var doc in allWorkersSnapshot.docs) {
        try {
          WorkerModel worker = WorkerModel.fromFirestore(doc);
          workers.add(worker);
        } catch (e) {
          print('DEBUG: Error parsing worker ${doc.id}: $e');
        }
      }

      setState(() {
        _allWorkers = workers;
        _filteredWorkers = workers;
        _isLoading = false;
      });

      _extractAvailableLocations();

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
    List<WorkerModel> filtered = List.from(_allWorkers);

    filtered = filtered.where((worker) {
      if (_minRating > 0 && worker.rating < _minRating) return false;

      if (worker.experienceYears < _experienceRange.start ||
          worker.experienceYears > _experienceRange.end) return false;

      double workerPrice = worker.pricing.minimumChargeLkr;
      if (workerPrice < _priceRange.start || workerPrice > _priceRange.end)
        return false;

      if (_locationFilter != 'all' &&
          worker.location.city.toLowerCase() != _locationFilter.toLowerCase())
        return false;

      // ✨ NEW: Filter by distance
      if (_userLatitude != null && _userLongitude != null) {
        double distance = _calculateDistance(
          _userLatitude!,
          _userLongitude!,
          worker.location.latitude,
          worker.location.longitude,
        );
        if (distance > _maxDistance) return false;
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
        // ✨ NEW: Sort by distance
        if (_userLatitude != null && _userLongitude != null) {
          filtered.sort((a, b) {
            double distA = _calculateDistance(
              _userLatitude!,
              _userLongitude!,
              a.location.latitude,
              a.location.longitude,
            );
            double distB = _calculateDistance(
              _userLatitude!,
              _userLongitude!,
              b.location.latitude,
              b.location.longitude,
            );
            return distA.compareTo(distB);
          });
        }
        break;
      case 'jobs':
        filtered.sort((a, b) => b.jobsCompleted.compareTo(a.jobsCompleted));
        break;
    }

    setState(() {
      _filteredWorkers = filtered;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _maxDistance = 100.0;
      _minRating = 0.0;
      _experienceRange = RangeValues(0, 20);
      _priceRange = RangeValues(0, 100000);
      _locationFilter = 'all';
      _locationController.clear();
      _filteredWorkers = List.from(_allWorkers);
    });
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
          _buildSortAndFilterBar(),
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
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredWorkers.isEmpty
                    ? (_allWorkers.isEmpty
                        ? _buildNoWorkersFound()
                        : _buildNoWorkersMatchingFilters())
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredWorkers.length,
                        itemBuilder: (context, index) {
                          return _buildWorkerCard(_filteredWorkers[index]);
                        },
                      ),
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
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('rating', 'Rating', Icons.star),
                      SizedBox(width: 8),
                      _buildSortChip('price', 'Price', Icons.attach_money),
                      SizedBox(width: 8),
                      _buildSortChip(
                          'experience', 'Experience', Icons.work_history),
                      SizedBox(width: 8),
                      _buildSortChip('distance', 'Distance', Icons.location_on),
                      SizedBox(width: 8),
                      _buildSortChip(
                          'jobs', 'Jobs', Icons.assignment_turned_in),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(Icons.filter_list),
            label: Text('Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          if (_showFilters) ...[
            SizedBox(height: 16),
            _buildFiltersPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    bool isSelected = _selectedSortBy == value;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : Colors.grey,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey,
          ),
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
        SizedBox(height: 16),

        // ✨ NEW: Location Input Field
        Text(
          'Filter by Location',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'All locations (enter city to filter)',
                  prefixIcon: Icon(Icons.location_city, color: Colors.orange),
                  suffixIcon: _locationController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _locationController.clear();
                              _locationFilter = 'all';
                              _showLocationSuggestions = false;
                            });
                            _applySortingAndFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _showLocationSuggestions = value.isNotEmpty;
                  });
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _locationFilter = value;
                      _showLocationSuggestions = false;
                    });
                    _applySortingAndFilters();
                  }
                },
              ),

              // Location Suggestions
              if (_showLocationSuggestions && _availableLocations.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  constraints: BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableLocations
                        .where((loc) => loc
                            .toLowerCase()
                            .contains(_locationController.text.toLowerCase()))
                        .length,
                    itemBuilder: (context, index) {
                      final filteredLocations = _availableLocations
                          .where((loc) => loc
                              .toLowerCase()
                              .contains(_locationController.text.toLowerCase()))
                          .toList();

                      if (index >= filteredLocations.length)
                        return SizedBox.shrink();

                      final location = filteredLocations[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.location_on,
                            size: 18, color: Colors.orange),
                        title: Text(location, style: TextStyle(fontSize: 14)),
                        onTap: () {
                          setState(() {
                            _locationController.text = location;
                            _locationFilter = location;
                            _showLocationSuggestions = false;
                          });
                          _applySortingAndFilters();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        if (_locationFilter != 'all')
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar:
                      Icon(Icons.location_on, size: 16, color: Colors.white),
                  label: Text(_locationFilter,
                      style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.orange,
                  deleteIcon: Icon(Icons.close, size: 18, color: Colors.white),
                  onDeleted: () {
                    setState(() {
                      _locationFilter = 'all';
                      _locationController.clear();
                    });
                    _applySortingAndFilters();
                  },
                ),
              ],
            ),
          ),

        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 8),

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

        // ✨ NEW: Maximum Distance Filter
        Text('Maximum Distance: ${_maxDistance.toStringAsFixed(0)} km'),
        Slider(
          value: _maxDistance,
          min: 10,
          max: 200,
          divisions: 19,
          activeColor: Colors.orange,
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
          onChangeEnd: (value) {
            _applySortingAndFilters();
          },
        ),

        SizedBox(height: 8),

        Text(
            'Experience: ${_experienceRange.start.toInt()} - ${_experienceRange.end.toInt()} years'),
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

        Text(
            'Price Range: LKR ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()}'),
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
      ],
    );
  }

  Widget _buildNoWorkersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Professionals Found',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'We couldn\'t find any professionals\nfor this service at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadWorkers,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Professionals Match Filters',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearAllFilters,
            icon: Icon(Icons.clear_all),
            label: Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    // ✨ NEW: Calculate distance
    double? distance;
    if (_userLatitude != null && _userLongitude != null) {
      distance = _calculateDistance(
        _userLatitude!,
        _userLongitude!,
        worker.location.latitude,
        worker.location.longitude,
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showWorkerDetails(worker),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange[100],
                    backgroundImage: worker.profilePictureUrl != null &&
                            worker.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(worker.profilePictureUrl!)
                        : null,
                    child: worker.profilePictureUrl == null ||
                            worker.profilePictureUrl!.isEmpty
                        ? Icon(Icons.person, size: 30, color: Colors.orange)
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
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${worker.rating.toStringAsFixed(1)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.work, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${worker.jobsCompleted} jobs',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.location_on,
                    worker.location.city,
                    Colors.blue,
                  ),
                  if (distance != null)
                    _buildInfoChip(
                      Icons.directions,
                      '${distance.toStringAsFixed(1)} km',
                      Colors.green,
                    ),
                  _buildInfoChip(
                    Icons.access_time,
                    '${worker.experienceYears} yrs exp',
                    Colors.orange,
                  ),
                  _buildInfoChip(
                    Icons.attach_money,
                    'From LKR ${worker.pricing.minimumChargeLkr}',
                    Colors.purple,
                  ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _confirmAndBook(worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 44),
                ),
                child: Text('Select This Professional'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  void _showWorkerDetails(WorkerModel worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
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
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.orange[100],
                  backgroundImage: worker.profilePictureUrl != null &&
                          worker.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(worker.profilePictureUrl!)
                      : null,
                  child: worker.profilePictureUrl == null ||
                          worker.profilePictureUrl!.isEmpty
                      ? Icon(Icons.person, size: 50, color: Colors.orange)
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Text(
                worker.workerName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '${worker.rating.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildDetailRow(Icons.location_on, 'Location',
                  '${worker.location.city}, ${worker.location.state}'),
              _buildDetailRow(
                  Icons.phone, 'Contact', worker.contact.phoneNumber),
              _buildDetailRow(Icons.email, 'Email', worker.contact.email),
              _buildDetailRow(
                  Icons.work, 'Experience', '${worker.experienceYears} years'),
              _buildDetailRow(Icons.assignment_turned_in, 'Jobs Completed',
                  '${worker.jobsCompleted}'),
              _buildDetailRow(Icons.attach_money, 'Minimum Charge',
                  'LKR ${worker.pricing.minimumChargeLkr}'),
              if (worker.profile.bio.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('About',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(worker.profile.bio,
                    style: TextStyle(color: Colors.grey[600])),
              ],
              if (worker.profile.specializations.isNotEmpty) ...[
                SizedBox(height: 16),
                Text('Specializations',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: worker.profile.specializations
                      .map((spec) => Chip(
                            label: Text(spec),
                            backgroundColor: Colors.orange[100],
                          ))
                      .toList(),
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmAndBook(worker);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Select This Professional',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAndBook(WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to book ${worker.workerName}?'),
            SizedBox(height: 16),
            Text('Service: ${widget.serviceType}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Sub-Service: ${widget.subService}'),
            Text('Scheduled: ${widget.scheduledDate.toString().split(' ')[0]}'),
            Text('Time: ${widget.scheduledTime}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createBooking(worker);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooking(WorkerModel worker) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(currentUser.uid)
          .get();

      if (!customerDoc.exists) {
        throw Exception('Customer profile not found');
      }

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;
      String customerId = customerData['customer_id'] ?? currentUser.uid;
      String customerName = customerData['customer_name'] ??
          '${customerData['first_name'] ?? ''} ${customerData['last_name'] ?? ''}'
              .trim();
      String customerPhone = customerData['phone_number'] ?? '';
      String customerEmail = customerData['email'] ?? currentUser.email ?? '';

      String? workerId = worker.workerId;

      if (workerId == null || workerId.isEmpty) {
        throw Exception('Worker ID is missing');
      }

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

      // FIX #2: Navigate to bookings screen instead of going back to welcome
      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close worker selection screen
      Navigator.pop(context); // Close service request flow

      // Navigate to bookings screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CustomerBookingsScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Failed to create booking: ${e.toString()}');
    }
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
}
