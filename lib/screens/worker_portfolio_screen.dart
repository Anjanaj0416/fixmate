// lib/screens/worker_portfolio_screen.dart
// NEW FILE - Worker portfolio management with picture upload and notes
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/worker_model.dart';
import '../services/storage_service.dart';

class WorkerPortfolioScreen extends StatefulWidget {
  @override
  _WorkerPortfolioScreenState createState() => _WorkerPortfolioScreenState();
}

class _WorkerPortfolioScreenState extends State<WorkerPortfolioScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<PortfolioItem> _portfolioItems = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      if (workerDoc.exists) {
        Map<String, dynamic> data = workerDoc.data() as Map<String, dynamic>;
        List<PortfolioItem> items = [];

        if (data.containsKey('portfolio') && data['portfolio'] is List) {
          items = (data['portfolio'] as List)
              .map(
                  (item) => PortfolioItem.fromMap(item as Map<String, dynamic>))
              .toList();
        }

        setState(() {
          _portfolioItems = items;
        });
      }
    } catch (e) {
      print('❌ Error loading portfolio: $e');
      _showSnackBar('Failed to load portfolio', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPortfolioItem() async {
    try {
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show note input dialog
      String? note = await _showNoteDialog();
      if (note == null || note.trim().isEmpty) {
        _showSnackBar('Note is required', Colors.orange);
        return;
      }

      setState(() => _isUploading = true);

      // Upload image to Firebase Storage
      String imageUrl = await StorageService.uploadPortfolioPhoto(
        imageFile: image,
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create new portfolio item
      PortfolioItem newItem = PortfolioItem(
        imageUrl: imageUrl,
        note: note.trim(),
        uploadedAt: DateTime.now(),
      );

      // Update Firestore
      List<Map<String, dynamic>> portfolioData = [
        ..._portfolioItems.map((item) => item.toMap()),
        newItem.toMap(),
      ];

      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update({
        'portfolio': portfolioData,
      });

      setState(() {
        _portfolioItems.add(newItem);
      });

      _showSnackBar('Portfolio item added successfully!', Colors.green);
    } catch (e) {
      print('❌ Error adding portfolio item: $e');
      _showSnackBar('Failed to add portfolio item: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> _showNoteDialog() async {
    TextEditingController noteController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Describe this work...',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePortfolioItem(int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Portfolio Item'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Remove item from list
      _portfolioItems.removeAt(index);

      // Update Firestore
      List<Map<String, dynamic>> portfolioData =
          _portfolioItems.map((item) => item.toMap()).toList();

      await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .update({
        'portfolio': portfolioData,
      });

      _showSnackBar('Portfolio item deleted', Colors.green);
    } catch (e) {
      print('❌ Error deleting portfolio item: $e');
      _showSnackBar('Failed to delete item', Colors.red);
      await _loadPortfolio(); // Reload to restore state
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Portfolio', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : _buildPortfolioList(),
      floatingActionButton: _isUploading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _addPortfolioItem,
              backgroundColor: Colors.orange,
              icon: Icon(Icons.add_photo_alternate, color: Colors.white),
              label: Text('Add Work', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildPortfolioList() {
    if (_portfolioItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No portfolio items yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Add photos of your work to showcase your skills',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _portfolioItems.length,
      itemBuilder: (context, index) {
        final item = _portfolioItems[index];
        return _buildPortfolioCard(item, index);
      },
    );
  }

  Widget _buildPortfolioCard(PortfolioItem item, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () => _showFullImage(item.imageUrl),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                image: DecorationImage(
                  image: NetworkImage(item.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Note and actions
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.note,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(item.uploadedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePortfolioItem(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
