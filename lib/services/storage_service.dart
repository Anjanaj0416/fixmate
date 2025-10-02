// lib/services/storage_service.dart
// FIXED VERSION - Works with Firebase Storage Emulator on Web
// Replace the entire file with this code

/*import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload issue photo to Firebase Storage
  /// Returns the download URL
  /// Works on both Web and Mobile platforms
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

      // Read file bytes (works on both web and mobile)
      final bytes = await imageFile.readAsBytes();

      print('📤 Uploading ${bytes.length} bytes to Firebase Storage...');
      print('📍 Path: issue_photos/${user.uid}/$fileName');

      // Upload file using putData (works on web)
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

      print('✅ Photo uploaded successfully!');
      print('🔗 Download URL: $downloadUrl');
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

    print('📤 Starting upload of ${imageFiles.length} photo(s)...');

    for (int i = 0; i < imageFiles.length; i++) {
      XFile imageFile = imageFiles[i];
      try {
        print('📸 Uploading photo ${i + 1}/${imageFiles.length}...');
        String url = await uploadIssuePhoto(imageFile: imageFile);
        downloadUrls.add(url);
        print('✅ Photo ${i + 1} uploaded successfully');
      } catch (e) {
        print('❌ Failed to upload photo ${i + 1}: ${imageFile.name}');
        print('   Error: $e');
        // Continue with other photos even if one fails
      }
    }

    print(
        '✅ Upload complete: ${downloadUrls.length}/${imageFiles.length} photos uploaded');
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

  /// Test Storage Emulator connection
  static Future<void> testStorageEmulator() async {
    try {
      print('🧪 Testing Firebase Storage Emulator...');
      final storage = FirebaseStorage.instance;
      final ref = storage
          .ref()
          .child('test/test_${DateTime.now().millisecondsSinceEpoch}.txt');

      // Try to upload test data
      await ref.putString('Test data from Flutter Web - ${DateTime.now()}');
      print('✅ Upload test passed!');

      // Try to get download URL
      String url = await ref.getDownloadURL();
      print('✅ Download URL retrieved: $url');

      // Clean up
      await ref.delete();
      print('✅ Storage emulator test passed!');
    } catch (e) {
      print('❌ Storage emulator test failed: $e');
      rethrow;
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
}*/

// lib/services/storage_service.dart
// PRODUCTION READY - Works with Firebase Storage Emulator and Production
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

      // Generate unique filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String extension = path.extension(imageFile.path);
      if (extension.isEmpty) {
        extension = '.jpg'; // Default to jpg if no extension
      }
      String fileName = 'issue_${user.uid}_$timestamp$extension';

      // Create storage reference
      Reference storageRef =
          _storage.ref().child('issue_photos').child(user.uid).child(fileName);

      // Read file bytes (works on all platforms)
      final bytes = await imageFile.readAsBytes();

      print('📤 Uploading ${bytes.length} bytes...');
      print('📍 Path: issue_photos/${user.uid}/$fileName');

      // Upload using putData (works on web and mobile)
      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );

      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Photo uploaded successfully!');
      print('🔗 URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Upload multiple issue photos
  /// Returns list of successfully uploaded URLs
  static Future<List<String>> uploadMultipleIssuePhotos({
    required List<XFile> imageFiles,
  }) async {
    List<String> downloadUrls = [];
    int successCount = 0;
    int failCount = 0;

    print('📤 Starting batch upload: ${imageFiles.length} photo(s)');

    for (int i = 0; i < imageFiles.length; i++) {
      XFile imageFile = imageFiles[i];
      try {
        print('\n📸 Uploading photo ${i + 1}/${imageFiles.length}...');
        String url = await uploadIssuePhoto(imageFile: imageFile);
        downloadUrls.add(url);
        successCount++;
        print('✅ Photo ${i + 1} uploaded');
      } catch (e) {
        failCount++;
        print('❌ Photo ${i + 1} failed: ${imageFile.name}');
        print('   Error: $e');
        // Continue with remaining photos
      }
    }

    print('\n📊 Batch upload complete:');
    print('   ✅ Success: $successCount');
    print('   ❌ Failed: $failCount');
    print('   📋 Total URLs: ${downloadUrls.length}');

    return downloadUrls;
  }

  /// Delete issue photo from Firebase Storage
  static Future<void> deleteIssuePhoto(String photoUrl) async {
    try {
      print('🗑️ Deleting photo: $photoUrl');
      Reference photoRef = _storage.refFromURL(photoUrl);
      await photoRef.delete();
      print('✅ Photo deleted');
    } catch (e) {
      print('❌ Delete error: $e');
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Delete multiple photos
  static Future<void> deleteMultiplePhotos(List<String> photoUrls) async {
    int successCount = 0;
    int failCount = 0;

    for (String url in photoUrls) {
      try {
        await deleteIssuePhoto(url);
        successCount++;
      } catch (e) {
        failCount++;
        print('⚠️ Could not delete: $url');
      }
    }

    print('📊 Batch delete: ✅$successCount ❌$failCount');
  }

  /// Test Storage Emulator connection
  static Future<bool> testStorageEmulator() async {
    try {
      print('🧪 Testing Storage Emulator...');
      final ref = _storage
          .ref()
          .child('_test/test_${DateTime.now().millisecondsSinceEpoch}.txt');

      // Upload test
      await ref.putString('Test from FixMate - ${DateTime.now()}');
      print('  ✓ Upload works');

      // Download URL test
      String url = await ref.getDownloadURL();
      print('  ✓ Download URL: $url');

      // Delete test
      await ref.delete();
      print('  ✓ Delete works');

      print('✅ Storage Emulator test passed!');
      return true;
    } catch (e) {
      print('❌ Storage Emulator test failed: $e');
      return false;
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
      case '.heic':
      case '.heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Get file size in human-readable format
  static String getReadableFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
