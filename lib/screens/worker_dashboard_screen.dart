// lib/screens/worker_dashboard_screen.dart
// UPDATED VERSION - Added ratings and reviews section

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../screens/worker_profile_screen.dart';
import '../screens/worker_bookings_screen.dart';
import '../screens/worker_reviews_screen.dart';
import '../services/rating_service.dart';

class WorkerDashboardScreen extends StatefulWidget {
  @override
  _WorkerDashboardScreenState createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  WorkerModel? _worker;
  bool _isLoading = true;
  bool _isAvailable = true;
  Map<String, dynamic> _ratingStats = {};

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      print('📊 Loading worker data for user: ${user.uid}');

      // METHOD 1: Try loading by user UID (most reliable)
      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      if (workerDoc.exists) {
        print('✅ Found worker by UID');
        _worker = WorkerModel.fromFirestore(workerDoc);
        _isAvailable = _worker!.availability.availableToday;

        // Load rating stats
        _ratingStats = await RatingService.getWorkerRatingStats(
          _worker!.workerId!,
        );

        setState(() => _isLoading = false);
        return;
      }

      print('⚠️ Worker not found by UID, trying email query...');

      // METHOD 2: Fallback - try querying by email
      QuerySnapshot workerQuery = await FirebaseFirestore.instance
          .collection('workers')
          .where('contact.email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (workerQuery.docs.isNotEmpty) {
        print('✅ Found worker by email');
        _worker = WorkerModel.fromFirestore(workerQuery.docs.first);
        _isAvailable = _worker!.availability.availableToday;

        // Load rating stats
        _ratingStats = await RatingService.getWorkerRatingStats(
          _worker!.workerId!,
        );
      } else {
        print('❌ Worker document not found');
        throw Exception(
            'Worker profile not found. Please complete registration.');
      }
    } catch (e) {
      print('❌ Error loading worker data: $e');
      _showErrorSnackBar('Failed to load worker data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && _worker != null) {
        QuerySnapshot workerQuery = await FirebaseFirestore.instance
            .collection('workers')
            .where('worker_id', isEqualTo: _worker!.workerId)
            .limit(1)
            .get();

        if (workerQuery.docs.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('workers')
              .doc(workerQuery.docs.first.id)
              .update({
            'availability.available_today': !_isAvailable,
            'last_active': FieldValue.serverTimestamp(),
          });

          setState(() {
            _isAvailable = !_isAvailable;
          });

          _showSuccessSnackBar(_isAvailable
              ? 'You are now available for work'
              : 'You are now offline');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update availability: ${e.toString()}');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    } catch (e) {
      _showErrorSnackBar('Logout failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _worker == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Dashboard'),
        backgroundColor: Color(0xFFFF9800),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 16),
              _buildAvailabilityCard(),
              SizedBox(height: 16),
              _buildRatingsCard(),
              SizedBox(height: 16),
              _buildQuickStats(),
              SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFFF9800),
              child: Text(
                _worker!.firstName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _worker!.workerName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _worker!.serviceType,
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
                        '${_worker!.rating.toStringAsFixed(1)} (${_worker!.jobsCompleted} jobs)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFFFF9800)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                ).then((updated) {
                  if (updated == true) {
                    _loadWorkerData();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isAvailable ? Icons.check_circle : Icons.cancel,
              color: _isAvailable ? Colors.green : Colors.red,
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAvailable ? 'Available for Work' : 'Currently Offline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _isAvailable
                        ? 'You will receive booking requests'
                        : 'You won\'t receive booking requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isAvailable,
              onChanged: (value) => _toggleAvailability(),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsCard() {
    double averageRating = _ratingStats['average_rating'] ?? _worker!.rating;
    int totalReviews = _ratingStats['total_reviews'] ?? 0;
    Map<int, int> ratingBreakdown = _ratingStats['rating_breakdown'] ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerReviewsScreen(
                workerId: _worker!.workerId!,
                workerName: _worker!.workerName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  // Average rating display
                  Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.floor()
                                ? Icons.star
                                : (index < averageRating.ceil() &&
                                        averageRating % 1 != 0)
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Color(0xFFFF9800),
                            size: 20,
                          );
                        }),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 24),

                  // Rating breakdown
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        int stars = 5 - index;
                        int count = ratingBreakdown[stars] ?? 0;
                        double percentage =
                            totalReviews > 0 ? count / totalReviews : 0;

                        return Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                '$stars',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.star,
                                  size: 12, color: Color(0xFFFF9800)),
                              SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF9800),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 20,
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              if (totalReviews > 0) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap to view all customer reviews',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Jobs Completed',
            _worker!.jobsCompleted.toString(),
            Icons.work,
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Experience',
            '${_worker!.experienceYears} years',
            Icons.emoji_events,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'My Bookings',
              Icons.calendar_today,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerBookingsScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Reviews',
              Icons.star,
              Colors.amber,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerReviewsScreen(
                      workerId: _worker!.workerId!,
                      workerName: _worker!.workerName,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Profile',
              Icons.person,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerProfileScreen(worker: _worker!),
                  ),
                ).then((updated) {
                  if (updated == true) {
                    _loadWorkerData();
                  }
                });
              },
            ),
            _buildActionCard(
              'Settings',
              Icons.settings,
              Colors.grey,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
}
