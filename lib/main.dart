// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart'; // Removed unused import

import 'package:rentoflow/providers/firebase_provider.dart';
import 'package:rentoflow/screens/persona_selection_screen.dart';
import 'package:rentoflow/screens/auth_screen.dart'; // Import the new auth screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => FirebaseProvider(),
      child: const RentOFlowApp(),
    ),
  );
}

class RentOFlowApp extends StatelessWidget {
  const RentOFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    if (firebaseProvider.loadingFirebase) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Loading RentOFlow...",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                if (firebaseProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: ${firebaseProvider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine the initial screen based on authentication state
    Widget initialScreen;
    if (firebaseProvider.currentUser != null && !firebaseProvider.currentUser!.isAnonymous) {
      initialScreen = const PersonaSelectionScreen();
    } else {
      initialScreen = const AuthScreen(); // Redirect to AuthScreen if not authenticated
    }

    return MaterialApp(
      title: 'RentOFlow',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF227d49), // Dark Green
        canvasColor: Colors.grey[50], // Light gray background for app
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
          margin: EdgeInsets.zero, // No default margin
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 2.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16.0),
            ),
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          buttonColor: const Color(0xFF2ca24a),
          textTheme: ButtonTextTheme.primary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Inter'), // Placeholder for Inter font
          bodyMedium: TextStyle(fontFamily: 'Inter'),
          labelLarge: TextStyle(fontFamily: 'Inter'),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF8cc045), width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        // Color Scheme for a more modern look
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: const Color(0xFFc79e1c), // Gold/yellow accent
          backgroundColor: Colors.grey[50],
        ).copyWith(
          secondary: const Color(0xFFc79e1c), // Accent color
        ),
      ),
      home: initialScreen,
    );
  }
}
