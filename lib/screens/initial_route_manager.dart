import 'package:flutter/material.dart';
import 'package:modern_auth_app/screens/language_selection_screen.dart';
import 'package:modern_auth_app/main.dart';
import 'package:modern_auth_app/services/localization_service.dart';

class InitialRouteManager extends StatefulWidget {
  const InitialRouteManager({super.key});

  @override
  State<InitialRouteManager> createState() => _InitialRouteManagerState();
}

class _InitialRouteManagerState extends State<InitialRouteManager> {
  late Future<bool> _hasSelectedLanguageFuture;

  @override
  void initState() {
    super.initState();
    _hasSelectedLanguageFuture = _checkLanguageSelection();
  }

  Future<bool> _checkLanguageSelection() async {
    return await LocalizationService.hasSelectedLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSelectedLanguageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          final bool hasSelectedLanguage = snapshot.data ?? false;
          return hasSelectedLanguage
              ? const InitialAuthCheck()
              : const LanguageSelectionScreen();
        }
      },
    );
  }
}
