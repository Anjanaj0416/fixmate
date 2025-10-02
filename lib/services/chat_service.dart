// lib/services/chat_service.dart
// ENHANCED VERSION - Added extensive debugging and proper error handling
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
}

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get customer chats with extensive logging
  static Stream<List<ChatRoom>> getCustomerChatsStream(String customerId) {
    print('🔍 Getting customer chats for ID: $customerId');

    return _firestore
        .collection('chat_rooms')
        .where('customer_id', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      print(
          '📊 Customer chats snapshot received: ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No chat rooms found for customer: $customerId');
        // Let's check if there are any chats at all
        _firestore.collection('chat_rooms').get().then((allChats) {
          print('📝 Total chat rooms in database: ${allChats.docs.length}');
          if (allChats.docs.isNotEmpty) {
            print('📝 Sample chat room customer_ids:');
            for (var doc in allChats.docs.take(5)) {
              var data = doc.data() as Map<String, dynamic>;
              print(
                  '   - Chat ${doc.id}: customer_id = ${data['customer_id']}');
            }
          }
        });
      } else {
        print('✅ Found ${snapshot.docs.length} chats for customer');
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          print(
              '   📨 Chat: ${doc.id}, Worker: ${data['worker_name']}, Last: ${data['last_message']}');
        }
      }

      // Get all chats
      List<ChatRoom> chats =
          snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();

      // Sort in memory by last_message_time (descending)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return chats;
    });
  }

  // Get worker chats with extensive logging
  static Stream<List<ChatRoom>> getWorkerChatsStream(String workerId) {
    print('🔍 Getting worker chats for ID: $workerId');

    return _firestore
        .collection('chat_rooms')
        .where('worker_id', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
      print(
          '📊 Worker chats snapshot received: ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No chat rooms found for worker: $workerId');
        // Let's check if there are any chats at all
        _firestore.collection('chat_rooms').get().then((allChats) {
          print('📝 Total chat rooms in database: ${allChats.docs.length}');
          if (allChats.docs.isNotEmpty) {
            print('📝 Sample chat room worker_ids:');
            for (var doc in allChats.docs.take(5)) {
              var data = doc.data() as Map<String, dynamic>;
              print('   - Chat ${doc.id}: worker_id = ${data['worker_id']}');
            }
          }
        });
      } else {
        print('✅ Found ${snapshot.docs.length} chats for worker');
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          print(
              '   📨 Chat: ${doc.id}, Customer: ${data['customer_name']}, Last: ${data['last_message']}');
        }
      }

      // Get all chats
      List<ChatRoom> chats =
          snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();

      // Sort in memory by last_message_time (descending)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return chats;
    });
  }

  // Create or get existing chat room
  static Future<String> createOrGetChatRoom({
    required String bookingId,
    required String customerId,
    required String customerName,
    required String workerId,
    required String workerName,
  }) async {
    try {
      print('🔍 Creating/getting chat room for booking: $bookingId');
      print('   Customer: $customerId ($customerName)');
      print('   Worker: $workerId ($workerName)');

      QuerySnapshot existing = await _firestore
          .collection('chat_rooms')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('✅ Found existing chat room: ${existing.docs.first.id}');
        return existing.docs.first.id;
      }

      print('📝 Creating new chat room...');
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

      print('✅ Created new chat room: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Send a message
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
    String? imageUrl,
  }) async {
    try {
      print('📤 Sending message to chat: $chatId');
      print('   From: $senderName ($senderType)');
      print(
          '   Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');

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

      String unreadField = senderType == 'worker'
          ? 'unread_count_customer'
          : 'unread_count_worker';

      await _firestore.collection('chat_rooms').doc(chatId).update({
        'last_message': StringUtils.truncate(message, 50),
        'last_message_time': FieldValue.serverTimestamp(),
        unreadField: FieldValue.increment(1),
      });

      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream for a chat
  static Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    print('🔍 Getting messages stream for chat: $chatId');

    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📊 Messages snapshot: ${snapshot.docs.length} messages');
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Get chat room details
  static Future<ChatRoom?> getChatRoom(String chatId) async {
    try {
      print('🔍 Getting chat room: $chatId');
      DocumentSnapshot doc =
          await _firestore.collection('chat_rooms').doc(chatId).get();

      if (doc.exists) {
        print('✅ Found chat room');
        return ChatRoom.fromFirestore(doc);
      }
      print('⚠️ Chat room not found');
      return null;
    } catch (e) {
      print('❌ Error getting chat room: $e');
      return null;
    }
  }

  // Get chat room by booking ID
  static Future<String?> getChatRoomByBookingId(String bookingId) async {
    try {
      print('🔍 Getting chat room by booking ID: $bookingId');
      QuerySnapshot snapshot = await _firestore
          .collection('chat_rooms')
          .where('booking_id', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('✅ Found chat room: ${snapshot.docs.first.id}');
        return snapshot.docs.first.id;
      }
      print('⚠️ No chat room found for booking');
      return null;
    } catch (e) {
      print('❌ Error getting chat room by booking: $e');
      return null;
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String userType,
  }) async {
    try {
      print('📖 Marking messages as read for chat: $chatId (user: $userType)');

      // Get all unread messages without filtering by sender
      QuerySnapshot unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .where('is_read', isEqualTo: false)
          .get();

      print('   Found ${unreadMessages.docs.length} unread messages');

      // Filter in memory to avoid complex Firestore query
      List<DocumentSnapshot> messagesToMark = unreadMessages.docs.where((doc) {
        String senderType = doc.get('sender_type') ?? '';
        return senderType != userType; // Only mark messages from the other user
      }).toList();

      if (messagesToMark.isEmpty) {
        print('✅ No unread messages to mark');
        return;
      }

      print('   Marking ${messagesToMark.length} messages as read');

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

      print('✅ Marked ${messagesToMark.length} messages as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
}
