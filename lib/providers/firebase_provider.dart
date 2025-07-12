// lib/providers/firebase_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs

// **IMPORTANT**: Make sure you have run `flutterfire configure` and this file exists.
import 'package:rentoflow/firebase_options.dart';

class FirebaseProvider extends ChangeNotifier {
  // Private variables to hold Firebase service instances and state
  FirebaseApp? _firebaseApp;
  FirebaseFirestore? _db;
  FirebaseAuth? _auth;
  User? _currentUser;
  String? _userId;
  bool _loadingFirebase = true;
  String? _errorMessage;
  ConfirmationResult? _confirmationResult; // For phone auth
  bool _justSignedUp = false; // New: Flag to track if a user just signed up

  // Public getters to expose state to the UI safely
  FirebaseApp? get firebaseApp => _firebaseApp;
  FirebaseFirestore? get db => _db;
  FirebaseAuth? get auth => _auth;
  User? get currentUser => _currentUser;
  String? get userId => _userId;
  bool get loadingFirebase => _loadingFirebase;
  String? get errorMessage => _errorMessage;
  bool get justSignedUp => _justSignedUp; // New: Getter for the signup flag

  // Constructor: Kicks off the Firebase initialization process
  FirebaseProvider() {
    _initializeFirebase();
  }

  // Handles the entire Firebase setup process using the recommended FlutterFire approach
  Future<void> _initializeFirebase() async {
    try {
      // **THE FIX IS HERE**: We now use the `firebase_options.dart` file.
      // This is the standard way and avoids all command-line issues.
      _firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firestore and Auth instances for the specific app
      _db = FirebaseFirestore.instanceFor(app: _firebaseApp!);
      _auth = FirebaseAuth.instanceFor(app: _firebaseApp!);

      // Set up a listener for authentication state changes
      _auth!.authStateChanges().listen((User? user) {
        _currentUser = user;
        if (user != null) {
          _userId = user.uid; // Use the Firebase UID for logged-in users
          debugPrint("Auth state changed. User ID: $_userId");
        } else {
          // When no user is logged in, we can still have a temporary ID if needed,
          // but the user object will be null.
          _userId = const Uuid().v4(); 
          debugPrint("Auth state changed. No user is signed in.");
        }
        _loadingFirebase = false; // Mark loading as complete
        notifyListeners();
      });

      // **CHANGE**: The automatic anonymous sign-in has been removed.
      // The app will now wait for the user to explicitly sign in.

    } catch (e) {
      debugPrint("Error initializing Firebase: $e");
      _errorMessage = "Error initializing Firebase: $e";
      _loadingFirebase = false;
      notifyListeners();
    }
  }

  // --- Authentication Methods ---

  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners();
      UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;
      _userId = _currentUser!.uid;
      _justSignedUp = true; // New: Set flag to true on successful signup
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'An unknown error occurred: $e';
      notifyListeners();
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners();
      UserCredential userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = userCredential.user;
      _userId = _currentUser!.uid;
      _justSignedUp = false; // New: Set flag to false on successful login
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // New: Better error handling for specific cases
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        _errorMessage = 'Invalid email or password. Please try again.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'An unknown error occurred: $e';
      notifyListeners();
      return null;
    }
  }

  // Phone Auth Step 1: Send OTP to the user's phone
  Future<void> sendOtp(String phoneNumber) async {
    try {
      _errorMessage = null;
      notifyListeners();
      _confirmationResult = await _auth!.signInWithPhoneNumber(
        phoneNumber,
      );
      notifyListeners();
      debugPrint("OTP sent to $phoneNumber");
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      debugPrint("Error sending OTP: $e");
    } catch (e) {
      _errorMessage = 'An unknown error occurred: $e';
      notifyListeners();
      debugPrint("Unknown error sending OTP: $e");
    }
  }

  // Phone Auth Step 2: Verify the OTP entered by the user
  Future<UserCredential?> verifyOtp(String otp) async {
    if (_confirmationResult == null) {
      _errorMessage = 'OTP not sent. Please try sending OTP again.';
      notifyListeners();
      return null;
    }
    try {
      _errorMessage = null;
      notifyListeners();
      UserCredential userCredential = await _confirmationResult!.confirm(otp);
      _currentUser = userCredential.user;
      _userId = _currentUser!.uid;
      _justSignedUp = false; // Assume phone login is for existing users
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      debugPrint("Error verifying OTP: $e");
      return null;
    } catch (e) {
      _errorMessage = 'An unknown error occurred during OTP verification: $e';
      notifyListeners();
      debugPrint("Unknown error verifying OTP: $e");
      return null;
    }
  }

  Future<void> signOutUser() async {
    if (_auth != null) {
      await _auth!.signOut();
      _currentUser = null;
      _userId = const Uuid().v4(); // Generate a new anonymous ID after sign out
      notifyListeners();
      debugPrint("User signed out.");
    }
  }

  // Utility method to clear error messages from the UI
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
