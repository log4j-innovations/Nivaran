// lib/services/image_upload_service.dart
import 'dart:io';
//import 'dart:convert';
// Firebase imports (commented out but kept for future reference)
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:uuid/uuid.dart'; // For generating unique filenames
import 'dart:developer' as developer;
import '../secrets.dart';
// import 'package:cloudinary_public/cloudinary_public.dart';

class ImageUploadService {
  // Firebase Storage fields (commented out but kept for future reference)
  final firebase_storage.FirebaseStorage _storage = firebase_storage
      .FirebaseStorage.instanceFor(bucket: 'authapp-3bd50.firebasestorage.app');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cloudinary implementation
  // final CloudinaryPublic _cloudinary;
  final Uuid _uuid = const Uuid();

  ImageUploadService() {
    // : _cloudinary = CloudinaryPublic(
    //     cloudinaryCloudName,
    //     cloudinaryUploadPreset,
    //   )
    // developer.log('Cloudinary initialized with cloud name: $cloudinaryCloudName',
    //              name: 'ImageUploadService');
  }

  // Firebase Storage implementation with App Check support
  Future<String?> uploadImage(File imageFile) async {
    developer.log(
      'Starting image upload process...',
      name: 'ImageUploadService',
    );

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      developer.log(
        '❌ User not authenticated, cannot upload image.',
        name: 'ImageUploadService',
      );
      throw Exception('User not authenticated. Cannot upload image.');
    }

    developer.log(
      '✅ User authenticated: ${currentUser.uid}',
      name: 'ImageUploadService',
    );

    // Verify App Check token before upload
    try {
      developer.log('Checking App Check token...', name: 'ImageUploadService');
      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      if (appCheckToken == null || appCheckToken.isEmpty) {
        developer.log(
          '❌ App Check token is null or empty. Debug token: $app_debug_token',
          name: 'ImageUploadService',
        );
        developer.log(
          '⚠️ This will likely cause upload to fail. Check Firebase Console App Check settings.',
          name: 'ImageUploadService',
        );
        // Continue anyway for debugging
      } else {
        developer.log(
          '✅ App Check token verified successfully (length: ${appCheckToken.length})',
          name: 'ImageUploadService',
        );
      }
    } catch (appCheckError) {
      developer.log(
        '❌ App Check verification failed: $appCheckError',
        name: 'ImageUploadService',
      );
      developer.log(
        '⚠️ Continuing with upload, but it may fail due to App Check issues',
        name: 'ImageUploadService',
      );
    }

    try {
      // Generate a unique filename to avoid overwrites and ensure privacy if needed
      final String fileExtension = imageFile.path.split('.').last;
      final String fileName = '${_uuid.v4()}.$fileExtension';

      // Define the path in Firebase Storage.
      // As per requirement, storing images directly at the root of the bucket
      // without creating any subfolders
      final String filePath = 'issues_images/$fileName';

      // No need to check for directory existence when uploading to root

      firebase_storage.Reference ref = _storage.ref().child(filePath);

      developer.log(
        'Uploading image to Firebase Storage at path: $filePath',
        name: 'ImageUploadService',
      );

      // Upload the file
      firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for the upload to complete
      firebase_storage.TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      developer.log(
        'Image uploaded successfully. Download URL: $downloadUrl',
        name: 'ImageUploadService',
      );
      return downloadUrl;
    } on firebase_storage.FirebaseException catch (e) {
      developer.log(
        '❌ Firebase Storage Error: ${e.code} - ${e.message}',
        name: 'ImageUploadService',
        error: e,
      );

      // Provide specific error messages and solutions
      String errorMessage;
      String suggestion;

      switch (e.code) {
        case 'unauthorized':
          errorMessage =
              'Upload unauthorized - App Check or authentication issue';
          suggestion =
              'Check: 1) User is logged in, 2) App Check debug token is in Firebase Console, 3) Storage rules allow authenticated users';
          break;
        case 'permission-denied':
          errorMessage =
              'Permission denied - Storage rules or authentication issue';
          suggestion =
              'Check Firebase Storage rules and ensure user is authenticated';
          break;
        case 'unauthenticated':
          errorMessage = 'User not authenticated';
          suggestion = 'User must be logged in to upload images';
          break;
        case 'app-check-token-invalid':
          errorMessage = 'App Check token is invalid';
          suggestion =
              'Add debug token $app_debug_token to Firebase Console App Check settings';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message}';
          suggestion = 'Check network connection and Firebase configuration';
      }

      developer.log('💡 Suggestion: $suggestion', name: 'ImageUploadService');

      // Check if this is an App Check related error
      if (e.code == 'unauthorized' ||
          e.code == 'permission-denied' ||
          e.message?.contains('App Check') == true ||
          e.message?.contains('appcheck') == true) {
        developer.log('🔍 App Check Debug Info:', name: 'ImageUploadService');
        developer.log(
          '   Debug token: $app_debug_token',
          name: 'ImageUploadService',
        );
        developer.log(
          '   Make sure this token is added to Firebase Console > App Check > Debug tokens',
          name: 'ImageUploadService',
        );
        developer.log(
          '   Storage bucket: authapp-3bd50.firebasestorage.app',
          name: 'ImageUploadService',
        );
      }

      throw Exception('$errorMessage. $suggestion');
    } catch (e, s) {
      developer.log(
        'Upload Image Exception: $e',
        name: 'ImageUploadService',
        error: e,
        stackTrace: s,
      );
      // Return null or rethrow a custom exception
      return null;
    }
  }

  // Cloudinary implementation
  // Future<String?> uploadImage(File imageFile) async {
  //   try {
  //     // Generate a unique filename to avoid overwrites
  //     final String fileExtension = imageFile.path.split('.').last;
  //     final String fileName = '${_uuid.v4()}.$fileExtension';

  //     developer.log('Uploading image to Cloudinary with filename: $fileName', name: 'ImageUploadService');

  //     // Create CloudinaryResponse by uploading the file
  //     final CloudinaryResponse response = await _cloudinary.uploadFile(
  //       CloudinaryFile.fromFile(
  //         imageFile.path,
  //         resourceType: CloudinaryResourceType.Image,
  //         folder: 'nivaran', // Optional: organize images in a folder
  //       ),
  //     );

  //     // Get the secure URL from the response
  //     final String secureUrl = response.secureUrl;

  //     developer.log('Image uploaded successfully to Cloudinary. URL: $secureUrl', name: 'ImageUploadService');
  //     return secureUrl;

  //   } on CloudinaryException catch (e) {
  //     developer.log('Cloudinary Error: ${e.message}', name: 'ImageUploadService', error: e);
  //     throw Exception('Failed to upload image to Cloudinary. Error: ${e.message}');
  //   } catch (e, s) {
  //     developer.log('Upload Image Exception: $e', name: 'ImageUploadService', error: e, stackTrace: s);
  //     // Return null or rethrow a custom exception
  //     return null;
  //   }
  // }
}
