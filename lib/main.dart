import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/worker_dashboard_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/account_type_screen.dart';
import 'screens/worker_registration_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes or routes with parameters
        switch (settings.name) {
          case '/worker_dashboard':
            return MaterialPageRoute(
              builder: (context) => WorkerDashboardScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
