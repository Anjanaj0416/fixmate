// lib/screens/worker_admin_tools_screen.dart
// Main screen to access all worker debugging and cleanup tools

import 'package:flutter/material.dart';
import 'verify_worker_ids_screen.dart';
import 'cleanup_duplicate_workers_screen.dart';
import 'chat_diagnostic_screen.dart';

class WorkerAdminToolsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Admin Tools'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Header
          Card(
            color: Colors.deepPurple[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, color: Colors.deepPurple, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Admin Tools',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[900],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tools to diagnose and fix worker-related issues',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Section: Diagnostics
          Text(
            'DIAGNOSTICS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),

          // Tool 1: Verify Worker IDs
          _buildToolCard(
            context,
            icon: Icons.verified_user,
            iconColor: Colors.blue,
            title: 'Verify Worker IDs',
            description: 'Check if worker_ids are consistent across database',
            badge: 'SAFE',
            badgeColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifyWorkerIdsScreen(),
                ),
              );
            },
          ),

          SizedBox(height: 12),

          // Tool 2: Chat Diagnostics
          _buildToolCard(
            context,
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.orange,
            title: 'Chat Diagnostics',
            description: 'Diagnose why chats are not showing up',
            badge: 'SAFE',
            badgeColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDiagnosticScreen(),
                ),
              );
            },
          ),

          SizedBox(height: 24),

          // Section: Cleanup
          Text(
            'CLEANUP & FIXES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),

          // Tool 3: Cleanup Duplicates
          _buildToolCard(
            context,
            icon: Icons.cleaning_services,
            iconColor: Colors.red,
            title: 'Cleanup Duplicate Workers',
            description: 'Remove duplicate worker entries and fix references',
            badge: 'CAUTION',
            badgeColor: Colors.orange,
            onTap: () {
              _showWarningDialog(
                context,
                'Cleanup Duplicate Workers',
                'This tool will modify your database. Make sure to:\n\n'
                    '1. Run it in DRY RUN mode first\n'
                    '2. Review the output carefully\n'
                    '3. Only enable LIVE mode after verification\n\n'
                    'Continue?',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CleanupDuplicateWorkersScreen(),
                    ),
                  );
                },
              );
            },
          ),

          SizedBox(height: 24),

          // Instructions
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                      SizedBox(width: 8),
                      Text(
                        'Recommended Workflow',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildStep(1, 'Run "Verify Worker IDs" to check for issues'),
                  _buildStep(
                      2, 'If duplicates found, run "Cleanup" in DRY RUN mode'),
                  _buildStep(3, 'Review the cleanup results carefully'),
                  _buildStep(4, 'Enable LIVE mode and run cleanup again'),
                  _buildStep(5, 'Run "Verify Worker IDs" again to confirm fix'),
                  _buildStep(
                      6, 'Use "Chat Diagnostics" if chat issues persist'),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Warning banner
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Always backup your database before running cleanup tools. '
                        'Use DRY RUN mode first to preview changes.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              SizedBox(width: 16),
              // Text
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
}
