// lib/screens/admin_manage_users_screen.dart
// FIXED VERSION - Added red unsuspend button with proper display
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
    return Column(
      children: [
        // Tab Selector
        Container(
          padding: EdgeInsets.all(16),
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
                        ? Color(0xFF2196F3)
                        : Colors.grey[300],
                    foregroundColor:
                        _selectedTab == 'workers' ? Colors.white : Colors.black,
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
              ? _buildCustomersList()
              : _buildWorkersList(),
        ),
      ],
    );
  }

  Widget _buildCustomersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No customers found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String name = data['name'] ?? 'Unknown';
            String customerId = data['customer_id'] ?? 'N/A';
            String email = data['email'] ?? 'No email';
            String phone = data['phone'] ?? 'No phone';
            bool isActive = data['status'] != 'suspended';

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.green : Colors.red,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: $customerId'),
                    Text('Email: $email'),
                    Text('Phone: $phone'),
                    SizedBox(height: 4),
                    Text(
                      'Status: ${isActive ? "Active" : "Suspended"}',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    _toggleUserStatus(doc.id, !isActive, 'customers');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.orange : Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(isActive ? 'Suspend' : 'Unsuspend'),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.engineering_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No workers found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String workerName = data['worker_name'] ?? 'Unknown';
            String workerId = data['worker_id'] ?? 'N/A';
            String email = data['email'] ?? 'No email';
            String serviceType = data['service_type'] ?? 'Unknown service';
            double rating = (data['rating'] ?? 0.0).toDouble();
            bool isActive = data['status'] != 'suspended';

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? Colors.blue : Colors.red,
                  child: Icon(
                    Icons.engineering,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  workerName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: $workerId'),
                    Text('Email: $email'),
                    Text('Service: ${serviceType.replaceAll('_', ' ')}'),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text('${rating.toStringAsFixed(1)}'),
                        SizedBox(width: 16),
                        Text(
                          'Status: ${isActive ? "Active" : "Suspended"}',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    _toggleUserStatus(doc.id, !isActive, 'workers');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.orange : Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(isActive ? 'Suspend' : 'Unsuspend'),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleUserStatus(
      String userId, bool isActive, String collection) async {
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
