// lib/services/auth_service.dart
// UPDATED VERSION - Enhanced email verification methods
// Added better email verification tracking and management

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Create account with email and password
  Future<UserCredential?> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw e;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw e;
    }
  }

  // Get user data
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw e;
    }
  }

  // Stream user data
  Stream<DocumentSnapshot> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Check if user has completed profile setup
  Future<bool> hasCompletedProfile(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData.containsKey('accountType') &&
            userData['accountType'] != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Update account type
  Future<void> updateAccountType({
    required String uid,
    required String accountType,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountType': accountType,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e;
    }
  }

  // Create or update user document
  Future<void> createOrUpdateUser({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        // Update existing user
        userData['updatedAt'] = FieldValue.serverTimestamp();
        await userRef.update(userData);
      } else {
        // Create new user
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['updatedAt'] = FieldValue.serverTimestamp();
        await userRef.set(userData);
      }
    } catch (e) {
      throw e;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user from Firebase Auth
        await user.delete();
      }
    } catch (e) {
      throw e;
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);

        // Update email in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'email': newEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw e;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw e;
    }
  }

  // Reauthenticate user (required for sensitive operations)
  Future<void> reauthenticate(String email, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } catch (e) {
      throw e;
    }
  }

  // ⭐ ENHANCED: Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ⭐ ENHANCED: Send email verification with error handling
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('✅ Verification email sent to ${user.email}');
      } else if (user != null && user.emailVerified) {
        print('ℹ️ Email already verified');
      }
    } catch (e) {
      print('❌ Error sending verification email: $e');
      throw e;
    }
  }

  // ⭐ NEW: Reload user and check verification status
  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;
        return user?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error reloading user: $e');
      throw e;
    }
  }

  // ⭐ NEW: Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus(String uid, bool verified) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'emailVerified': verified,
        'emailVerifiedAt': verified ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Email verification status updated in Firestore');
    } catch (e) {
      print('❌ Error updating verification status: $e');
      throw e;
    }
  }

  // ⭐ NEW: Get email verification status from Firestore
  Future<bool> getEmailVerificationStatus(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['emailVerified'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error getting verification status: $e');
      return false;
    }
  }

  // Reload user data
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      throw e;
    }
  }
}
