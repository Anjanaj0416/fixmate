// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> createNotification({
    FirebaseFirestore? firestore,
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String priority = 'medium',
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;

    await db.collection('notifications').doc().set({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data ?? {},
      'priority': priority,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
