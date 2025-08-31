import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:modern_auth_app/services/localization_service.dart';
import 'package:modern_auth_app/services/locale_provider.dart';
import 'package:provider/provider.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? selectedLanguageCode;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LocalizationService.getSavedLanguage();
    if (savedLanguage != null) {
      setState(() {
        selectedLanguageCode = savedLanguage;
      });
    }
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Save the selected language
      await LocalizationService.setLocale(languageCode);

      // Update the locale provider to change the app language immediately
      if (mounted) {
        final localeProvider = Provider.of<LocaleProvider>(
          context,
          listen: false,
        );
        localeProvider.setLocale(Locale(languageCode));
      }

      // Navigate to the main app
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo
              Center(
                child: Image.asset(
                  'assets/icon/app_logo.png',
                  height: 120,
                  width: 120,
                ),
              ),

              const SizedBox(height: 40),

              // Welcome Text
              Text(
                l10n?.welcomeToNivaran ?? 'Welcome to Nivaran',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                l10n?.pleaseSelectYourPreferredLanguage ??
                    'Please select your preferred language',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Language Dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedLanguageCode ?? 'en',
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(Icons.language, color: Colors.blue),
                  ),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                    DropdownMenuItem(value: 'hi', child: Text('🇮🇳 हिन्दी')),
                    DropdownMenuItem(value: 'gu', child: Text('🇮🇳 ગુજરાતી')),
                    DropdownMenuItem(value: 'bn', child: Text('🇮🇳 বাংলা')),
                    DropdownMenuItem(value: 'ta', child: Text('🇮🇳 தமிழ்')),
                    DropdownMenuItem(value: 'te', child: Text('🇮🇳 తెలుగు')),
                    DropdownMenuItem(value: 'mr', child: Text('🇮🇳 मराठी')),
                    DropdownMenuItem(value: 'kn', child: Text('🇮🇳 ಕನ್ನಡ')),
                    DropdownMenuItem(value: 'ml', child: Text('🇮🇳 മലയാളം')),
                    DropdownMenuItem(value: 'pa', child: Text('🇮🇳 ਪੰਜਾਬੀ')),
                    DropdownMenuItem(value: 'or', child: Text('🇮🇳 ଓଡ଼ିଆ')),
                    DropdownMenuItem(value: 'as', child: Text('🇮🇳 অসমীয়া')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedLanguageCode = newValue;
                      });
                    }
                  },
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      selectedLanguageCode != null && !isLoading
                          ? () => _selectLanguage(selectedLanguageCode ?? 'en')
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            l10n?.continueButton ?? 'Continue',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 20),

              // Auto-detect option
              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          // Try to detect system language
                          final systemLocale = Localizations.localeOf(context);
                          final languageCode = systemLocale.languageCode;

                          // Check if system language is supported
                          final supportedLanguages = [
                            'en',
                            'hi',
                            'gu',
                            'bn',
                            'ta',
                            'te',
                            'mr',
                            'kn',
                            'ml',
                            'pa',
                            'or',
                          ];
                          if (supportedLanguages.contains(languageCode)) {
                            await _selectLanguage(languageCode);
                          } else {
                            // Default to English if system language not supported
                            await _selectLanguage('en');
                          }
                        },
                child: Text(
                  l10n?.useSystemLanguage ?? 'Use System Language',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
