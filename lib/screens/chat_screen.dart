// lib/screens/chat_screen.dart
// MODIFIED VERSION - Updated background gradient and chat bubble colors
// Background: Soft light-orange and white gradient (white at top → light orange at bottom)
// Customer chat: Light orange
// Worker chat: Orange

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String bookingId;
  final String otherUserName;
  final String currentUserType; // 'customer' or 'worker'

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.bookingId,
    required this.otherUserName,
    required this.currentUserType,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? _currentUser;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUserName();

    // Debug logging
    print('💬 ChatScreen initialized');
    print('   Chat ID: ${widget.chatId}');
    print('   Booking ID: ${widget.bookingId}');
    print('   Other User: ${widget.otherUserName}');
    print('   Current User Type: ${widget.currentUserType}');

    // Mark messages as read when opening chat
    ChatService.markMessagesAsRead(
      chatId: widget.chatId,
      userType: widget.currentUserType,
    );
  }

  Future<void> _loadUserName() async {
    setState(() {
      _currentUserName = _currentUser?.displayName ??
          (widget.currentUserType == 'customer' ? 'Customer' : 'Worker');
    });
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      print('📤 Sending message...');
      print('   Chat ID: ${widget.chatId}');
      print(
          '   Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');

      await ChatService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUser!.uid,
        senderName: _currentUserName ?? widget.currentUserType,
        senderType: widget.currentUserType,
        message: message,
      );

      _messageController.clear();
      print('✅ Message sent successfully');

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      _showErrorSnackBar('Failed to send message: $e');
    }
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
    // Set app bar color based on user type
    Color appBarColor =
        widget.currentUserType == 'customer' ? Colors.blue : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Text(
              'Booking #${widget.bookingId.substring(0, 8)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      // 🎨 NEW: Soft light-orange and white gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // White at top
              Color(0xFFFFE5CC), // Soft light orange at bottom
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.getMessagesStream(widget.chatId),
                builder: (context, snapshot) {
                  print('📊 StreamBuilder update:');
                  print('   Connection State: ${snapshot.connectionState}');
                  print('   Has Data: ${snapshot.hasData}');
                  print('   Has Error: ${snapshot.hasError}');

                  if (snapshot.hasError) {
                    print('   Error: ${snapshot.error}');
                  }

                  if (snapshot.hasData) {
                    print('   Message Count: ${snapshot.data!.length}');
                    // Log each message
                    for (var i = 0; i < snapshot.data!.length; i++) {
                      var msg = snapshot.data![i];
                      print(
                          '   Message $i: ${msg.senderName} (${msg.senderType}): ${msg.message.substring(0, msg.message.length > 30 ? 30 : msg.message.length)}...');
                    }
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading messages...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading messages',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print('⚠️ No messages to display');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  List<ChatMessage> messages = snapshot.data!;
                  print('✅ Rendering ${messages.length} messages');

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      ChatMessage message = messages[index];
                      bool isMe = message.senderType == widget.currentUserType;

                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              padding: EdgeInsets.all(8),
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
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: widget.currentUserType == 'customer'
                          ? Colors.blue
                          : Colors.orange,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    // 🎨 NEW: Determine bubble color based on sender type
    Color bubbleColor;
    Color textColor;

    if (isMe) {
      // Current user's message
      if (widget.currentUserType == 'customer') {
        // Customer's own message: light orange
        bubbleColor = Color(0xFFFFCC99); // Light orange
        textColor = Colors.black87;
      } else {
        // Worker's own message: orange
        bubbleColor = Colors.orange;
        textColor = Colors.white;
      }
    } else {
      // Other person's message
      if (widget.currentUserType == 'customer') {
        // Customer viewing worker's message: orange
        bubbleColor = Colors.orange;
        textColor = Colors.white;
      } else {
        // Worker viewing customer's message: light orange
        bubbleColor = Color(0xFFFFCC99); // Light orange
        textColor = Colors.black87;
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name (only show for messages from other person)
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Message bubble
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: bubbleColor, // 🎨 NEW: Use calculated bubble color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: textColor, // 🎨 NEW: Use calculated text color
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: textColor
                          .withOpacity(0.7), // 🎨 NEW: Adjust time text color
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    String minuteStr = minute.toString().padLeft(2, '0');

    return '$hour:$minuteStr $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
