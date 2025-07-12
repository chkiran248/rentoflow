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
      // Check network connectivity before initializing Firebase
      _firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firestore and Auth instances for the specific app
      _db = FirebaseFirestore.instanceFor(app: _firebaseApp!);
      _auth = FirebaseAuth.instanceFor(app: _firebaseApp!);

      // Note: Firestore persistence is enabled by default on mobile platforms

      // Set up a listener for authentication state changes
      _auth!.authStateChanges().listen((User? user) {
        _currentUser = user;
        if (user != null) {
          _userId = user.uid;
          debugPrint("Auth state changed. User ID: $_userId");
        } else {
          _userId = const Uuid().v4();
          debugPrint("Auth state changed. No user is signed in.");
        }
        _loadingFirebase = false;
        notifyListeners();
      }, onError: (error) {
        debugPrint("Auth state listener error: $error");
        _errorMessage = "Authentication error: $error";
        _loadingFirebase = false;
        notifyListeners();
      });

    } catch (e) {
      debugPrint("Error initializing Firebase: $e");
      _errorMessage = _getErrorMessage(e);
      _loadingFirebase = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('permission')) {
      return 'Permission denied. Please check your Firebase configuration.';
    }
    return 'Error initializing Firebase: $error';
  }

  // --- Authentication Methods ---

  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    if (!_validateEmail(email)) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return null;
    }
    if (!_validatePassword(password)) {
      _errorMessage = 'Password must be at least 6 characters long.';
      notifyListeners();
      return null;
    }
    
    try {
      _errorMessage = null;
      notifyListeners();
      UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = userCredential.user;
      _userId = _currentUser!.uid;
      _justSignedUp = true;
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    if (!_validateEmail(email)) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return null;
    }
    
    try {
      _errorMessage = null;
      notifyListeners();
      UserCredential userCredential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = userCredential.user;
      _userId = _currentUser!.uid;
      _justSignedUp = false;
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return null;
    }
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
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
