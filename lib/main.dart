import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Add this import
import 'screens/welcome_screen.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fix: Pass the Firebase options for the current platform
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
    );
  }
}
