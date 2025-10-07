// lib/screens/admin_manage_users_screen.dart
// MODIFIED VERSION - Added gradient background, removed back button, changed title
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManageUsersScreen extends StatefulWidget {
  @override
  _AdminManageUsersScreenState createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  String _selectedTab = 'customers';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.lightGreen.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          // Manage Users Title
          Container(
            padding: EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Manage Users',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),

          // Tab Selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 'customers'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _selectedTab == 'customers'
                          ? Color(0xFF2196F3)
                          : Colors.grey[300],
                      foregroundColor: _selectedTab == 'customers'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: Text('Customers'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 'workers'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _selectedTab == 'workers'
                          ? Colors.orange
                          : Colors.grey[300],
                      foregroundColor: _selectedTab == 'workers'
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: Text('Workers'),
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: _selectedTab == 'customers'
                ? _buildCustomerList()
                : _buildWorkerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No customers found'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var customer = snapshot.data!.docs[index];
            Map<String, dynamic> data = customer.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF2196F3),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  data['name'] ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(data['email'] ?? 'No email'),
                    Text('Phone: ${data['phone'] ?? 'N/A'}'),
                    Text('City: ${data['city'] ?? 'N/A'}'),
                  ],
                ),
                trailing: _buildUserStatusButton(
                  customer.id,
                  'customers',
                  data['status'] != 'suspended',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkerList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workers')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No workers found'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var worker = snapshot.data!.docs[index];
            Map<String, dynamic> data = worker.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.construction, color: Colors.white),
                ),
                title: Text(
                  data['name'] ?? 'Unknown',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(data['email'] ?? 'No email'),
                    Text('Service: ${data['serviceType'] ?? 'N/A'}'),
                    Text('Phone: ${data['phone'] ?? 'N/A'}'),
                    Text('City: ${data['city'] ?? 'N/A'}'),
                  ],
                ),
                trailing: _buildUserStatusButton(
                  worker.id,
                  'workers',
                  data['status'] != 'suspended',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserStatusButton(
      String userId, String collection, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          ElevatedButton(
            onPressed: () => _toggleUserStatus(userId, collection, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Suspend',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          )
        else
          ElevatedButton(
            onPressed: () => _toggleUserStatus(userId, collection, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Unsuspend',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _toggleUserStatus(
      String userId, String collection, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update({
        'status': isActive ? 'active' : 'suspended',
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'User activated successfully'
                : 'User suspended successfully',
          ),
          backgroundColor: isActive ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
