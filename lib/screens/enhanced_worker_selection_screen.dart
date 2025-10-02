// lib/screens/enhanced_worker_selection_screen.dart
// COMPLETE FIXED VERSION with Location Selection and Blue Theme
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

  // Location selection
  String? _selectedLocation;
  final List<String> _sriLankanTowns = [
    'Colombo',
    'Negombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Batticaloa',
    'Trincomalee',
    'Anuradhapura',
    'Polonnaruwa',
    'Kurunegala',
    'Ratnapura',
    'Badulla',
    'Ampara',
    'Hambantota',
    'Puttalam',
    'Vavuniya',
    'Kegalle',
    'Nuwara Eliya',
    'Monaragala',
    'Kilinochchi',
    'Mannar',
    'Mullaitivu',
    'Chilaw',
    'Matale',
    'Avissawella',
    'Panadura',
  ];

  double _maxDistance = 100.0;
  double _minRating = 0.0;
  RangeValues _experienceRange = RangeValues(0, 20);
  RangeValues _priceRange = RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    _loadUserLocationAndWorkers();
  }

  Future<void> _loadUserLocationAndWorkers() async {
    await _loadUserLocation();
    await _loadWorkers();
  }

  Future<void> _loadUserLocation() async {
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
          String? nearestTown = userData['nearestTown'];

          if (nearestTown != null && nearestTown.isNotEmpty) {
            setState(() {
              _selectedLocation = nearestTown;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user location: $e');
    }
  }

  Future<void> _loadWorkers() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot workersSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .where('service_type', isEqualTo: widget.serviceType)
          .get();

      List<WorkerModel> workers = [];
      for (var doc in workersSnapshot.docs) {
        try {
          WorkerModel worker = WorkerModel.fromFirestore(doc);
          workers.add(worker);
        } catch (e) {
          print('Error parsing worker ${doc.id}: $e');
        }
      }

      setState(() {
        _allWorkers = workers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load workers: ${e.toString()}');
    }
  }

  void _applyFilters() {
    List<WorkerModel> filtered = List.from(_allWorkers);

    // Filter by location if selected
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((worker) {
        return worker.location.city.toLowerCase() ==
            _selectedLocation!.toLowerCase();
      }).toList();
    }

    // Apply other filters
    filtered = filtered.where((worker) {
      if (_minRating > 0 && worker.rating < _minRating) return false;
      if (worker.experienceYears < _experienceRange.start ||
          worker.experienceYears > _experienceRange.end) return false;

      double workerPrice = worker.pricing.minimumChargeLkr;
      if (workerPrice < _priceRange.start || workerPrice > _priceRange.end) {
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
      case 'jobs':
        filtered.sort((a, b) => b.jobsCompleted.compareTo(a.jobsCompleted));
        break;
    }

    setState(() {
      _filteredWorkers = filtered;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Select ${widget.serviceType.replaceAll('_', ' ').toUpperCase()} Professional',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF2196F3),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildLocationSelector(),
          _buildSortAndFilterBar(),
          if (!_isLoading) _buildWorkerCount(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2196F3),
                    ),
                  )
                : _buildWorkerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Color(0xFF2196F3)),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: InputDecoration(
                labelText: 'Select Location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF2196F3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _sriLankanTowns.map((String town) {
                return DropdownMenuItem<String>(
                  value: town,
                  child: Text(town),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLocation = newValue;
                  _applyFilters();
                });
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Rating', 'rating', Icons.star),
                      _buildSortChip('Price', 'price', Icons.attach_money),
                      _buildSortChip('Experience', 'experience', Icons.work),
                      _buildSortChip('Jobs', 'jobs', Icons.check_circle),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                  color: _showFilters ? Color(0xFF2196F3) : Colors.grey,
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
                size: 16, color: isSelected ? Colors.white : Color(0xFF2196F3)),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSortBy = value;
            _applyFilters();
          });
        },
        selectedColor: Color(0xFF2196F3),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Color(0xFF2196F3),
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: Color(0xFF2196F3)),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}',
            style: TextStyle(fontWeight: FontWeight.w500)),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: Color(0xFF2196F3),
          onChanged: (value) {
            setState(() {
              _minRating = value;
              _applyFilters();
            });
          },
        ),
        SizedBox(height: 8),
        Text(
            'Experience: ${_experienceRange.start.round()}-${_experienceRange.end.round()} years',
            style: TextStyle(fontWeight: FontWeight.w500)),
        RangeSlider(
          values: _experienceRange,
          min: 0,
          max: 20,
          divisions: 20,
          activeColor: Color(0xFF2196F3),
          onChanged: (values) {
            setState(() {
              _experienceRange = values;
              _applyFilters();
            });
          },
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: Icon(Icons.clear, color: Color(0xFF2196F3)),
              label: Text('Clear Filters',
                  style: TextStyle(color: Color(0xFF2196F3))),
              onPressed: () {
                setState(() {
                  _minRating = 0.0;
                  _experienceRange = RangeValues(0, 20);
                  _priceRange = RangeValues(0, 100000);
                  _applyFilters();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkerCount() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredWorkers.length} professional${_filteredWorkers.length != 1 ? 's' : ''} found',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList() {
    if (_filteredWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'No workers found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              _selectedLocation != null
                  ? 'Try changing location or adjusting filters'
                  : 'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

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
                    backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                    child: Text(
                      worker.workerName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '${worker.rating.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.work_outline,
                                color: Colors.grey[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${worker.experienceYears} years',
                              style: TextStyle(color: Colors.grey[600]),
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
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF2196F3), size: 16),
                  SizedBox(width: 4),
                  Text(
                    worker.location.city,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Spacer(),
                  Icon(Icons.check_circle_outline,
                      color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${worker.jobsCompleted} jobs',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Minimum Charge',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _bookWorker(worker),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Select Worker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkerDetails(WorkerModel worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF2196F3).withOpacity(0.1),
                      child: Text(
                        worker.workerName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
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
                          SizedBox(height: 4),
                          Text(
                            worker.serviceType
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildDetailRow(Icons.star, 'Rating',
                    '${worker.rating.toStringAsFixed(1)} / 5.0'),
                _buildDetailRow(Icons.work, 'Experience',
                    '${worker.experienceYears} years'),
                _buildDetailRow(
                    Icons.location_on, 'Location', worker.location.city),
                _buildDetailRow(Icons.check_circle, 'Completed Jobs',
                    '${worker.jobsCompleted}'),
                _buildDetailRow(
                    Icons.phone, 'Phone', worker.contact.phoneNumber),
                SizedBox(height: 16),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  worker.profile.bio,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _bookWorker(worker);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF2196F3), size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bookWorker(WorkerModel worker) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      ),
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please login to book a worker');

      // Get customer details
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String customerName = customerDoc.data() != null
          ? (customerDoc.data() as Map<String, dynamic>)['name'] ?? 'Customer'
          : 'Customer';
      String customerPhone = customerDoc.data() != null
          ? (customerDoc.data() as Map<String, dynamic>)['phone'] ?? ''
          : '';

      // Validate worker ID
      if (worker.workerId == null || worker.workerId!.isEmpty) {
        throw Exception('Invalid worker ID');
      }

      // Create booking
      await BookingService.createBooking(
        customerId: user.uid,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: user.email ?? '',
        workerId: worker.workerId!,
        workerName: worker.workerName,
        workerPhone: worker.contact.phoneNumber,
        serviceType: widget.serviceType,
        subService: widget.subService,
        issueType: widget.issueType,
        problemDescription: widget.problemDescription,
        problemImageUrls: widget.problemImageUrls,
        location: _selectedLocation ?? widget.location,
        address: widget.address,
        urgency: widget.urgency,
        budgetRange: widget.budgetRange,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
      );

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close worker selection

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Booking request sent successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book worker: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
