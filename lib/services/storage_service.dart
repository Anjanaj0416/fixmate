// lib/services/storage_service.dart
// COMPLETE FIXED VERSION - Profile pictures now persist properly
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload issue photo to Firebase Storage
  /// Returns the download URL
  /// Works on Web, Mobile, and Desktop platforms
  static Future<String> uploadIssuePhoto({
    required XFile imageFile,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = 'issue_${user.uid}_$timestamp$extension';

      Reference storageRef =
          _storage.ref().child('issue_photos').child(user.uid).child(fileName);

      final bytes = await imageFile.readAsBytes();

      print('📤 Uploading ${bytes.length} bytes to Firebase Storage...');
      print('📍 Path: issue_photos/${user.uid}/$fileName');

      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Photo uploaded successfully!');
      print('🔗 Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading issue photo: $e');
      rethrow;
    }
  }

  /// ✅ FIXED: Upload worker profile picture with consistent filename
  /// Returns the download URL
  /// Uses a fixed filename 'profile_picture' so the URL remains consistent
  static Future<String> uploadWorkerProfilePicture({
    required XFile imageFile,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String extension = path.extension(imageFile.path);
      // ✅ FIX: Use fixed filename 'profile_picture' instead of timestamp
      // This ensures the URL stays the same across uploads
      String fileName = 'profile_picture$extension';

      Reference storageRef = _storage
          .ref()
          .child('worker_profiles')
          .child(user.uid)
          .child(fileName);

      final bytes = await imageFile.readAsBytes();

      print('📤 Uploading profile picture ${bytes.length} bytes...');
      print('📍 Path: worker_profiles/${user.uid}/$fileName');

      // ✅ FIX: Add cache control to prevent caching issues
      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(extension),
          cacheControl: 'public, max-age=300', // Cache for 5 minutes
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Profile picture uploaded successfully!');
      print('🔗 Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// ✅ Delete old profile picture from Firebase Storage
  /// This is now optional since we're overwriting the same file
  static Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Old profile picture deleted successfully');
    } catch (e) {
      print('⚠️ Error deleting old profile picture: $e');
      // Don't throw error, just log it
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg';
    }
  }
}
