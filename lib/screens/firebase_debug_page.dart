import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDebugPage extends StatefulWidget {
  const FirebaseDebugPage({Key? key}) : super(key: key);

  @override
  State<FirebaseDebugPage> createState() => _FirebaseDebugPageState();
}

class _FirebaseDebugPageState extends State<FirebaseDebugPage> {
  List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print(message);
  }

  Future<void> _testFirebaseSetup() async {
    setState(() {
      _logs.clear();
      _isLoading = true;
    });

    _addLog('🔍 Starting Firebase tests...');

    try {
      // Test 1: Check Firebase Auth
      _addLog('Test 1: Checking Firebase Auth...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _addLog('✅ Auth user: ${currentUser.uid}');
      } else {
        _addLog('⚠️ No user logged in');
      }

      // Test 2: Check Database URL
      _addLog('Test 2: Checking Database URL...');
      final dbUrl = FirebaseDatabase.instance.databaseURL;
      _addLog('📍 Database URL: $dbUrl');

      // Test 3: Try to write test data
      _addLog('Test 3: Writing test data...');
      final testRef = FirebaseDatabase.instance.ref('test/debug');
      await testRef.set({
        'message': 'Test from emulator',
        'timestamp': DateTime.now().toIso8601String(),
        'uid': currentUser?.uid ?? 'no-user',
      });
      _addLog('✅ Write successful!');

      // Test 4: Try to read test data
      _addLog('Test 4: Reading test data...');
      final snapshot = await testRef.get();
      if (snapshot.exists) {
        _addLog('✅ Read successful: ${snapshot.value}');
      } else {
        _addLog('❌ No data found');
      }

      // Test 5: Try to write user data
      _addLog('Test 5: Writing user test data...');
      if (currentUser != null) {
        final userRef = FirebaseDatabase.instance.ref('users/${currentUser.uid}');
        await userRef.set({
          'uid': currentUser.uid,
          'name': 'Test User',
          'mobile': '9999999999',
          'email': 'test@test.com',
          'city': 'Mumbai',
          'role': 'customer',
          'createdAt': DateTime.now().toIso8601String(),
        });
        _addLog('✅ User data write successful!');

        // Test 6: Read user data
        _addLog('Test 6: Reading user data...');
        final userSnapshot = await userRef.get();
        if (userSnapshot.exists) {
          _addLog('✅ User data read successful!');
          _addLog('Data: ${userSnapshot.value}');
        } else {
          _addLog('❌ User data not found');
        }
      } else {
        _addLog('⚠️ Skipping user test - no auth user');
      }

      _addLog('🎉 All tests completed!');
    } catch (e, stackTrace) {
      _addLog('❌ ERROR: ${e.toString()}');
      _addLog('Stack: ${stackTrace.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testUserSave() async {
    _addLog('🔄 Testing user save with AuthProvider logic...');
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _addLog('❌ No Firebase Auth user. Please login first.');
        return;
      }

      _addLog('✅ Current user UID: ${currentUser.uid}');
      
      final userData = {
        'uid': currentUser.uid,
        'name': 'Debug Test User',
        'mobile': '9876543210',
        'email': 'debug@test.com',
        'city': 'Delhi',
        'referralCode': '',
        'role': 'customer',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': null,
      };

      _addLog('📝 Saving user data...');
      _addLog('Data: $userData');

      await FirebaseDatabase.instance
          .ref('users/${currentUser.uid}')
          .set(userData);

      _addLog('✅ User saved successfully!');

      // Verify by reading back
      _addLog('🔍 Verifying save...');
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${currentUser.uid}')
          .get();

      if (snapshot.exists) {
        _addLog('✅ VERIFIED! User exists in database');
        _addLog('Saved data: ${snapshot.value}');
      } else {
        _addLog('❌ FAILED! User not found after save');
      }
    } catch (e, stackTrace) {
      _addLog('❌ Error: ${e.toString()}');
      _addLog('Stack: ${stackTrace.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testFirebaseSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Run All Tests',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testUserSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Test User Save',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Press "Run All Tests" to start',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        Color color = Colors.white;
                        if (log.contains('✅')) color = Colors.green;
                        if (log.contains('❌')) color = Colors.red;
                        if (log.contains('⚠️')) color = Colors.orange;
                        if (log.contains('📍') || log.contains('📝')) {
                          color = Colors.blue;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: color,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}