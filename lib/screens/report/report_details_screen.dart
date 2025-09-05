// lib/screens/report/report_details_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import for ConnectivityResult

import '../../services/image_upload_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/auth_button.dart';
import '../../models/app_user_model.dart';
import '../../models/category_model.dart';
import '../../models/issue_model.dart';
import 'dart:developer' as developer;
import '../../secrets.dart';

import '../feed/issue_collaboration_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String imagePath;
  const ReportDetailsScreen({super.key, required this.imagePath});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoadingInitialData = true;
  bool _isSubmitting = false;
  bool _isGeneratingDescription = false;
  bool _isSuggestingCategory = false;
  bool _isDetectingUrgency = false;
  
  Position? _currentPosition;
  String? _currentAddress;
  String _detectedUrgency = 'Medium';
  
  List<CategoryModel> _fetchedCategories = [];
  CategoryModel? _selectedCategoryModel;

  ConnectivityService? _connectivityService;
  OfflineSyncService? _offlineSyncService;
  final LocationService _locationService = LocationService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final FirestoreService _firestoreService = FirestoreService();

  String _analysisStatus = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _connectivityService = Provider.of<ConnectivityService>(context, listen: false);
        _offlineSyncService = Provider.of<OfflineSyncService>(context, listen: false);
        _fetchInitialData();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted || _connectivityService == null) return;
    setState(() {
      _isLoadingInitialData = true;
      _analysisStatus = AppLocalizations.of(context)!.fetchingLocationAndCategories;
    });
    
    try {
      // Step 1: Fetch location
      developer.log('Step 1: Fetching location...', name: 'ReportDetailsScreen');
      _currentPosition = await _locationService.getCurrentPosition();
      if (mounted && _currentPosition != null) {
        _currentAddress = await _locationService.getAddressFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude);
        developer.log('Location fetched: $_currentAddress', name: 'ReportDetailsScreen');
      } else {
        developer.log('Failed to get location', name: 'ReportDetailsScreen');
      }
      
      if (mounted) {
        setState(() {
          _analysisStatus = AppLocalizations.of(context)!.loadingCategories;
        });
      }

      // Step 2: Fetch categories
      developer.log('Step 2: Fetching categories...', name: 'ReportDetailsScreen');
      _fetchedCategories = await _firestoreService.fetchIssueCategories();
      developer.log('Categories fetched: ${_fetchedCategories.length}', name: 'ReportDetailsScreen');
      
      if (_fetchedCategories.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load issue categories. You can still submit manually.')),
        );
      }

      // Step 3: Perform AI analysis
      final connectivityResult = await _connectivityService?.checkConnectivity() ?? ConnectivityResult.none;
      if (connectivityResult != ConnectivityResult.none) {
        if (widget.imagePath.isNotEmpty && _currentPosition != null) {
          if (mounted) {
            setState(() {
              _analysisStatus = AppLocalizations.of(context)!.analyzingImageWithAI;
            });
          }
          developer.log('Step 3: Starting AI analysis...', name: 'ReportDetailsScreen');
          await _performAIAnalysis();
        } else {
          developer.log('Skipping AI analysis - missing image or location', name: 'ReportDetailsScreen');
          if (mounted) {
            setState(() {
              _analysisStatus = "Manual entry required - missing data for AI analysis";
            });
          }
        }
      } else {
        developer.log('Skipping AI analysis - offline', name: 'ReportDetailsScreen');
        if (mounted) {
          setState(() {
            _analysisStatus = "Offline mode: AI analysis skipped. Urgency defaulted to Medium.";
            _detectedUrgency = 'Medium'; // Default to Medium when offline
          });
        }
      }
      
    } catch (e) {
      developer.log('Error fetching initial data: ${e.toString()}', name: 'ReportDetailsScreen');
      if (mounted) {
        setState(() {
          _analysisStatus = "Error loading data. Please enter details manually.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading details: ${e.toString().substring(0, 50)}...')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false;
          if (_analysisStatus.isEmpty || _analysisStatus.contains("Analyzing")) {
            _analysisStatus = "Ready for submission";
          }
        });
      }
    }
  }

  Future<void> _performAIAnalysis() async {
    try {
      developer.log('Reading image file: ${widget.imagePath}', name: 'ReportDetailsScreen');
      
      // Verify image file exists
      File imageFile = File(widget.imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found at ${widget.imagePath}');
      }

      // Read image and convert to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      developer.log('Image size: ${imageBytes.length} bytes', name: 'ReportDetailsScreen');
      
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      String imageBase64 = base64Encode(imageBytes);
      
      LocationModel locationModel = LocationModel(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress ?? "Unknown address"
      );
      
      developer.log('Starting Gemini analysis with location: ${locationModel.address}', name: 'ReportDetailsScreen');
      
      // Call comprehensive AI analysis
      Map<String, dynamic>? analysis = await _analyzeIssueWithGemini(imageBase64, locationModel);
      
      if (!mounted) {
        developer.log('Widget not mounted after AI analysis', name: 'ReportDetailsScreen');
        return;
      }
      
      if (analysis != null) {
        developer.log('AI analysis successful: $analysis', name: 'ReportDetailsScreen');
        
        // Set the AI-generated description (editable by user)
        if (analysis['description'] != null && analysis['description'].toString().isNotEmpty) {
          _descriptionController.text = analysis['description'].toString();
          developer.log('Description set: ${_descriptionController.text}', name: 'ReportDetailsScreen');
        } else {
          developer.log('No description in AI response', name: 'ReportDetailsScreen');
        }
        
        // Set the detected urgency (non-editable)
        if (analysis['urgency'] != null) {
          _detectedUrgency = analysis['urgency'].toString();
          developer.log('Urgency set: $_detectedUrgency', name: 'ReportDetailsScreen');
        }
        
        // Try to match and set the category
        if (analysis['category'] != null && _fetchedCategories.isNotEmpty) {
          String suggestedCategoryName = analysis['category'].toString();
          CategoryModel? matchedCategory = _fetchedCategories.firstWhere(
            (cat) => cat.name.toLowerCase() == suggestedCategoryName.toLowerCase(),
            orElse: () => _fetchedCategories.first
          );
          
          if (matchedCategory.name.isNotEmpty) {
            _selectedCategoryModel = matchedCategory;
            developer.log('Category set: ${matchedCategory.name}', name: 'ReportDetailsScreen');
          }
        }
        
        if (mounted) {
          setState(() {
            _analysisStatus = AppLocalizations.of(context)!.aiAnalysisComplete;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI analysis complete! You can edit the description and change category if needed.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        developer.log('AI analysis returned null or empty', name: 'ReportDetailsScreen');
        if (mounted) {
          setState(() {
            _analysisStatus = "AI analysis failed. Please enter details manually.";
          });
        }
      }
    } catch (e) {
      developer.log('Error in AI analysis: $e', name: 'ReportDetailsScreen');
      if (mounted) {
        setState(() {
          _analysisStatus = "AI analysis failed: ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI analysis failed: ${e.toString().substring(0, 50)}...')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _analyzeIssueWithGemini(String imageBase64, LocationModel location) async {
    if (imageBase64.isEmpty) {
      developer.log('Empty image base64', name: 'ReportDetailsScreen');
      return null;
    }
    
    if (!mounted) {
      developer.log('Widget not mounted before starting analysis', name: 'ReportDetailsScreen');
      return null;
    }
    
    setState(() {
      _isGeneratingDescription = true;
      _isSuggestingCategory = true;
      _isDetectingUrgency = true;
    });

    String locationContext = "Location: ${location.address}. Coordinates: (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}).";
    
    // Get available categories for context
    final categoryNames = _fetchedCategories.map((c) => c.name).toList();
    String categoriesContext = categoryNames.isNotEmpty 
      ? "Available categories: [${categoryNames.join(', ')}]" 
      : "No specific categories available";

    String prompt = """
Analyze this civic issue image and provide a comprehensive report in JSON format.

Context:
$locationContext
$categoriesContext

Please analyze the image and provide:
1. A clear, detailed description of the civic issue visible in the image (2-3 sentences)
2. The most appropriate category from the available list, or "General" if none fit
3. Urgency level: "Low", "Medium", or "High" based on severity and public safety impact
4. Relevant tags (3-5 comma-separated keywords) that describe the issue

Respond ONLY with a valid JSON object in this exact format:
{
  "description": "Clear description of the issue visible in the image",
  "category": "Most appropriate category name from the list",
  "urgency": "Low/Medium/High",
  "tags": "tag1, tag2, tag3"
}

Do not include any other text or formatting.
""";

    return await _callGeminiApi(prompt, imageBase64);
  }
  
  Future<bool> _checkForDuplicatesWithGemini(String imageBase64, String description) async {
    // Construct the prompt for duplicate detection
    final prompt = """You are an expert duplicate issue detector for a civic reporting app.
    
Analyze the provided image and description to determine if this is likely a duplicate of an existing issue.

Description: '$description'

Respond with a JSON object containing only a boolean field 'is_duplicate' with value true or false.
Example: {"is_duplicate": true} or {"is_duplicate": false}

Consider these factors:
1. Is this a common civic issue that's likely already reported?
2. Does the description suggest a recent problem that others would notice?
3. Is this in a high-traffic area where issues are frequently reported?

If you're uncertain, err on the side of marking it as not a duplicate (false).
""";

    // Call Gemini API
    final result = await _callGeminiApi(prompt, imageBase64);
    
    // Extract the duplicate status
    if (result != null && result.containsKey('is_duplicate')) {
      return result['is_duplicate'] as bool;
    }
    
    // Default to false if we couldn't determine
    return false;
  }
  
  Future<Map<String, dynamic>?> _callGeminiApi(String prompt, String imageBase64) async {
    final payload = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": imageBase64
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "maxOutputTokens": 500,
        "stopSequences": []
      }
    };

    developer.log("Sending request to Gemini", name: "ReportDetailsScreen");

    try {
      // Get geminiApiKey from secrets.dart
      if (geminiApiKey.isEmpty) {
        throw Exception('Gemini API key not configured');
      }

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) {
        developer.log("Widget not mounted after API call, returning null", name: "ReportDetailsScreen");
        return null;
      }

      developer.log("Gemini API response status: ${response.statusCode}", name: "ReportDetailsScreen");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        developer.log("Gemini Response: ${response.body}", name: "ReportDetailsScreen");
        
        if (result['candidates'] != null &&
            result['candidates'].isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          
          String aiResponse = result['candidates'][0]['content']['parts'][0]['text'].trim();
          developer.log("Raw AI response: $aiResponse", name: "ReportDetailsScreen");
          
          // Clean up the response and parse JSON
          aiResponse = aiResponse.replaceAll('``````', '').trim();
          
          // Find JSON object in the response
          int startIndex = aiResponse.indexOf('{');
          int endIndex = aiResponse.lastIndexOf('}');
          
          if (startIndex >= 0 && endIndex > startIndex) {
            aiResponse = aiResponse.substring(startIndex, endIndex + 1);
            developer.log("Cleaned AI response: $aiResponse", name: "ReportDetailsScreen");
            
            try {
                final jsonResponse = jsonDecode(aiResponse) as Map<String, dynamic>;
                developer.log("Successfully parsed JSON response: $jsonResponse", name: "ReportDetailsScreen");
                
                // For issue analysis, validate the response structure
                if (prompt.contains("description") && prompt.contains("category") && prompt.contains("urgency")) {
                  if (jsonResponse.containsKey('description') && 
                      jsonResponse.containsKey('category') && 
                      jsonResponse.containsKey('urgency')) {
                      
                    // Handle tags if present
                    if (jsonResponse.containsKey('tags')) {
                      String tags = jsonResponse['tags'].toString();
                      // Clean up tags if needed
                      tags = tags.replaceAll(RegExp(r'\[|\]'), '').trim();
                      _tagsController.text = tags;
                      developer.log("Tags set from AI: $tags", name: "ReportDetailsScreen");
                    }
                    
                    // Validate urgency value
                    String urgency = jsonResponse['urgency'].toString();
                    if (!['Low', 'Medium', 'High'].contains(urgency)) {
                      developer.log("Invalid urgency value: $urgency, setting to Medium", name: "ReportDetailsScreen");
                      jsonResponse['urgency'] = 'Medium';
                    }
                    
                    developer.log("Successfully parsed AI analysis: $jsonResponse", name: "ReportDetailsScreen");
                  } else {
                    developer.log("Missing required fields in AI response", name: "ReportDetailsScreen");
                  }
                }
                
                return jsonResponse;
              } catch (e) {
                developer.log("Failed to parse JSON response: $e", name: "ReportDetailsScreen");
              }
          } else {
            developer.log("No valid JSON found in response", name: "ReportDetailsScreen");
          }
        } else {
          developer.log("Invalid response structure from Gemini", name: "ReportDetailsScreen");
        }
      } else {
        developer.log("Gemini API Error: ${response.statusCode} - ${response.body}", name: "ReportDetailsScreen");
        
        if (response.statusCode == 400) {
          // Check for specific error messages
          try {
            final errorResult = jsonDecode(response.body);
            if (errorResult['error'] != null && errorResult['error']['message'] != null) {
              throw Exception('API Error: ${errorResult['error']['message']}');
            }
          } catch (_) {
            throw Exception('Bad Request - Check API key and request format');
          }
        } else if (response.statusCode == 403) {
          throw Exception('API key invalid or quota exceeded');
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      }
    } on TimeoutException {
      developer.log("Gemini API timeout", name: "ReportDetailsScreen");
      throw Exception('Request timeout - please try again');
    } catch (e) {
      developer.log("Error calling Gemini API: $e", name: "ReportDetailsScreen");
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingDescription = false;
          _isSuggestingCategory = false;
          _isDetectingUrgency = false;
        });
      } else {
        developer.log("Widget not mounted in finally block", name: "ReportDetailsScreen");
      }
    }
    
    return null;
  }

  Future<void> _submitReport() async {
    if (_connectivityService == null || _offlineSyncService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Services not initialized. Please try again.')),
      );
      return;
    }

    final userProfileService = Provider.of<UserProfileService>(context, listen: false);
    final AppUser? appUser = userProfileService.currentUserProfile;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryModel == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.category)));
      return;
    }
    if (_currentPosition == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.description)));
      return;
    }
    if (appUser == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.description)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final connectivityResult = await _connectivityService?.checkConnectivity() ?? ConnectivityResult.none;

      if (connectivityResult == ConnectivityResult.none) {
        // OFFLINE MODE: Save issue locally
        developer.log('Submitting issue offline', name: 'ReportDetailsScreen');
        
        final locationModel = LocationModel(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          address: _currentAddress ?? 'Address not available',
        );

        final tagsList = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        // Save issue offline using OfflineSyncService
        final localId = await _offlineSyncService!.saveIssueOffline(
          description: _descriptionController.text.trim(),
          category: _selectedCategoryModel!.name,
          urgency: _detectedUrgency, // Will be "Medium" for offline issues
          tags: tagsList,
          imagePath: widget.imagePath,
          location: locationModel,
          user: appUser,
        );
        
        developer.log('Issue saved offline with local ID: $localId', name: 'ReportDetailsScreen');

        if (mounted) {
          // Show "Issue saved locally" confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Issue saved locally. It will sync when you\'re back online.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );

          // Navigate back to main screen
          Navigator.of(context).pushNamedAndRemoveUntil('/app', (Route<dynamic> route) => false);
        }
        
        return;
      }

      // ONLINE MODE: Proceed with existing upload logic
      developer.log('Submitting issue online', name: 'ReportDetailsScreen');
      
      // Get the image data as a Base64 string
      final imageBytes = await File(widget.imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Use Gemini API directly for duplicate detection instead of Cloud Function
      final isDuplicate = await _checkForDuplicatesWithGemini(
          base64Image,
          _descriptionController.text.trim()
      );

      // If it's a duplicate, find the most similar issue
      String? existingIssueId;
      String? existingIssueTitle;

      if (isDuplicate) {
        // Query recent issues to find the most similar one
        final recentIssues = await FirebaseFirestore.instance
            .collection('issues')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get();

        if (recentIssues.docs.isNotEmpty) {
          // For simplicity, we'll just use the most recent issue
          // In a production app, you might want to implement more sophisticated matching
          final mostRecentIssue = recentIssues.docs.first;
          existingIssueId = mostRecentIssue.id;
          existingIssueTitle = mostRecentIssue.data()['title'] as String? ?? 'Untitled Issue';
        }
      }

      // Handle the response
      if (isDuplicate && existingIssueId != null) {
        if (!mounted) return;

        // Show dialog for duplicate found
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Similar Issue Found"),
            content: Text(
                "This seems related to an existing report:\n\n'${existingIssueTitle ?? 'Untitled Issue'}'\n\nWould you like to add your photo and info as evidence to it?"
            ),
            actions: [
              TextButton(
                child: const Text("Create New Anyway"),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                child: const Text("Yes, Add to Existing"),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
        );

        if (result == true) {
          // User chose to collaborate
          if (!mounted) return;
          final issueDoc = await FirebaseFirestore.instance.collection('issues').doc(existingIssueId).get();
          if (issueDoc.exists) {
            if (!mounted) return;
            final existingIssue = Issue.fromFirestore(issueDoc.data()!, issueDoc.id);
            Navigator.push(context, MaterialPageRoute(builder: (context) =>
                IssueCollaborationScreen(issueId: existingIssueId!, issue: existingIssue)
            ));
          }
        } else {
          // User chose to create new anyway
          await _createNewIssue(appUser, isDuplicateOf: existingIssueId);
        }
      } else {
        // No duplicate found
        await _createNewIssue(appUser);
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log("Cloud function error: ${e.message}", name: "ReportDetailsScreen", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking for duplicates: ${e.message}. Submitting as new issue.")),
        );
        await _createNewIssue(appUser);
      }
    } catch (e) {
      developer.log("Error during submission process: $e", name: "ReportDetailsScreen", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e. Submitting as new issue.")),
        );
        await _createNewIssue(appUser);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }


  Future<void> _createNewIssue(AppUser appUser, {String? isDuplicateOf}) async {
    if (_currentPosition == null || _selectedCategoryModel == null) return;

    // Save the issue locally before attempting to upload to Firebase.
    // This ensures that even if the online submission fails, a record is kept locally.

    try {
      final String? imageUrl = await _imageUploadService.uploadImage(File(widget.imagePath));
      if (imageUrl == null) throw Exception('Failed to upload image.');

      final String assignedDepartment = _selectedCategoryModel!.defaultDepartment;
      final List<String> tagsList = _tagsController.text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

      final Map<String, dynamic> issueData = {
        'description': _descriptionController.text.trim(),
        'category': _selectedCategoryModel!.name,
        'urgency': _detectedUrgency,
        'tags': tagsList.isNotEmpty ? tagsList : null,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'address': _currentAddress ?? 'Address not available',
        },
        'userId': appUser.uid,
        'username': appUser.username!,
        'status': 'Reported',
        'isUnresolved': true,
        'assignedDepartment': assignedDepartment,
        'upvotes': 0,
        'downvotes': 0,
        'voters': {},
        'commentsCount': 0,
        'affectedUsersCount': 1,
        'affectedUserIds': [appUser.uid],
        if (isDuplicateOf != null) 'duplicateOfIssueId': isDuplicateOf,
      };

      await _firestoreService.addIssue(issueData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.description)));
        Navigator.of(context).pushNamedAndRemoveUntil('/app', (Route<dynamic> route) => false);
      }
    } catch (e) {
      developer.log('Failed to create new issue: ${e.toString()}', name: 'ReportDetailsScreen', error: e);
      if (mounted) {
        final errorMsg = e.toString();
        final endIndex = math.min(100, errorMsg.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: ${errorMsg.substring(0, endIndex)}...')),
        );
      }
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high': return Colors.red.shade700;
      case 'medium': return Colors.orange.shade700;
      case 'low': return Colors.blue.shade700;
      default: return Colors.grey.shade600;
    }
  }

  IconData _getUrgencyIcon(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high': return Icons.priority_high;
      case 'medium': return Icons.warning_amber;
      case 'low': return Icons.info_outline;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    
    bool isAnyProcessing = _isGeneratingDescription || _isSuggestingCategory || _isDetectingUrgency;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.report),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isLoadingInitialData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_analysisStatus.isNotEmpty ? _analysisStatus : AppLocalizations.of(context)!.description),
                  if (_analysisStatus.contains("failed") || _analysisStatus.contains("Error"))
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          _fetchInitialData();
                        },
                        child: Text(AppLocalizations.of(context)!.description),
                      ),
                    ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image preview
                    if (widget.imagePath.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.file(File(widget.imagePath), fit: BoxFit.contain, height: 200),
                      ),
                    SizedBox(height: screenHeight * 0.03),

                    // Location (read-only)
                    Text(AppLocalizations.of(context)!.map, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: screenHeight * 0.008),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey[350]!)
                      ),
                      child: Text(
                        _currentAddress ?? (_currentPosition != null 
                          ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}' 
                          : 'Fetching location...'),
                        style: textTheme.bodyLarge?.copyWith(fontSize: 15),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Description (AI-generated but editable)
                    Text(AppLocalizations.of(context)!.description, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: screenHeight * 0.008),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: isAnyProcessing ? AppLocalizations.of(context)!.description : AppLocalizations.of(context)!.description,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      readOnly: isAnyProcessing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.description;
                        }
                        if (value.trim().length < 10) {
                          return AppLocalizations.of(context)!.description;
                        }
                        return null;
                      },
                    ),
                    
                    if (isAnyProcessing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 8),
                            Text(
                              _isGeneratingDescription ? "Generating description..." :
                              _isDetectingUrgency ? "Detecting urgency..." :
                              _isSuggestingCategory ? "Suggesting category..." : "Analyzing...",
                              style: const TextStyle(fontStyle: FontStyle.italic)
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Category (AI-suggested but changeable)
                    Text(AppLocalizations.of(context)!.category, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: screenHeight * 0.008),
                    DropdownButtonFormField<CategoryModel>(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.category,
                      ),
                      value: _selectedCategoryModel,
                      isExpanded: true,
                      items: _fetchedCategories.map((CategoryModel category) {
                        return DropdownMenuItem<CategoryModel>(
                          value: category,
                          child: Text(category.name, style: textTheme.bodyLarge?.copyWith(fontSize: 15)),
                        );
                      }).toList(),
                      onChanged: (CategoryModel? newValue) {
                        setState(() {
                          _selectedCategoryModel = newValue;
                        });
                      },
                      validator: (value) => value == null ? AppLocalizations.of(context)!.category : null,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Urgency (AI-determined, read-only when online, defaulted to Medium when offline)
                    Text(AppLocalizations.of(context)!.urgency, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: screenHeight * 0.008),
                    StreamBuilder<ConnectivityResult>(
                      stream: Provider.of<ConnectivityService>(context, listen: false).connectivityStream,
                      builder: (context, snapshot) {
                        final isOffline = snapshot.data == ConnectivityResult.none;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isOffline ? Colors.grey[200] : (_isDetectingUrgency ? Colors.yellow[50] : (_detectedUrgency == null ? Colors.grey[100] : _getUrgencyColor(_detectedUrgency).withAlpha(26))),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: isOffline ? Colors.grey[400]! : (_isDetectingUrgency ? Colors.orange.shade300 :
                                     (_detectedUrgency == null ? Colors.grey[350]! : _getUrgencyColor(_detectedUrgency)))
                            )
                          ),
                          child: Row(
                            children: [
                              ...[
                              Icon(
                                _getUrgencyIcon(_detectedUrgency!),
                                color: isOffline ? Colors.grey[600] : _getUrgencyColor(_detectedUrgency!),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                              Expanded(
                                child: Text(
                                  isOffline ? AppLocalizations.of(context)!.medium : (_isDetectingUrgency ? "Detecting urgency..." :
                                  (_detectedUrgency ?? "Not determined")),
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    color: isOffline ? Colors.grey[600] : (_isDetectingUrgency ? Colors.orange.shade800 :
                                           (_detectedUrgency == null ? Colors.grey[700] : _getUrgencyColor(_detectedUrgency))),
                                    fontStyle: _detectedUrgency == null && !_isDetectingUrgency && !isOffline ? FontStyle.italic : FontStyle.normal,
                                    fontWeight: _detectedUrgency != null || isOffline ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.lock_outline,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Tags (Optional)
                    Text(AppLocalizations.of(context)!.description, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: screenHeight * 0.008),
                    CustomTextField(
                      controller: _tagsController,
                      hintText: 'e.g., broken, urgent, road_hazard',
                      maxLines: 1,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Analysis Status (for debugging)
                    if (_analysisStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _analysisStatus.contains('complete') ? Colors.green[50] :
                                 _analysisStatus.contains('failed') || _analysisStatus.contains('Error') ? Colors.red[50] :
                                 Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _analysisStatus.contains('complete') ? Colors.green :
                                   _analysisStatus.contains('failed') || _analysisStatus.contains('Error') ? Colors.red :
                                   Colors.blue,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _analysisStatus.contains('complete') ? Icons.check_circle :
                              _analysisStatus.contains('failed') || _analysisStatus.contains('Error') ? Icons.error :
                              Icons.info,
                              size: 16,
                              color: _analysisStatus.contains('complete') ? Colors.green :
                                     _analysisStatus.contains('failed') || _analysisStatus.contains('Error') ? Colors.red :
                                     Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_analysisStatus, style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),

                    // Analyze Again button
                    if (widget.imagePath.isNotEmpty && !_isLoadingInitialData)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: isAnyProcessing ? null : () async {
                            setState(() {
                              _analysisStatus = "Analyzing image with AI again...";
                            });
                            await _performAIAnalysis();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context)!.description),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[800],
                          ),
                        ),
                      ),
                    
                    // Submit button
                    AuthButton(
                      text: AppLocalizations.of(context)!.submitIssue,
                      onPressed: (_isLoadingInitialData || isAnyProcessing) ? null : _submitReport,
                      isLoading: _isSubmitting,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
    );
  }
}
