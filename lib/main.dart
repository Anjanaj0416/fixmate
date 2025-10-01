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

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    print('🔧 Using Firebase Storage Emulator on localhost:9199');
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
}
