// lib/services/chat_service.dart
// REPLACE YOUR EXISTING chat_service.dart WITH THIS VERSION
// This version avoids the complex query that requires an index

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/string_utils.dart';

class ChatMessage {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer' or 'worker'
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      messageId: doc.id,
      chatId: data['chat_id'] ?? '',
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderType: data['sender_type'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
      imageUrl: data['image_url'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': isRead,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class ChatRoom {
  final String chatId;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String workerId;
  final String workerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCountCustomer;
  final int unreadCountWorker;
  final DateTime createdAt;

  ChatRoom({
    required this.chatId,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.workerId,
    required this.workerName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCountCustomer = 0,
    this.unreadCountWorker = 0,
    required this.createdAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      chatId: doc.id,
      bookingId: data['booking_id'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      workerId: data['worker_id'] ?? '',
      workerName: data['worker_name'] ?? '',
      lastMessage: data['last_message'] ?? '',
      lastMessageTime:
          (data['last_message_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCountCustomer: data['unread_count_customer'] ?? 0,
      unreadCountWorker: data['unread_count_worker'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'booking_id': bookingId,
      'customer_id': customerId,
      'customer_name': customerName,
      'worker_id': workerId,
      'worker_name': workerName,
      'last_message': lastMessage,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_customer': unreadCountCustomer,
      'unread_count_worker': unreadCountWorker,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or get existing chat room for a booking
  static Future<String> createOrGetChatRoom({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
  }) async {
    try {
      // Check if chat room already exists for this booking
      QuerySnapshot existingChat = await _firestore
          .collection('chat_rooms')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat room
      DocumentReference chatRef =
          await _firestore.collection('chat_rooms').add({
        'booking_id': bookingId,
        'customer_id': customerId,
        'customer_name': customerName,
        'worker_id': workerId,
        'worker_name': workerName,
        'last_message': 'Chat started',
        'last_message_time': FieldValue.serverTimestamp(),
        'unread_count_customer': 0,
        'unread_count_worker': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('✅ Chat room created: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  /// Send a message
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
    String? imageUrl,
  }) async {
    try {
      // Add message to messages subcollection
      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .add({
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_type': senderType,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        if (imageUrl != null) 'image_url': imageUrl,
      });

      // Update chat room last message and unread count
      String unreadField = senderType == 'customer'
          ? 'unread_count_worker'
          : 'unread_count_customer';

      await _firestore.collection('chat_rooms').doc(chatId).update({
        'last_message': StringUtils.truncate(message, 50),
        'last_message_time': FieldValue.serverTimestamp(),
        unreadField: FieldValue.increment(1),
      });

      print('✅ Message sent to chat: $chatId');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get messages stream for a chat
  static Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Get chat room details
  static Future<ChatRoom?> getChatRoom(String chatId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('chat_rooms').doc(chatId).get();

      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  /// Get chat room by booking ID
  static Future<String?> getChatRoomByBookingId(String bookingId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chat_rooms')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error getting chat room by booking: $e');
      return null;
    }
  }

  /// Mark messages as read - SIMPLIFIED VERSION (No complex query, no index needed)
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String userType,
  }) async {
    try {
      // SIMPLIFIED: Just get all unread messages without complex filtering
      QuerySnapshot unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .get();

      // Filter in memory to avoid complex Firestore query
      List<DocumentSnapshot> messagesToMark = unreadMessages.docs.where((doc) {
        String senderType = doc.get('sender_type') ?? '';
        return senderType != userType; // Only mark messages from the other user
      }).toList();

      if (messagesToMark.isEmpty) {
        print('✅ No unread messages to mark');
        return;
      }

      // Mark each message as read using batch
      WriteBatch batch = _firestore.batch();
      for (var doc in messagesToMark) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();

      // Reset unread count
      String unreadField = userType == 'customer'
          ? 'unread_count_customer'
          : 'unread_count_worker';

      await _firestore.collection('chat_rooms').doc(chatId).update({
        unreadField: 0,
      });

      print(
          '✅ Marked ${messagesToMark.length} messages as read in chat: $chatId');
    } catch (e) {
      print('⚠️  Error marking messages as read: $e');
      // Non-critical error, just log it
    }
  }

  /// Get all chat rooms for a customer
  static Stream<List<ChatRoom>> getCustomerChatsStream(String customerId) {
    return _firestore
        .collection('chat_rooms')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  /// Get all chat rooms for a worker
  static Stream<List<ChatRoom>> getWorkerChatsStream(String workerId) {
    return _firestore
        .collection('chat_rooms')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }
}
