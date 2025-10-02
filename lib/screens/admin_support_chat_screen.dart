// lib/screens/admin_support_chat_screen.dart
// NEW FILE - Chat between user and admin for support
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSupportChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userType; // 'customer' or 'worker'

  const AdminSupportChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userType,
  }) : super(key: key);

  @override
  State<AdminSupportChatScreen> createState() => _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState extends State<AdminSupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _supportChatId;

  @override
  void initState() {
    super.initState();
    _createOrGetSupportChat();
  }

  Future<void> _createOrGetSupportChat() async {
    try {
      // Check if support chat already exists
      QuerySnapshot existingChat = await FirebaseFirestore.instance
          .collection('support_chats')
          .where('user_id', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        setState(() {
          _supportChatId = existingChat.docs.first.id;
        });
      } else {
        // Create new support chat
        DocumentReference chatRef =
            await FirebaseFirestore.instance.collection('support_chats').add({
          'user_id': widget.userId,
          'user_name': widget.userName,
          'user_type': widget.userType,
          'last_message': 'Chat started',
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count_user': 0,
          'unread_count_admin': 0,
          'status': 'active',
          'created_at': FieldValue.serverTimestamp(),
        });

        setState(() {
          _supportChatId = chatRef.id;
        });

        // Send welcome message
        await _sendMessage(
          'Hello! How can we help you today?',
          isAdmin: true,
        );
      }

      // Mark messages as read when opening chat
      _markMessagesAsRead();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading support chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_supportChatId == null) return;

    try {
      // Get all unread messages from admin
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .where('is_admin', isEqualTo: true)
          .get();

      // Mark them as read
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();

      // Reset unread count
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .update({'unread_count_user': 0});
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage(String message, {bool isAdmin = false}) async {
    if (_supportChatId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .collection('messages')
          .add({
        'message': message,
        'sender_id': isAdmin ? 'admin' : widget.userId,
        'sender_name': isAdmin ? 'Admin Support' : widget.userName,
        'is_admin': isAdmin,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      // Update last message in parent chat
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(_supportChatId)
          .update({
        'last_message':
            message.length > 50 ? message.substring(0, 50) + '...' : message,
        'last_message_time': FieldValue.serverTimestamp(),
        if (!isAdmin) 'unread_count_admin': FieldValue.increment(1),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSendMessage() {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    _sendMessage(message);
    _messageController.clear();

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_supportChatId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Admin Support'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Support'),
            Text(
              'Get help from our team',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(_supportChatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    bool isAdmin = data['is_admin'] ?? false;
                    String message = data['message'] ?? '';
                    String senderName = data['sender_name'] ?? 'Unknown';
                    Timestamp? timestamp = data['timestamp'] as Timestamp?;

                    return _buildMessageBubble(
                      message: message,
                      isAdmin: isAdmin,
                      senderName: senderName,
                      timestamp: timestamp?.toDate(),
                    );
                  },
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isAdmin,
    required String senderName,
    DateTime? timestamp,
  }) {
    bool isCurrentUser = !isAdmin;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isCurrentUser ? 50 : 0,
          right: isCurrentUser ? 0 : 50,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (timestamp != null) ...[
              SizedBox(height: 4),
              Text(
                _formatMessageTime(timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
