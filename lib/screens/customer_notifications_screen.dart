// lib/screens/customer_notifications_screen.dart
// FIXED VERSION - Removed orderBy to avoid composite index requirement
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  @override
  _CustomerNotificationsScreenState createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _customerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerId();
  }

  Future<void> _loadCustomerId() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot customerDoc =
            await _firestore.collection('customers').doc(user.uid).get();

        if (customerDoc.exists) {
          Map<String, dynamic> customerData =
              customerDoc.data() as Map<String, dynamic>;
          setState(() {
            _customerId = customerData['customer_id'] ?? user.uid;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading customer ID: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      if (_customerId == null) return;

      // Query for notifications where recipient_type is 'customer' and read is false
      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipient_type', isEqualTo: 'customer')
          .where('read', isEqualTo: false)
          .get();

      // Filter for this specific customer
      List<DocumentSnapshot> customerNotifications =
          unreadNotifications.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String? customerId = data['customer_id'];
        String? recipientId = data['recipient_id'];
        return customerId == _customerId || recipientId == _customerId;
      }).toList();

      if (customerNotifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No unread notifications'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (var doc in customerNotifications) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notifications as read'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_customerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Could not load notifications',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIXED: Removed orderBy to avoid composite index requirement
        // We'll sort the data locally after filtering
        stream: _firestore
            .collection('notifications')
            .where('recipient_type', isEqualTo: 'customer')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you have updates',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Filter notifications for this customer
          List<DocumentSnapshot> allNotifications = snapshot.data!.docs;
          List<DocumentSnapshot> notifications = allNotifications.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            // Check both customer_id and recipient_id fields
            String? customerId = data['customer_id'];
            String? recipientId = data['recipient_id'];
            return customerId == _customerId || recipientId == _customerId;
          }).toList();

          // FIXED: Sort locally by created_at timestamp (newest first)
          notifications.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;

            Timestamp? timestampA = dataA['created_at'] as Timestamp?;
            Timestamp? timestampB = dataB['created_at'] as Timestamp?;

            // Handle null timestamps (put them at the end)
            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) return 1;
            if (timestampB == null) return -1;

            // Sort descending (newest first)
            return timestampB.compareTo(timestampA);
          });

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you have updates',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification =
                  notifications[index].data() as Map<String, dynamic>;
              String notificationId = notifications[index].id;
              bool isRead = notification['read'] ?? false;
              String type = notification['type'] ?? 'general';
              String title = notification['title'] ?? 'Notification';
              String message = notification['message'] ?? '';
              Timestamp? createdAt = notification['created_at'] as Timestamp?;

              // Format timestamp
              String timeAgo = 'Just now';
              if (createdAt != null) {
                DateTime dateTime = createdAt.toDate();
                Duration difference = DateTime.now().difference(dateTime);

                if (difference.inDays > 7) {
                  timeAgo = DateFormat('MMM d, yyyy').format(dateTime);
                } else if (difference.inDays > 0) {
                  timeAgo = '${difference.inDays}d ago';
                } else if (difference.inHours > 0) {
                  timeAgo = '${difference.inHours}h ago';
                } else if (difference.inMinutes > 0) {
                  timeAgo = '${difference.inMinutes}m ago';
                }
              }

              // Get icon and color based on notification type
              IconData icon;
              Color iconColor;

              switch (type) {
                case 'new_booking':
                  icon = Icons.calendar_today;
                  iconColor = Colors.blue;
                  break;
                case 'booking_status_update':
                  icon = Icons.update;
                  iconColor = Colors.orange;
                  break;
                case 'booking_accepted':
                  icon = Icons.check_circle;
                  iconColor = Colors.green;
                  break;
                case 'booking_declined':
                  icon = Icons.cancel;
                  iconColor = Colors.red;
                  break;
                case 'booking_cancelled':
                  icon = Icons.cancel_outlined;
                  iconColor = Colors.red;
                  break;
                case 'message':
                  icon = Icons.message;
                  iconColor = Colors.purple;
                  break;
                default:
                  icon = Icons.notifications;
                  iconColor = Colors.grey;
              }

              return Dismissible(
                key: Key(notificationId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete Notification'),
                        content: Text(
                            'Are you sure you want to delete this notification?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  _deleteNotification(notificationId);
                },
                child: Card(
                  elevation: isRead ? 0 : 2,
                  color: isRead ? Colors.grey[100] : Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notificationId);
                      }
                      // TODO: Navigate to relevant screen based on notification type
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),
                          SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
