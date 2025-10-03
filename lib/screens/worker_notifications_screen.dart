// lib/screens/worker_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerNotificationsScreen extends StatefulWidget {
  @override
  _WorkerNotificationsScreenState createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _workerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerId();
  }

  Future<void> _loadWorkerId() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot workerDoc =
            await _firestore.collection('workers').doc(user.uid).get();

        if (workerDoc.exists) {
          Map<String, dynamic> workerData =
              workerDoc.data() as Map<String, dynamic>;
          setState(() {
            _workerId = workerData['worker_id'] ?? user.uid;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading worker ID: $e');
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
      if (_workerId == null) return;

      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipient_type', isEqualTo: 'worker')
          .where('read', isEqualTo: false)
          .get();

      List<DocumentSnapshot> workerNotifications =
          unreadNotifications.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        String? workerId = data['worker_id'];
        String? recipientId = data['recipient_id'];
        return workerId == _workerId || recipientId == _workerId;
      }).toList();

      if (workerNotifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No unread notifications'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (var doc in workerNotifications) {
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
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_workerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text('Unable to load worker profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: Color(0xFFFF9800),
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
        stream: _firestore
            .collection('notifications')
            .where('recipient_type', isEqualTo: 'worker')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Filter notifications for this worker
          List<QueryDocumentSnapshot> allDocs = snapshot.data!.docs;
          List<QueryDocumentSnapshot> workerDocs = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String? workerId = data['worker_id'];
            String? recipientId = data['recipient_id'];
            return workerId == _workerId || recipientId == _workerId;
          }).toList();

          // Sort by timestamp
          workerDocs.sort((a, b) {
            Timestamp? aTime = (a.data() as Map<String, dynamic>)['created_at'];
            Timestamp? bTime = (b.data() as Map<String, dynamic>)['created_at'];
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          if (workerDocs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: workerDocs.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              DocumentSnapshot doc = workerDocs[index];
              String notificationId = doc.id;
              Map<String, dynamic> notification =
                  doc.data() as Map<String, dynamic>;

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
                  margin: EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notificationId);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                          color: Color(0xFFFF9800),
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
                                SizedBox(height: 8),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when customers\nrequest your services',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
