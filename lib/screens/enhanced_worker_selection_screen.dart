// lib/screens/enhanced_worker_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../constants/service_constants.dart';
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

  // ✨ NEW: Initialize user's location
  void _initializeUserLocation() {
    _userLatitude = 6.9271;
    _userLongitude = 79.8612;

    if (widget.location.isNotEmpty) {
      _locationController.text = widget.location;
    }
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

      List<WorkerModel> workers = await WorkerService.searchWorkers(
        serviceType: widget.serviceType,
        serviceCategory: widget.subService,
        userLat: 6.9271,
        userLng: 79.8612,
        maxDistance: 100.0,
      );

      if (workers.isEmpty) {
        List<WorkerModel> allWorkers = [];
        for (var doc in allWorkersSnapshot.docs) {
          try {
            WorkerModel worker = WorkerModel.fromFirestore(doc);
            allWorkers.add(worker);
          } catch (e) {
            print('DEBUG: Error parsing worker ${doc.id}: $e');
          }
        }

        workers = allWorkers.where((worker) {
          return worker.serviceType.toLowerCase() ==
              widget.serviceType.toLowerCase();
        }).toList();
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
                      _buildSortChip('Distance', 'distance', Icons.location_on),
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
                  hintText: 'Enter city name (e.g., Colombo, Kandy)',
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
          min: 5,
          max: 100,
          divisions: 19,
          activeColor: Colors.orange,
          label: '${_maxDistance.toStringAsFixed(0)} km',
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

        Text(
            'Price Range: LKR ${_priceRange.start.round()} - ${_priceRange.end.round()}'),
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

  Widget _buildWorkerList() {
    if (_filteredWorkers.isEmpty) {
      return _allWorkers.isEmpty
          ? _buildNoWorkersAvailable()
          : _buildNoWorkersMatchingFilters();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        return _buildWorkerCard(_filteredWorkers[index]);
      },
    );
  }

  Widget _buildNoWorkersAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
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
              'No workers found for this service type.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
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
                  SizedBox(width: 16),
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
                              worker.rating > 0
                                  ? '${worker.rating.toStringAsFixed(1)}'
                                  : 'New',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.work, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text('${worker.experienceYears} yrs'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),

              // ✨ NEW: Location with distance
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.red[400]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${worker.location.city}, ${worker.location.state}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  if (distance != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me,
                              size: 14, color: Colors.blue[700]),
                          SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.attach_money, size: 18, color: Colors.green[600]),
                  SizedBox(width: 8),
                  Text(
                    'Starting from LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              if (worker.profile.specializations.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: worker.profile.specializations.take(3).map((spec) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spec,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    Icons.check_circle_outline,
                    '${worker.jobsCompleted}',
                    'Jobs',
                  ),
                  _buildStatItem(
                    Icons.timer,
                    '${worker.availability.responseTimeMinutes}m',
                    'Response',
                  ),
                  ElevatedButton(
                    onPressed: () => _selectWorker(worker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Select',
                      style: TextStyle(color: Colors.white),
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

  void _showWorkerDetails(WorkerModel worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          double? distance;
          if (_userLatitude != null && _userLongitude != null) {
            distance = _calculateDistance(
              _userLatitude!,
              _userLongitude!,
              worker.location.latitude,
              worker.location.longitude,
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.all(20),
                    children: [
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
                              ? Icon(Icons.person,
                                  size: 50, color: Colors.orange)
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        worker.workerName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        worker.businessName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            Icons.star,
                            worker.rating > 0
                                ? worker.rating.toStringAsFixed(1)
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
                            'Completed',
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Divider(),
                      SizedBox(height: 16),
                      Text(
                        'Bio',
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
                      if (distance != null)
                        _buildDetailRow(
                          Icons.near_me,
                          '${distance.toStringAsFixed(1)} km from your location',
                        ),
                      _buildDetailRow(Icons.map,
                          'Service Radius: ${worker.profile.serviceRadiusKm} km'),
                      SizedBox(height: 16),
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
                          'LKR ${worker.pricing.dailyWageLkr.toStringAsFixed(0)}/day'),
                      _buildPriceRow('Half Day Rate',
                          'LKR ${worker.pricing.halfDayRateLkr.toStringAsFixed(0)}'),
                      SizedBox(height: 16),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Languages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: worker.capabilities.languages.map((lang) {
                          return Chip(
                            label: Text(lang, style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.blue[50],
                            labelStyle: TextStyle(color: Colors.blue[700]),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectWorker(worker);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Select This Worker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

  Future<void> _createBooking(WorkerModel worker) async {
    try {
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

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context);
        _showErrorSnackBar('Please log in to create a booking');
        return;
      }

      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(currentUser.uid)
          .get();

      if (!customerDoc.exists) {
        Navigator.pop(context);
        _showErrorSnackBar('Customer profile not found');
        return;
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

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);

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
}
