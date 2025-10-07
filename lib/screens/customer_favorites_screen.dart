// lib/screens/customer_favorites_screen.dart
// MODIFIED VERSION - Added ONLY gradient background (white → light red)
// All original functionality preserved exactly as-is
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import 'worker_profile_view_screen.dart';

class CustomerFavoritesScreen extends StatefulWidget {
  @override
  _CustomerFavoritesScreenState createState() =>
      _CustomerFavoritesScreenState();
}

class _CustomerFavoritesScreenState extends State<CustomerFavoritesScreen> {
  bool _isLoading = true;
  List<WorkerModel> _favoriteWorkers = [];
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get customer document
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) throw Exception('Customer profile not found');

      Map<String, dynamic> customerData =
          customerDoc.data() as Map<String, dynamic>;

      _customerId = customerData['customer_id'] ?? user.uid;

      // Get favorite worker IDs
      List<String> favoriteWorkerIds =
          List<String>.from(customerData['favorite_workers'] ?? []);

      if (favoriteWorkerIds.isEmpty) {
        setState(() {
          _favoriteWorkers = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch worker details for each favorite
      _favoriteWorkers = [];
      for (String workerId in favoriteWorkerIds) {
        try {
          // Try by worker_id field first
          QuerySnapshot workerQuery = await FirebaseFirestore.instance
              .collection('workers')
              .where('worker_id', isEqualTo: workerId)
              .limit(1)
              .get();

          if (workerQuery.docs.isNotEmpty) {
            WorkerModel worker =
                WorkerModel.fromFirestore(workerQuery.docs.first);
            _favoriteWorkers.add(worker);
          } else {
            // Try by document ID
            DocumentSnapshot workerDoc = await FirebaseFirestore.instance
                .collection('workers')
                .doc(workerId)
                .get();

            if (workerDoc.exists) {
              WorkerModel worker = WorkerModel.fromFirestore(workerDoc);
              _favoriteWorkers.add(worker);
            }
          }
        } catch (e) {
          print('Error loading worker $workerId: $e');
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load favorites: ${e.toString()}');
    }
  }

  Future<void> _removeFromFavorites(String workerId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .update({
        'favorite_workers': FieldValue.arrayRemove([workerId])
      });

      setState(() {
        _favoriteWorkers.removeWhere((w) => w.workerId == workerId);
      });

      _showSuccessSnackBar('Removed from favorites');
    } catch (e) {
      _showErrorSnackBar('Failed to remove: ${e.toString()}');
    }
  }

  void _viewWorkerProfile(String workerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerProfileViewScreen(workerId: workerId),
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorite Workers'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      // ✅ ONLY CHANGE: Wrapped body in Container with gradient
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // White at top
              Color(0xFFFFE5E5), // Light red at bottom
            ],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.red))
            : _favoriteWorkers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _favoriteWorkers.length,
                    itemBuilder: (context, index) {
                      return _buildWorkerCard(_favoriteWorkers[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No favorite workers yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add workers to favorites after completed bookings',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(WorkerModel worker) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewWorkerProfile(worker.workerId ?? ''),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Worker avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.red[100],
                    child: Text(
                      worker.workerName.isNotEmpty
                          ? worker.workerName[0].toUpperCase()
                          : 'W',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Worker info
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
                                  ? '${worker.rating.toStringAsFixed(1)} rating'
                                  : 'No ratings yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Remove button
                  IconButton(
                    icon: Icon(Icons.favorite, color: Colors.red),
                    onPressed: () =>
                        _removeFromFavorites(worker.workerId ?? ''),
                    tooltip: 'Remove from favorites',
                  ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),

              // Service details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.work,
                      worker.serviceType.replaceAll('_', ' '),
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.location_on,
                      worker.location.city,
                      Colors.green,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.calendar_today,
                      '${worker.experienceYears} yrs exp',
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.payments,
                      'LKR ${worker.pricing.minimumChargeLkr.toStringAsFixed(0)}+',
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewWorkerProfile(worker.workerId ?? ''),
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Full Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
