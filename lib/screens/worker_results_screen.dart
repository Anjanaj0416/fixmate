// lib/screens/worker_results_screen.dart
// COMPLETE FIXED VERSION - Replace entire file
// Added "See Pictures of the Issue" button functionality

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ml_service.dart';
import 'worker_detail_screen.dart';

class WorkerResultsScreen extends StatefulWidget {
  final List<MLWorker> workers;
  final AIAnalysis aiAnalysis;
  final String problemDescription;
  final List<String> problemImageUrls;

  const WorkerResultsScreen({
    Key? key,
    required this.workers,
    required this.aiAnalysis,
    required this.problemDescription,
    this.problemImageUrls = const [],
  }) : super(key: key);

  @override
  State<WorkerResultsScreen> createState() => _WorkerResultsScreenState();
}

class _WorkerResultsScreenState extends State<WorkerResultsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Recommended Workers', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Compact AI Analysis Summary
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfo(
                        Icons.location_on,
                        widget.aiAnalysis.userInputLocation,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactInfo(
                        Icons.build,
                        widget.aiAnalysis.servicePredictions.first.serviceType,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Problem Description Section
          if (widget.problemDescription.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problem Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.problemDescription,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: _isDescriptionExpanded ? null : 3,
                    overflow: _isDescriptionExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (widget.problemDescription.length > 100)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? 'Show less' : 'Read more',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  // ✅ ADDED: "See Pictures" button
                  if (widget.problemImageUrls.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: ElevatedButton.icon(
                        onPressed: _viewIssuePhotos,
                        icon: Icon(Icons.photo_library, size: 18),
                        label: Text('See Pictures of the Issue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Worker List
          Expanded(
            child: widget.workers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No workers found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: widget.workers.length,
                    itemBuilder: (context, index) {
                      return _buildWorkerCard(
                        context,
                        widget.workers[index],
                        index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ ADDED: Method to view issue photos
  void _viewIssuePhotos() {
    if (widget.problemImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No photos available for this issue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IssuePhotoViewerScreen(
          imageUrls: widget.problemImageUrls,
          problemDescription: widget.problemDescription,
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(BuildContext context, MLWorker worker, int rank) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showWorkerDetails(context, worker),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with rank badge and match percentage
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: rank == 1 ? Colors.amber : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rank == 1 ? '⭐ #$rank Best Match' : '#$rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '${worker.aiConfidence.toStringAsFixed(0)}% Match',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Worker Profile Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      worker.workerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                        SizedBox(height: 4),
                        Text(
                          _formatServiceType(worker.serviceType),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Stats Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.star,
                      '${worker.rating.toStringAsFixed(1)}',
                      Colors.amber,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      Icons.work,
                      '${worker.experienceYears} yrs',
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      Icons.location_on,
                      '${worker.distanceKm.toStringAsFixed(1)} km',
                      Colors.green,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Price
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'LKR ${worker.dailyWageLkr}/day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showWorkerDetails(context, worker),
                      icon: Icon(Icons.info_outline, size: 18),
                      label: Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _callWorker(context, worker),
                      icon: Icon(Icons.phone, size: 18),
                      label: Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showWorkerDetails(BuildContext context, MLWorker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDetailScreen(
          worker: worker,
          problemDescription: widget.problemDescription,
          problemImageUrls: widget.problemImageUrls,
        ),
      ),
    );
  }

  void _callWorker(BuildContext context, MLWorker worker) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: worker.phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar(context, 'Cannot make phone call');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatServiceType(String serviceType) {
    return serviceType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

// ✅ ADDED: New Issue Photo Viewer Screen
class IssuePhotoViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final String problemDescription;

  const IssuePhotoViewerScreen({
    Key? key,
    required this.imageUrls,
    required this.problemDescription,
  }) : super(key: key);

  @override
  State<IssuePhotoViewerScreen> createState() => _IssuePhotoViewerScreenState();
}

class _IssuePhotoViewerScreenState extends State<IssuePhotoViewerScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Issue Photos (${_currentImageIndex + 1}/${widget.imageUrls.length})',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Problem description banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              border: Border(
                bottom: BorderSide(color: Colors.blue.withOpacity(0.5)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Problem Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  widget.problemDescription,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Image viewer with zoom
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.blue,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 60, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Image navigation dots
          if (widget.imageUrls.length > 1)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentImageIndex
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
