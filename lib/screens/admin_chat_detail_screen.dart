// lib/screens/admin_chat_detail_screen.dart
// NEW FILE - Admin chat detail screen to respond to user support requests
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String userType;

  const AdminChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.userName,
    required this.userType,
  }) : super(key: key);

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      // Get all unread messages from user
      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .where('is_admin', isEqualTo: false)
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
          .doc(widget.chatId)
          .update({'unread_count_admin': 0});
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'message': message,
        'sender_id': 'admin',
        'sender_name': 'Admin Support',
        'is_admin': true,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      // Update last message in parent chat
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.chatId)
          .update({
        'last_message':
            message.length > 50 ? message.substring(0, 50) + '...' : message,
        'last_message_time': FieldValue.serverTimestamp(),
        'unread_count_user': FieldValue.increment(1),
      });

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            Text(
              '${widget.userType.toUpperCase()} Support',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(widget.chatId)
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
                      hintText: 'Type your response...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
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

  Widget _buildMessageBubble({
    required String message,
    required bool isAdmin,
    required String senderName,
    DateTime? timestamp,
  }) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isAdmin ? 50 : 0,
          right: isAdmin ? 0 : 50,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.deepPurple : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAdmin)
              Text(
                senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isAdmin ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (timestamp != null) ...[
              SizedBox(height: 4),
              Text(
                _formatMessageTime(timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isAdmin ? Colors.white70 : Colors.grey[600],
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
