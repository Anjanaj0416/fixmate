// lib/main.dart
// UPDATED VERSION - Proper Firebase Storage Emulator setup for Web
// Replace the entire file with this code

/*import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/worker_dashboard_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/account_type_screen.dart';
import 'screens/worker_registration_flow.dart';
import 'screens/customer_dashboard.dart';
import 'services/openai_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Storage Emulator for development
  if (kDebugMode) {
    try {
      // For web, use the host without 'localhost' string, use actual host
      if (kIsWeb) {
        await FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
        print('🔧 Using Firebase Storage Emulator on 127.0.0.1:9199 (Web)');
      } else {
        await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
        print('🔧 Using Firebase Storage Emulator on localhost:9199 (Mobile)');
      }

      // Test the emulator connection
      await _testStorageConnection();
    } catch (e) {
      print('⚠️ Warning: Could not connect to Storage Emulator: $e');
      print(
          '   Make sure the emulator is running: firebase emulators:start --only storage');
    }
  }

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    // Initialize OpenAI service
    OpenAIService.initialize();
  } catch (e) {
    print('Warning: Failed to load .env file: $e');
    print('AI features will not be available.');
  }

  runApp(FixMateApp());
}

/// Test Firebase Storage connection
Future<void> _testStorageConnection() async {
  try {
    print('🧪 Testing Firebase Storage connection...');
    final testRef =
        FirebaseStorage.instance.ref().child('_test/connection_test.txt');

    // Try to upload a test file
    await testRef.putString('Connection test - ${DateTime.now()}');
    print('✅ Storage upload test passed!');

    // Try to get the download URL
    String url = await testRef.getDownloadURL();
    print('✅ Storage download URL test passed!');
    print('   Test file URL: $url');

    // Clean up
    await testRef.delete();
    print('✅ Storage emulator connection successful!');
  } catch (e) {
    print('❌ Storage connection test failed: $e');
    throw e;
  }
}

class FixMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixMate',
      theme: ThemeData(
        primaryColor: Color(0xFF2196F3),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFFFF9800),
        ),
      ),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/signin': (context) => SignInScreen(),
        '/signup': (context) => CreateAccountScreen(),
        '/account_type': (context) => AccountTypeScreen(),
        '/worker_registration': (context) => WorkerRegistrationFlow(),
        '/worker_dashboard': (context) => WorkerDashboardScreen(),
        '/customer_dashboard': (context) => CustomerDashboard(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes or routes with parameters
        switch (settings.name) {
          case '/worker_dashboard':
            return MaterialPageRoute(
              builder: (context) => WorkerDashboardScreen(),
            );
          case '/customer_dashboard':
            return MaterialPageRoute(
              builder: (context) => CustomerDashboard(),
            );
          default:
            // Return null to let the framework handle the route
            return null;
        }
      },
    );
  }
}*/

// lib/main.dart
// TESTED VERSION - Works on Windows with proper browser handling
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/worker_dashboard_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/account_type_screen.dart';
import 'screens/worker_registration_flow.dart';
import 'screens/customer_dashboard.dart';
import 'services/openai_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Storage Emulator for development
  if (kDebugMode) {
    try {
      // For web platforms (Chrome, Edge, etc.)
      if (kIsWeb) {
        // Use 127.0.0.1 for web to avoid CORS issues
        await FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
        print('🔧 Firebase Storage Emulator: 127.0.0.1:9199 (Web)');
      } else {
        // Use localhost for mobile/desktop
        await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
        print('🔧 Firebase Storage Emulator: localhost:9199 (Mobile/Desktop)');
      }

      // Test connection (optional - comment out if causing issues)
      await _testStorageConnection();
    } catch (e) {
      print('⚠️ Storage Emulator not connected: $e');
      print('   Run: firebase emulators:start --only storage');
      print('   App will continue without emulator');
    }
  }

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    OpenAIService.initialize();
    print('✅ OpenAI Service initialized');
  } catch (e) {
    print('⚠️ .env file not loaded: $e');
    print('   AI features will be limited');
  }

  runApp(FixMateApp());
}

/// Test Firebase Storage connection (optional)
Future<void> _testStorageConnection() async {
  try {
    print('🧪 Testing Storage Emulator...');
    final testRef = FirebaseStorage.instance
        .ref()
        .child('_test/connection_${DateTime.now().millisecondsSinceEpoch}.txt');

    await testRef.putString('Test - ${DateTime.now()}');
    String url = await testRef.getDownloadURL();
    await testRef.delete();

    print('✅ Storage Emulator working!');
    print('   URL format: $url');
  } catch (e) {
    print('⚠️ Storage test failed: $e');
    // Don't throw - let app continue
  }
}

class FixMateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixMate',
      theme: ThemeData(
        primaryColor: Color(0xFF2196F3),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFFFF9800),
        ),
      ),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/signin': (context) => SignInScreen(),
        '/signup': (context) => CreateAccountScreen(),
        '/account_type': (context) => AccountTypeScreen(),
        '/worker_registration': (context) => WorkerRegistrationFlow(),
        '/worker_dashboard': (context) => WorkerDashboardScreen(),
        '/customer_dashboard': (context) => CustomerDashboard(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/worker_dashboard':
            return MaterialPageRoute(
              builder: (context) => WorkerDashboardScreen(),
            );
          case '/customer_dashboard':
            return MaterialPageRoute(
              builder: (context) => CustomerDashboard(),
            );
          default:
            return null;
        }
      },
    );
  }
}
