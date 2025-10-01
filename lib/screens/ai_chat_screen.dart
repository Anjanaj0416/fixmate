// lib/screens/ai_chat_screen.dart
// FIXED VERSION - Gets location from Firebase user collection (nearestTown)
// Replace your existing ai_chat_screen.dart with this file

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/openai_service.dart';
import '../services/ml_service.dart';
import 'worker_results_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart'; // NEW - Add this
import 'enhanced_worker_selection_screen.dart'; // NEW - Add this

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final XFile? image;
  final bool showOptions;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.image,
    this.showOptions = false,
    this.isError = false,
  });
}

class AIChatScreen extends StatefulWidget {
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _lastProblemDescription;
  String? _userLocation; // Store user's nearest town

  @override
  void initState() {
    super.initState();
    _loadUserLocation(); // Load location on init
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your AI assistant. You can:\n\n'
          '📸 Upload a photo of any issue\n'
          '💬 Describe your problem in text\n\n'
          'I\'ll analyze it and help you find skilled workers or provide repair tips!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========== NEW METHOD: Load user location from Firebase ==========
  Future<void> _loadUserLocation() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not logged in');
        return;
      }

      // Get user document from Firebase
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userLocation = userData['nearestTown'];
        });
        print('✅ Loaded user location: $_userLocation');
      } else {
        print('❌ User document not found');
      }
    } catch (e) {
      print('❌ Error loading user location: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                    await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue),
              title: Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                  });
                }
              },
            ),
          ],
        ),
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

  Widget _buildImageWidget(XFile imageFile, double width, double height) {
    // Use Image.network for web, Image.file for mobile/desktop
    return FutureBuilder<dynamic>(
      future: _loadImageBytes(imageFile),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  // Load image as bytes (works on all platforms including web)
  Future<dynamic> _loadImageBytes(XFile imageFile) async {
    return await imageFile.readAsBytes();
  }

  void _sendMessage() async {
    String message = _messageController.text.trim();

    if (message.isEmpty && _selectedImage == null) return;

    setState(() {
      if (_selectedImage != null) {
        _messages.add(ChatMessage(
          text: message.isEmpty ? 'Analyzing image...' : message,
          isUser: true,
          timestamp: DateTime.now(),
          image: _selectedImage,
        ));
      } else {
        _messages.add(ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ));
      }
      _isLoading = true;
    });

    _messageController.clear();
    final imageToAnalyze = _selectedImage;
    setState(() {
      _selectedImage = null;
    });

    _scrollToBottom();

    try {
      String response;

      if (imageToAnalyze != null) {
        response = await OpenAIService.analyzeImageFromXFile(
          imageFile: imageToAnalyze,
          userMessage: message.isEmpty ? null : message,
        );

        // Store the problem description for ML model
        _lastProblemDescription = response;
      } else {
        response = await OpenAIService.sendMessage(message);
      }

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          showOptions:
              imageToAnalyze != null, // Show options only for image analysis
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // ========== MODIFIED: Show location dialog with pre-filled saved location ==========
  Future<void> _findWorkers() async {
    if (_lastProblemDescription == null) {
      _showErrorSnackBar('No problem description available');
      return;
    }

    // Show location dialog
    String? location = await _showLocationDialog();
    if (location == null || location.isEmpty) {
      _showErrorSnackBar('Location is required to find workers');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NEW: Upload photo to Firebase Storage if there's an image
      List<String> uploadedPhotoUrls = [];

      // Check if there's an image in the last message
      for (var message in _messages.reversed) {
        if (message.isUser && message.image != null) {
          // Show upload progress
          setState(() {
            _messages.add(ChatMessage(
              text: '📤 Uploading photo to secure storage...',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();

          try {
            // Upload the photo
            String photoUrl = await StorageService.uploadIssuePhoto(
              imageFile: message.image!,
            );
            uploadedPhotoUrls.add(photoUrl);
            print('✅ Photo uploaded: $photoUrl');

            // Show success message
            setState(() {
              _messages.add(ChatMessage(
                text: '✅ Photo uploaded successfully!',
                isUser: false,
                timestamp: DateTime.now(),
              ));
            });
            _scrollToBottom();
          } catch (e) {
            print('❌ Photo upload failed: $e');
            _showErrorSnackBar('Failed to upload photo, continuing without it');
          }

          break; // Only upload the most recent image
        }
      }

      setState(() => _isLoading = false);

      // Navigate to worker selection with uploaded photo URLs
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedWorkerSelectionScreen(
            serviceType: 'general_services',
            subService: 'maintenance',
            issueType: 'general',
            problemDescription: _lastProblemDescription!,
            problemImageUrls: uploadedPhotoUrls, // ✅ Now contains actual URLs
            location: location,
            address: location,
            urgency: 'normal',
            budgetRange: 'negotiable',
            scheduledDate: DateTime.now().add(Duration(days: 1)),
            scheduledTime: '09:00 AM',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Failed to process request: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // ========== NEW: Location dialog with pre-filled saved location ==========
  Future<String?> _showLocationDialog() async {
    final TextEditingController locationController = TextEditingController();

    // Pre-fill with saved location from Firebase
    if (_userLocation != null && _userLocation!.isNotEmpty) {
      locationController.text = _userLocation!;
    }

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your city or area:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'e.g., Colombo, Kandy, Galle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 8),
              Text(
                'Popular locations: Colombo, Kandy, Galle, Negombo, Jaffna, Gampaha',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String location = locationController.text.trim();
                if (location.isNotEmpty) {
                  Navigator.of(context).pop(location);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a location'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Search', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _handleGetRepairTips() {
    setState(() {
      _messages.add(ChatMessage(
        text: 'Getting repair tips for your issue...',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    // Request repair tips from OpenAI
    _sendRepairTipsRequest();
  }

  Future<void> _sendRepairTipsRequest() async {
    if (_lastProblemDescription == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await OpenAIService.sendMessage(
        'Based on this problem: "$_lastProblemDescription", '
        'provide step-by-step repair tips that a homeowner can try. '
        'Include safety warnings if necessary.',
      );

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Failed to get repair tips: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Image preview
          if (_selectedImage != null)
            Container(
              margin: EdgeInsets.all(8),
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(
                      _selectedImage!,
                      double.infinity,
                      120,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_photo_alternate, color: Colors.blue),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.blue
              : (message.isError ? Colors.red[50] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(
                  message.image!,
                  double.infinity,
                  200,
                ),
              ),
              if (message.text.isNotEmpty) SizedBox(height: 8),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),

            // Show action buttons for AI responses with problem descriptions
            if (message.showOptions && !message.isUser) ...[
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _findWorkers,
                    icon: Icon(Icons.person_search, size: 18),
                    label: Text('Find Skilled Workers'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _handleGetRepairTips,
                    icon: Icon(Icons.tips_and_updates, size: 18),
                    label: Text('Get Repair Tips'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
