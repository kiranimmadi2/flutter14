import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  late final FirebaseStorage _storage;
  final _uuid = const Uuid();
  
  FirebaseStorageService() {
    _storage = FirebaseStorage.instance;
  }

  Future<List<String>> uploadImages(List<File> images, String userId) async {
    List<String> downloadUrls = [];
    
    for (File image in images) {
      try {
        // Check if file exists
        if (!await image.exists()) {
          print('Image file does not exist: ${image.path}');
          continue;
        }
        
        // Get file size
        final fileSize = await image.length();
        print('Uploading image: ${image.path}, size: $fileSize bytes');
        
        String fileName = '${_uuid.v4()}.jpg';
        String path = 'posts/$userId/$fileName';
        
        print('Upload path: $path');
        
        // Create reference
        final ref = _storage.ref().child(path);
        
        // Upload with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadTime': DateTime.now().toIso8601String(),
          },
        );
        
        final uploadTask = await ref.putFile(image, metadata);
        
        if (uploadTask.state == TaskState.success) {
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          print('Image uploaded successfully: $downloadUrl');
          downloadUrls.add(downloadUrl);
        } else {
          print('Upload failed with state: ${uploadTask.state}');
        }
      } catch (e, stackTrace) {
        print('Error uploading image: $e');
        print('Stack trace: $stackTrace');
        // Continue with other images even if one fails
      }
    }
    
    return downloadUrls;
  }

  Future<String?> uploadProfileImage(File image, String userId) async {
    try {
      print('Starting profile image upload for user: $userId');
      print('File path: ${image.path}');
      
      // Check if file exists
      if (!await image.exists()) {
        print('Profile image file does not exist: ${image.path}');
        return null;
      }
      
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
      String path = 'profiles/$userId/$fileName';
      
      print('Upload path: $path');
      
      final ref = _storage.ref().child(path);
      
      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = await ref.putFile(image, metadata);
      
      // Check if upload was successful
      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        print('Upload successful! URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error uploading profile image: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<String?> uploadProfileImageBytes(Uint8List imageBytes, String userId) async {
    try {
      print('Starting profile image upload for user: $userId');
      print('Image size: ${imageBytes.length} bytes');
      
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
      String path = 'profiles/$userId/$fileName';
      
      print('Upload path: $path');
      
      final ref = _storage.ref().child(path);
      
      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = await ref.putData(imageBytes, metadata);
      
      // Check if upload was successful
      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        print('Upload successful! URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error uploading profile image bytes: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}