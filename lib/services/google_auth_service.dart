// lib/services/google_auth_service.dart
// FIXED VERSION - Works on both Android and Web

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lazy initialization
  GoogleSignIn? _googleSignIn;

  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      _googleSignIn = GoogleSignIn();
    }
    return _googleSignIn!;
  }

  /// Sign in with Google OAuth
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔵 Starting Google Sign-In process...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _getGoogleSignIn().signIn();

      if (googleUser == null) {
        print('❌ Google Sign-In cancelled by user');
        return null; // User cancelled the sign-in
      }

      print('✅ Google account selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔑 Obtained Google authentication tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Created Firebase credential');

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print('✅ Signed in to Firebase: ${userCredential.user?.email}');

      // Check if user document exists, create if not
      await _ensureUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      print('❌ Error during Google Sign-In: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  /// Ensure user document exists in Firestore
  Future<void> _ensureUserDocument(User user) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user document
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'authProvider': 'google',
          // accountType and role will be set later by user
        });
        print('✅ Created new user document for Google user');
      } else {
        // Update last login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('✅ Updated last login for existing user');
      }
    } catch (e) {
      print('❌ Error ensuring user document: $e');
    }
  }

  /// Sign out from both Google and Firebase
  Future<void> signOut() async {
    try {
      await Future.wait([
        if (_googleSignIn != null) _googleSignIn!.signOut(),
        _auth.signOut(),
      ]);
      print('✅ Signed out from Google and Firebase');
    } catch (e) {
      print('❌ Error during sign out: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  /// Check if user is currently signed in
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get user auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
