import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';

  // Get the saved language code
  static Future<String?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  // Set the language and save it
  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Get the current locale
  static Future<Locale> getCurrentLocale() async {
    final savedLanguage = await getSavedLanguage();
    if (savedLanguage != null) {
      return Locale(savedLanguage);
    }
    // Default to English if no language is saved
    return const Locale('en');
  }

  // Check if user has selected a language
  static Future<bool> hasSelectedLanguage() async {
    final savedLanguage = await getSavedLanguage();
    return savedLanguage != null;
  }

  // Get supported locales
  static List<Locale> getSupportedLocales() {
    return const [
      Locale('en'), // English
      Locale('hi'), // Hindi
      Locale('gu'), // Gujarati
      Locale('bn'), // Bengali
      Locale('ta'), // Tamil
      Locale('te'), // Telugu
      Locale('mr'), // Marathi
      Locale('kn'), // Kannada
      Locale('ml'), // Malayalam
      Locale('pa'), // Punjabi
      Locale('or'), // Odia
    ];
  }

  // Get language name by code
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिन्दी';
      case 'gu':
        return 'ગુજરાતી';
      case 'bn':
        return 'বাংলা';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'mr':
        return 'मराठी';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'or':
        return 'ଓଡ଼ିଆ';
      default:
        return 'English';
    }
  }

  // Get language code by name
  static String getLanguageCode(String languageName) {
    switch (languageName) {
      case 'English':
        return 'en';
      case 'हिन्दी':
      case 'Hindi':
        return 'hi';
      case 'ગુજરાતી':
      case 'Gujarati':
        return 'gu';
      case 'বাংলা':
      case 'Bengali':
        return 'bn';
      case 'தமிழ்':
      case 'Tamil':
        return 'ta';
      case 'తెలుగు':
      case 'Telugu':
        return 'te';
      case 'मराठी':
      case 'Marathi':
        return 'mr';
      case 'ಕನ್ನಡ':
      case 'Kannada':
        return 'kn';
      case 'മലയാളം':
      case 'Malayalam':
        return 'ml';
      case 'ਪੰਜਾਬੀ':
      case 'Punjabi':
        return 'pa';
      case 'ଓଡ଼ିଆ':
      case 'Odia':
        return 'or';
      default:
        return 'en';
    }
  }
}
