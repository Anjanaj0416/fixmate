// lib/screens/customer_notifications_screen.dart
// BEAUTIFIED VERSION - Blue theme with gradient background
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

      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipient_type', isEqualTo: 'customer')
          .where('read', isEqualTo: false)
          .get();

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
            backgroundColor: Colors.blue[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notifications as read'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.blue.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: AppBar(
            title: Text('Notifications'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.blue[800],
          ),
        ),
      );
    }

    if (_customerId == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.blue.shade50.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            children: [
              AppBar(
                title: Text('Notifications'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.blue[800],
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.blue[300]),
                      SizedBox(height: 16),
                      Text(
                        'Could not load notifications',
                        style: TextStyle(fontSize: 16, color: Colors.blue[700]),
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Text(
                'Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.blue[800],
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.done_all, color: Colors.blue[700]),
                    tooltip: 'Mark all as read',
                    onPressed: _markAllAsRead,
                  ),
                ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('notifications')
                    .where('recipient_type', isEqualTo: 'customer')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.blue[300]),
                          SizedBox(height: 16),
                          Text(
                            'Error loading notifications',
                            style: TextStyle(
                                fontSize: 16, color: Colors.blue[700]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue[400]),
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
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none,
                              size: 80,
                              color: Colors.blue[300],
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'You\'ll see notifications here when you have updates',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  List<DocumentSnapshot> allNotifications = snapshot.data!.docs;
                  List<DocumentSnapshot> notifications =
                      allNotifications.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String? customerId = data['customer_id'];
                    String? recipientId = data['recipient_id'];
                    return customerId == _customerId ||
                        recipientId == _customerId;
                  }).toList();

                  notifications.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    Timestamp? timestampA = dataA['created_at'] as Timestamp?;
                    Timestamp? timestampB = dataB['created_at'] as Timestamp?;
                    if (timestampA == null && timestampB == null) return 0;
                    if (timestampA == null) return 1;
                    if (timestampB == null) return -1;
                    return timestampB.compareTo(timestampA);
                  });

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none,
                              size: 80,
                              color: Colors.blue[300],
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'You\'ll see notifications here when you have updates',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      var notification =
                          notifications[index].data() as Map<String, dynamic>;
                      String notificationId = notifications[index].id;
                      bool isRead = notification['read'] ?? false;
                      String type = notification['type'] ?? 'general';
                      String title = notification['title'] ?? 'Notification';
                      String message = notification['message'] ?? '';
                      Timestamp? createdAt =
                          notification['created_at'] as Timestamp?;

                      IconData icon;
                      Color iconColor;

                      switch (type) {
                        case 'booking_confirmed':
                          icon = Icons.check_circle;
                          iconColor = Colors.blue[600]!;
                          break;
                        case 'booking_cancelled':
                          icon = Icons.cancel;
                          iconColor = Colors.blue[400]!;
                          break;
                        case 'worker_assigned':
                          icon = Icons.person_add;
                          iconColor = Colors.blue[700]!;
                          break;
                        case 'payment_received':
                          icon = Icons.payment;
                          iconColor = Colors.blue[600]!;
                          break;
                        case 'review_request':
                          icon = Icons.star;
                          iconColor = Colors.blue[500]!;
                          break;
                        default:
                          icon = Icons.notifications;
                          iconColor = Colors.blue[600]!;
                      }

                      return Dismissible(
                        key: Key(notificationId),
                        background: Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red[400]!, Colors.red[600]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child:
                              Icon(Icons.delete, color: Colors.white, size: 28),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Delete Notification',
                                  style: TextStyle(color: Colors.blue[900]),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this notification?',
                                  style: TextStyle(color: Colors.blue[700]),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.blue[600]),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red[600]),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteNotification(notificationId);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isRead
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey[50]!,
                                      Colors.grey[100]!,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.blue[50]!.withOpacity(0.5),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isRead
                                    ? Colors.grey.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isRead
                                  ? Colors.grey[200]!
                                  : Colors.blue[100]!,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(notificationId);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          iconColor.withOpacity(0.2),
                                          iconColor.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child:
                                        Icon(icon, color: iconColor, size: 24),
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.w700,
                                                  color: isRead
                                                      ? Colors.blue[700]
                                                      : Colors.blue[900],
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.blue[600]!,
                                                      Colors.blue[400]!,
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isRead
                                                ? Colors.grey[600]
                                                : Colors.blue[800],
                                            height: 1.4,
                                          ),
                                        ),
                                        if (createdAt != null) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            DateFormat('MMM dd, yyyy • hh:mm a')
                                                .format(createdAt.toDate()),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[400],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
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
            ),
          ],
        ),
      ),
    );
  }
}
