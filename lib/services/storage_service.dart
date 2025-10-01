// lib/services/storage_service.dart
// NEW FILE - Add this file to upload photos to Firebase Storage

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload issue photo to Firebase Storage
  /// Returns the download URL
  static Future<String> uploadIssuePhoto({
    required XFile imageFile,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      String fileName = 'issue_${user.uid}_$timestamp$extension';

      // Create storage reference
      Reference storageRef =
          _storage.ref().child('issue_photos').child(user.uid).child(fileName);

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload file
      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Upload multiple issue photos
  /// Returns list of download URLs
  static Future<List<String>> uploadMultipleIssuePhotos({
    required List<XFile> imageFiles,
  }) async {
    List<String> downloadUrls = [];

    for (XFile imageFile in imageFiles) {
      try {
        String url = await uploadIssuePhoto(imageFile: imageFile);
        downloadUrls.add(url);
      } catch (e) {
        print('❌ Failed to upload photo: ${imageFile.path}');
        // Continue with other photos even if one fails
      }
    }

    return downloadUrls;
  }

  /// Delete issue photo from Firebase Storage
  static Future<void> deleteIssuePhoto(String photoUrl) async {
    try {
      Reference photoRef = _storage.refFromURL(photoUrl);
      await photoRef.delete();
      print('✅ Photo deleted successfully');
    } catch (e) {
      print('❌ Error deleting photo: $e');
      throw Exception('Failed to delete photo: $e');
    }
  }

  Future<void> testStorageEmulator() async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('test/test.txt');

      // Try to upload test data
      await ref.putString('Test data from Flutter');
      print('✅ Storage emulator test passed!');

      // Clean up
      await ref.delete();
    } catch (e) {
      print('❌ Storage emulator test failed: $e');
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
      default:
        return 'image/jpeg';
    }
  }
}
