import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationHelperScreen extends StatefulWidget {
  @override
  _MigrationHelperScreenState createState() => _MigrationHelperScreenState();
}

class _MigrationHelperScreenState extends State<MigrationHelperScreen> {
  bool _isRunning = false;
  String _log = '';

  void _addLog(String message) {
    setState(() {
      _log += '$message\n';
    });
    print(message);
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _log = '';
    });

    _addLog('🚀 Starting migration...');
    _addLog('Adding is_online and last_seen to workers\n');

    try {
      QuerySnapshot workersSnapshot =
          await FirebaseFirestore.instance.collection('workers').get();

      _addLog('📊 Found ${workersSnapshot.docs.length} workers\n');

      int updateCount = 0;
      int skipCount = 0;

      for (var doc in workersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (!data.containsKey('is_online')) {
          await doc.reference.update({
            'is_online': false,
            'last_seen': FieldValue.serverTimestamp(),
          });
          _addLog('✅ Updated: ${data['worker_name']}');
          updateCount++;
        } else {
          _addLog(
              '⏭️ Skipped: ${data['worker_name']} (already has online status)');
          skipCount++;
        }
      }

      _addLog('\n📊 Migration Summary:');
      _addLog('   Updated: $updateCount workers');
      _addLog('   Skipped: $skipCount workers');
      _addLog('\n✅ Migration completed successfully!');
    } catch (e) {
      _addLog('\n❌ Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Migration Helper'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Online Status Migration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This will add is_online and last_seen fields to all existing workers.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isRunning ? null : _runMigration,
                      child: Text(_isRunning ? 'Running...' : 'Run Migration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      _log.isEmpty ? 'Migration log will appear here...' : _log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
