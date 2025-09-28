// lib/screens/worker_search_quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/quote_model.dart';
import '../services/booking_service.dart';
import 'booking_confirmation_screen.dart';

class WorkerSearchQuotesScreen extends StatefulWidget {
  final String serviceRequestId;
  final String serviceType;
  final String problemDescription;
  final double? latitude;
  final double? longitude;

  const WorkerSearchQuotesScreen({
    Key? key,
    required this.serviceRequestId,
    required this.serviceType,
    required this.problemDescription,
    this.latitude,
    this.longitude,
  }) : super(key: key);

  @override
  _WorkerSearchQuotesScreenState createState() =>
      _WorkerSearchQuotesScreenState();
}

class _WorkerSearchQuotesScreenState extends State<WorkerSearchQuotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WorkerModel> _workers = [];
  List<QuoteModel> _quotes = [];
  bool _isLoading = true;
  String _sortBy = 'rating'; // rating, price, distance
  double _maxDistance = 20.0;
  double _minRating = 0.0;
  double _maxPrice = 50000.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadWorkers(),
        _loadQuotes(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkers() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('workers')
          .where('service_type', isEqualTo: widget.serviceType)
          .where('rating', isGreaterThanOrEqualTo: _minRating);

      QuerySnapshot snapshot = await query.get();
      List<WorkerModel> workers =
          snapshot.docs.map((doc) => WorkerModel.fromFirestore(doc)).toList();

      // Filter by distance if location is available
      if (widget.latitude != null && widget.longitude != null) {
        workers = workers.where((worker) {
          double distance = _calculateDistance(
            widget.latitude!,
            widget.longitude!,
            worker.location.latitude,
            worker.location.longitude,
          );
          return distance <= _maxDistance;
        }).toList();
      }

      // Sort workers
      _sortWorkers(workers);

      setState(() {
        _workers = workers;
      });
    } catch (e) {
      throw Exception('Failed to load workers: ${e.toString()}');
    }
  }

  Future<void> _loadQuotes() async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('quotes')
          .where('customer_id', isEqualTo: currentUserId)
          .where('service_request_id', isEqualTo: widget.serviceRequestId)
          .orderBy('created_at', descending: true)
          .get();

      List<QuoteModel> quotes =
          snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList();

      setState(() {
        _quotes = quotes;
      });
    } catch (e) {
      throw Exception('Failed to load quotes: ${e.toString()}');
    }
  }

  void _sortWorkers(List<WorkerModel> workers) {
    switch (_sortBy) {
      case 'rating':
        workers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price':
        workers.sort(
            (a, b) => a.pricing.dailyWageLkr.compareTo(b.pricing.dailyWageLkr));
        break;
      case 'distance':
        if (widget.latitude != null && widget.longitude != null) {
          workers.sort((a, b) {
            double distanceA = _calculateDistance(
              widget.latitude!,
              widget.longitude!,
              a.location.latitude,
              a.location.longitude,
            );
            double distanceB = _calculateDistance(
              widget.latitude!,
              widget.longitude!,
              b.location.latitude,
              b.location.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation - for production use proper geospatial queries
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() *
            _toRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();
    double c = 2 * (a.sqrt()).asin();
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workers & Quotes'),
        backgroundColor: Color(0xFFFF9800),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people),
                  SizedBox(width: 8),
                  Text('Workers (${_workers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_quote),
                  SizedBox(width: 8),
                  Text('Quotes (${_quotes.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkersTab(),
                _buildQuotesTab(),
              ],
            ),
    );
  }

  Widget _buildWorkersTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        Expanded(
          child: _workers.isEmpty
              ? _buildEmptyState(
                  'No workers available',
                  'Try adjusting your filters or check back later.',
                  Icons.people_outline,
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _workers.length,
                  itemBuilder: (context, index) =>
                      _buildWorkerCard(_workers[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildQuotesTab() {
    return _quotes.isEmpty
        ? _buildEmptyState(
            'No quotes yet',
            'Workers will send quotes for your request soon.',
            Icons.request_quote_outlined,
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _quotes.length,
            itemBuilder: (context, index) => _buildQuoteCard(_quotes[index]),
          );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: 'rating', child: Text('Rating')),
                    DropdownMenuItem(value: 'price', child: Text('Price')),
                    if (widget.latitude != null)
                      DropdownMenuItem(
                          value: 'distance', child: Text('Distance')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _sortWorkers(_workers);
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              IconButton(
                onPressed: _showFiltersDialog,
                icon: Icon(Icons.filter_list, color: Color(0xFFFF9800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    double? distance;
    if (widget.latitude != null && widget.longitude != null) {
      distance = _calculateDistance(
        widget.latitude!,
        widget.longitude!,
        worker.location.latitude,
        worker.location.longitude,
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFFF9800),
                  child: Text(
                    worker.firstName.isNotEmpty
                        ? worker.firstName[0].toUpperCase()
                        : 'W',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
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
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        worker.businessName,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 4),
                          Text(
                            '${worker.rating.toStringAsFixed(1)} (${worker.jobsCompleted} jobs)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Rate',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        'LKR ${worker.pricing.dailyWageLkr.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800)),
                      ),
                    ],
                  ),
                ),
                if (distance != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Distance',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Experience',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        '${worker.experienceYears} years',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
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
                    onPressed: () => _requestQuote(worker),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF9800)),
                    child: Text('Request Quote'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(QuoteModel quote) {
    bool isExpired = quote.validUntil.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.workerDetails?['worker_name'] ?? 'Worker',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        quote.workerDetails?['business_name'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQuoteStatusColor(quote.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getQuoteStatusColor(quote.status)
                            .withOpacity(0.3)),
                  ),
                  child: Text(
                    quote.status.toUpperCase(),
                    style: TextStyle(
                      color: _getQuoteStatusColor(quote.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: Color(0xFFFF9800)),
                  SizedBox(width: 8),
                  Text(
                    'LKR ${quote.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${quote.estimatedDurationHours}h estimated',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              quote.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (quote.includedServices.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Included Services:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: quote.includedServices
                    .map((service) => Chip(
                          label: Text(service, style: TextStyle(fontSize: 12)),
                          backgroundColor: Colors.green[50],
                        ))
                    .toList(),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Valid until ${_formatDate(quote.validUntil)}',
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (quote.status == 'pending' && !isExpired) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectQuote(quote.quoteId!),
                      child: Text('Decline'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptQuote(quote),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Text('Accept Quote'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Filter Workers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Maximum Distance: ${_maxDistance.toInt()} km'),
              Slider(
                value: _maxDistance,
                min: 5,
                max: 50,
                divisions: 9,
                onChanged: (value) =>
                    setDialogState(() => _maxDistance = value),
              ),
              SizedBox(height: 16),
              Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                onChanged: (value) => setDialogState(() => _minRating = value),
              ),
              SizedBox(height: 16),
              Text('Maximum Price: LKR ${_maxPrice.toInt()}'),
              Slider(
                value: _maxPrice,
                min: 1000,
                max: 100000,
                divisions: 20,
                onChanged: (value) => setDialogState(() => _maxPrice = value),
              ),
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
                _loadWorkers();
              },
              child: Text('Apply Filters'),
            ),
          ],
        ),
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
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
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
                SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFFF9800),
                      child: Text(
                        worker.firstName.isNotEmpty
                            ? worker.firstName[0].toUpperCase()
                            : 'W',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
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
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            worker.businessName,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(
                                '${worker.rating.toStringAsFixed(1)} (${worker.jobsCompleted} jobs)',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildProfileSection('About', worker.profile.bio),
                _buildProfileSection('Experience',
                    '${worker.experienceYears} years in ${worker.serviceType}'),
                _buildProfileSection('Service Area',
                    '${worker.profile.serviceRadiusKm.toInt()} km radius'),
                _buildProfileSection(
                    'Working Hours', worker.availability.workingHours),
                if (worker.profile.specializations.isNotEmpty)
                  _buildSpecializationsSection(worker.profile.specializations),
                if (worker.capabilities.languages.isNotEmpty)
                  _buildLanguagesSection(worker.capabilities.languages),
                _buildCapabilitiesSection(worker.capabilities),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _requestQuote(worker);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF9800),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        Text('Request Quote', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationsSection(List<String> specializations) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specializations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: specializations
                .map((spec) => Chip(
                      label: Text(spec),
                      backgroundColor: Color(0xFFFF9800).withOpacity(0.1),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection(List<String> languages) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            languages.join(', '),
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection(WorkerCapabilities capabilities) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capabilities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCapabilityItem(
                    Icons.build, 'Tools Owned', capabilities.toolsOwned),
              ),
              Expanded(
                child: _buildCapabilityItem(Icons.directions_car, 'Vehicle',
                    capabilities.vehicleAvailable),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCapabilityItem(
                    Icons.verified, 'Certified', capabilities.certified),
              ),
              Expanded(
                child: _buildCapabilityItem(
                    Icons.security, 'Insured', capabilities.insurance),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(IconData icon, String label, bool available) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: available ? Colors.green : Colors.grey,
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: available ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _requestQuote(WorkerModel worker) async {
    try {
      // Create quote request notification for worker
      await FirebaseFirestore.instance.collection('quote_requests').add({
        'worker_id': worker.workerId,
        'customer_id': FirebaseAuth.instance.currentUser?.uid,
        'service_request_id': widget.serviceRequestId,
        'service_type': widget.serviceType,
        'problem_description': widget.problemDescription,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Quote request sent to ${worker.workerName}');
    } catch (e) {
      _showErrorSnackBar('Failed to request quote: ${e.toString()}');
    }
  }

  Future<void> _acceptQuote(QuoteModel quote) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(quote: quote),
      ),
    );
  }

  Future<void> _rejectQuote(String quoteId) async {
    try {
      await FirebaseFirestore.instance
          .collection('quotes')
          .doc(quoteId)
          .update({
        'status': 'rejected',
        'updated_at': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Quote declined');
      _loadQuotes();
    } catch (e) {
      _showErrorSnackBar('Failed to decline quote: ${e.toString()}');
    }
  }

  Color _getQuoteStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
