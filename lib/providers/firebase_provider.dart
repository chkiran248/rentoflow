// lib/providers/firebase_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs
import 'dart:convert'; // For json.decode

class FirebaseProvider extends ChangeNotifier {
  FirebaseApp? _firebaseApp;
  FirebaseFirestore? _db;
  FirebaseAuth? _auth;
  User? _currentUser;
  String? _userId;
  bool _loadingFirebase = true;
  String? _errorMessage;
  ConfirmationResult? _confirmationResult; // For phone auth
  String? _canvasAppId; // New: To store the Canvas app ID

  FirebaseApp? get firebaseApp => _firebaseApp;
  FirebaseFirestore? get db => _db;
  FirebaseAuth? get auth => _auth;
  User? get currentUser => _currentUser;
  String? get userId => _userId;
  bool get loadingFirebase => _loadingFirebase;
  String? get errorMessage => _errorMessage;
  String? get canvasAppId => _canvasAppId; // New: Getter for Canvas app ID

  FirebaseProvider() {
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      const String appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');
      _canvasAppId = appId; // Use the local variable here
      const String firebaseConfigJson = String.fromEnvironment('FIREBASE_CONFIG', defaultValue: '{}');
      final Map<String, dynamic> firebaseConfig = firebaseConfigJson.isNotEmpty
          ? Map<String, dynamic>.from(json.decode(firebaseConfigJson))
          : {};

      if (firebaseConfig.isEmpty) {
        _errorMessage = "Firebase config is missing or empty.";
        _loadingFirebase = false;
        notifyListeners();
        return;
      }

      _firebaseApp = await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseConfig['apiKey'] ?? 'YOUR_API_KEY',
          appId: firebaseConfig['appId'] ?? 'YOUR_APP_ID',
          messagingSenderId: firebaseConfig['messagingSenderId'] ?? 'YOUR_MESSAGING_SENDER_ID',
          projectId: firebaseConfig['projectId'] ?? 'YOUR_PROJECT_ID',
          storageBucket: firebaseConfig['storageBucket'] ?? 'YOUR_STORAGE_BUCKET',
        ),
      );

      // Use null assertion operator '!' because _firebaseApp is guaranteed to be non-null after initializeApp
      _db = FirebaseFirestore.instanceFor(app: _firebaseApp!);
      _auth = FirebaseAuth.instanceFor(app: _firebaseApp!);

      // Listen for auth state changes first
      _auth!.authStateChanges().listen((User? user) {
        _currentUser = user;
        if (user != null) {
          _userId = user.uid;
          debugPrint("Auth state changed. User ID: $_userId");
        } else {
          _userId = const Uuid().v4(); // Generate a new UUID for anonymous/unauthenticated users
          debugPrint("Auth state changed. No user, generated random ID: $_userId");
        }
        _loadingFirebase = false; // Set loading to false once initial auth state is determined
        notifyListeners();
      });

      // Try to sign in with custom token if available, otherwise anonymous sign-in
      const String initialAuthToken = String.fromEnvironment('INITIAL_AUTH_TOKEN', defaultValue: '');
      if (initialAuthToken.isNotEmpty) {
        await _auth!.signInWithCustomToken(initialAuthToken);
        debugPrint("Signed in with custom token.");
      } else if (_auth!.currentUser == null) { // Only sign in anonymously if no user is already logged in
        await _auth!.signInAnonymously();
        debugPrint("Signed in anonymously.");
      }

    } catch (e) {
      debugPrint("Error initializing Firebase: $e");
      _errorMessage = "Error initializing Firebase: $e";
      _loadingFirebase = false;
    } finally {
      notifyListeners();
    }
  }

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

  // Phone number authentication - Step 1: Send OTP
  Future<void> sendOtp(String phoneNumber) async {
    try {
      _errorMessage = null;
      notifyListeners();
      // For mobile platforms (Android/iOS), Firebase handles reCAPTCHA automatically.
      // RecaptchaVerifier is primarily for web.
      _confirmationResult = await _auth!.signInWithPhoneNumber(
        phoneNumber,
        // Removed RecaptchaVerifier as it's not typically needed or directly configured for mobile.
        // The Firebase SDK handles the underlying verification mechanisms (e.g., SafetyNet, DeviceCheck).
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

  // Phone number authentication - Step 2: Verify OTP
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
      _userId = const Uuid().v4(); // Ensure a new anonymous ID after sign out
      notifyListeners();
      debugPrint("User signed out.");
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
