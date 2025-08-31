// lib/services/app_check_test_service.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../secrets.dart';
import 'dart:developer' as developer;

class AppCheckTestService {
  static Future<void> testAppCheckToken() async {
    try {
      developer.log(
        'Testing App Check with debug token: $app_debug_token',
        name: 'AppCheckTest',
      );

      // Get the current App Check token
      final token = await FirebaseAppCheck.instance.getToken();

      if (token != null) {
        developer.log(
          'App Check token obtained successfully. Token length: ${token.length}',
          name: 'AppCheckTest',
        );
        developer.log(
          'App Check is working correctly with debug token',
          name: 'AppCheckTest',
        );

        // Log build mode for debugging
        developer.log(
          'Running in ${kDebugMode ? 'DEBUG' : 'RELEASE'} mode',
          name: 'AppCheckTest',
        );
      } else {
        developer.log(
          'App Check token is null - this may indicate a configuration issue',
          name: 'AppCheckTest',
        );
        developer.log(
          'Debug token configured: $app_debug_token',
          name: 'AppCheckTest',
        );
      }
    } catch (e) {
      developer.log(
        'Error getting App Check token: $e',
        name: 'AppCheckTest',
        error: e,
      );
      developer.log(
        'Make sure the debug token $app_debug_token is added to Firebase Console',
        name: 'AppCheckTest',
      );
    }
  }

  static Future<bool> isAppCheckWorking() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      final isWorking = token != null && token.isNotEmpty;

      developer.log(
        'App Check status: ${isWorking ? 'WORKING' : 'NOT WORKING'}',
        name: 'AppCheckTest',
      );

      return isWorking;
    } catch (e) {
      developer.log(
        'App Check test failed: $e',
        name: 'AppCheckTest',
        error: e,
      );
      return false;
    }
  }

  /// Test App Check specifically for image upload functionality
  static Future<Map<String, dynamic>> testAppCheckForImageUpload() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();

      if (token != null && token.isNotEmpty) {
        return {
          'success': true,
          'message': 'App Check token is available for image upload',
          'tokenLength': token.length,
          'debugToken': app_debug_token,
        };
      } else {
        return {
          'success': false,
          'message': 'App Check token is null or empty',
          'debugToken': app_debug_token,
          'suggestion':
              'Make sure the debug token is added to Firebase Console',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'App Check test failed: $e',
        'debugToken': app_debug_token,
        'error': e.toString(),
      };
    }
  }
}
