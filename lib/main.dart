// lib/main.dart

// Import necessary packages for UI, state management, and screens
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rentoflow/providers/firebase_provider.dart';
import 'package:rentoflow/screens/auth_screen.dart';
import 'package:rentoflow/screens/owner_dashboard_screen.dart';

// The main entry point for the application.
void main() async {
  // 1. Ensure Flutter bindings are initialized before running the app.
  // This is crucial for using plugins like Firebase before the UI is built.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale data for date formatting
  await initializeDateFormatting();

  // 2. Run the app, wrapping it with ChangeNotifierProvider.
  // This is the key step:
  //  - It creates an instance of your FirebaseProvider.
  //  - The constructor of your FirebaseProvider should be handling the
  //    Firebase.initializeApp() call.
  //  - This makes the provider instance available to all widgets down the tree.
  runApp(
    ChangeNotifierProvider(
      create: (context) => FirebaseProvider(),
      child: const RentOFlowApp(),
    ),
  );
}

// The root widget for the RentOFlow application.
class RentOFlowApp extends StatelessWidget {
  const RentOFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Listen to the FirebaseProvider to get the current state.
    // This widget will rebuild whenever notifyListeners() is called in the provider,
    // for example, when Firebase initialization finishes or the user logs in/out.
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    // --- State 1: Loading ---
    // Show a loading indicator while the FirebaseProvider is initializing.
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
                // Display an error message if one exists
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

    // --- State 2: Loaded ---
    // 4. Determine which screen to show based on the user's authentication status
    //    which is managed by the FirebaseProvider.
    Widget initialScreen;
    if (firebaseProvider.currentUser != null && !firebaseProvider.currentUser!.isAnonymous) {
      // If the user is logged in, show the owner dashboard by default.
      initialScreen = const OwnerDashboardScreen();
    } else {
      // If no user is logged in, show the authentication screen.
      initialScreen = const AuthScreen();
    }

    // Build the main app with a custom theme.
    return MaterialApp(
      title: 'RentOFlow',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF81C784), // Light Green
        canvasColor: Colors.grey[50],
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: const CardThemeData( // CORRECTED: Was CardTheme, now is CardThemeData
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey,
          elevation: 2.0,
          shape: RoundedRectangleBorder(
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
          bodyLarge: TextStyle(fontFamily: 'Inter'),
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
            borderSide: const BorderSide(color: Color(0xFF81C784), width: 2.0),
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
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
          accentColor: const Color(0xFFFFD54F), // Light Gold accent
          backgroundColor: Colors.grey[50],
        ).copyWith(
          secondary: const Color(0xFFFFD54F), // Modern way to set accent color
        ),
      ),
      // Set the determined initial screen as the home screen.
      home: initialScreen,
    );
  }
}
