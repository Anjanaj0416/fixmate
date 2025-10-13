// lib/screens/ai_chat_screen.dart
// ENHANCED VERSION - Both photo upload and text description supported
// Replace the entire file with this version

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/openai_service.dart';
import '../services/ml_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import 'worker_results_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final XFile? image;
  final bool showFindWorkersButton; // Show button for both photo and text
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.image,
    this.showFindWorkersButton = false,
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
  String? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
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

  Future<void> _loadUserLocation() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not logged in');
        return;
      }

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

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    XFile? imageToAnalyze = _selectedImage;

    // Must have either text or image
    if (message.isEmpty && imageToAnalyze == null) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: message.isEmpty ? 'Analyzing image...' : message,
        isUser: true,
        timestamp: DateTime.now(),
        image: imageToAnalyze,
      ));
      _messageController.clear();
      _selectedImage = null;
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      String response;

      // OPTION A: Image Upload Flow
      if (imageToAnalyze != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: '🔍 Analyzing image...',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();

        response = await OpenAIService.analyzeImageFromXFile(
          imageFile: imageToAnalyze,
          userMessage: message.isNotEmpty
              ? message
              : 'What issue do you see in this image? Provide a detailed description.',
        );

        _lastProblemDescription = response;

        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
            showFindWorkersButton: true, // Show button for image analysis
          ));
        });
      }
      // OPTION B: Text Description Flow
      else {
        // Check if this looks like a problem description
        bool isProblemDescription = _isProblemDescription(message);

        response = await OpenAIService.sendMessage(message);

        if (isProblemDescription) {
          _lastProblemDescription = message; // Store the user's description

          setState(() {
            _messages.add(ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
              showFindWorkersButton: true, // Show button for text description
            ));
          });
        } else {
          setState(() {
            _messages.add(ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
        }
      }

      setState(() {
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

  // Helper to detect if message is a problem description
  bool _isProblemDescription(String text) {
    text = text.toLowerCase();

    // Keywords that indicate a problem description
    List<String> problemKeywords = [
      'leak',
      'broken',
      'not working',
      'issue',
      'problem',
      'fix',
      'repair',
      'damage',
      'crack',
      'block',
      'clog',
      'stuck',
      'loose',
      'fault',
      'malfunction',
      'defect',
      'error',
      'water',
      'pipe',
      'toilet',
      'sink',
      'faucet',
      'shower',
      'electrical',
      'wiring',
      'switch',
      'outlet',
      'light',
      'plumbing',
      'drain',
      'heating',
      'cooling',
      'ac',
      'hvac',
      'roof',
      'ceiling',
      'wall',
      'floor',
      'door',
      'window',
      'paint',
      'carpenter',
      'electrician',
      'plumber',
      'help',
      'need',
      'urgent'
    ];

    return problemKeywords.any((keyword) => text.contains(keyword));
  }

  // Main worker finding function - works for both photo and text
  Future<void> _findWorkers() async {
    if (_lastProblemDescription == null) {
      _showErrorSnackBar('No problem description available');
      return;
    }

    String? location = await _showLocationDialog();
    if (location == null || location.isEmpty) {
      _showErrorSnackBar('Location is required to find workers');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Upload photos if any exist in the conversation
      List<String> uploadedPhotoUrls = [];

      for (var message in _messages.reversed) {
        if (message.isUser && message.image != null) {
          setState(() {
            _messages.add(ChatMessage(
              text: '📤 Uploading photo to secure storage...',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();

          try {
            String photoUrl = await StorageService.uploadIssuePhoto(
              imageFile: message.image!,
            );
            uploadedPhotoUrls.add(photoUrl);
            print('✅ Photo uploaded: $photoUrl');

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

          break;
        }
      }

      // Step 2: Use ML model to predict service type and find workers
      setState(() {
        _messages.add(ChatMessage(
          text: '🤖 Analyzing your issue to find the best workers...',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();

      print('🔍 Using ML model to predict service type...');
      print('📝 Description: $_lastProblemDescription');
      print('📍 Location: $location');

      // Call ML service
      MLRecommendationResponse mlResponse = await MLService.searchWorkers(
        description: _lastProblemDescription!,
        location: location,
      );

      print('✅ ML Analysis complete!');
      print(
          '📊 Predicted service: ${mlResponse.aiAnalysis.servicePredictions.first.serviceType}');
      print(
          '📊 Confidence: ${(mlResponse.aiAnalysis.servicePredictions.first.confidence * 100).toStringAsFixed(1)}%');

      setState(() => _isLoading = false);

      // Navigate to worker results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerResultsScreen(
            workers: mlResponse.workers,
            aiAnalysis: mlResponse.aiAnalysis,
            problemDescription: _lastProblemDescription!,
            problemImageUrls: uploadedPhotoUrls,
          ),
        ),
      );

      setState(() {
        _messages.add(ChatMessage(
          text:
              '✅ Found ${mlResponse.workers.length} workers matching your needs!\n'
              '🔧 Service: ${_formatServiceType(mlResponse.aiAnalysis.servicePredictions.first.serviceType)}\n'
              '📍 Location: $location',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ Error finding workers: $e');
      setState(() {
        _messages.add(ChatMessage(
          text:
              'Failed to find workers: ${e.toString()}\n\nPlease make sure the ML service is running on http://localhost:8000',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _formatServiceType(String serviceType) {
    return serviceType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<String?> _showLocationDialog() async {
    TextEditingController locationController =
        TextEditingController(text: _userLocation ?? '');

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please confirm your location to find nearby workers:'),
            SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Colombo, Kandy, Galle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
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
              Navigator.pop(context, locationController.text.trim());
            },
            child: Text('Confirm'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('AI Assistant', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(_selectedImage!, 60, 60),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Image selected',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.blue),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message or describe your issue...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
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
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? Colors.red[100]
                        : message.isUser
                            ? Colors.blue
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.image != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(message.image!, 200, 200),
                        ),
                        SizedBox(height: 8),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (message.showFindWorkersButton) ...[
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _findWorkers,
                    icon: Icon(Icons.search),
                    label: Text('Find Skilled Workers'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to build image widget (works on web and mobile)
  Widget _buildImageWidget(XFile imageFile, double width, double height) {
    return FutureBuilder<Uint8List>(
      future: imageFile.readAsBytes(),
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
}
