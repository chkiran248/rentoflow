// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:rentoflow/common/widgets.dart';
import 'package:rentoflow/providers/firebase_provider.dart';
import 'package:rentoflow/screens/persona_selection_screen.dart';

enum AuthMode { login, signup }
enum AuthMethod { email, phone }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _authMode = AuthMode.login;
  AuthMethod _authMethod = AuthMethod.email;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login;
      _otpSent = false;
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _otpController.clear();
      Provider.of<FirebaseProvider>(context, listen: false).clearErrorMessage();
    });
  }

  void _switchAuthMethod(AuthMethod method) {
    setState(() {
      _authMethod = method;
      _otpSent = false;
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _otpController.clear();
      Provider.of<FirebaseProvider>(context, listen: false).clearErrorMessage();
    });
  }

  Future<void> _submitAuthForm() async {
    setState(() {
      _isLoading = true;
    });
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);

    try {
      UserCredential? userCredential;
      if (_authMethod == AuthMethod.email) {
        if (_authMode == AuthMode.login) {
          userCredential = await firebaseProvider.signInWithEmailPassword(
            _emailController.text,
            _passwordController.text,
          );
        } else {
          userCredential = await firebaseProvider.signUpWithEmailPassword(
            _emailController.text,
            _passwordController.text,
          );
        }
      } else {
        if (!_otpSent) {
          String phoneNumber = _phoneController.text.trim();
          if (!phoneNumber.startsWith('+91')) {
            phoneNumber = '+91$phoneNumber';
          }
          await firebaseProvider.sendOtp(phoneNumber);
          setState(() {
            _otpSent = true;
          });
          showSnackBar(context, 'OTP sent to your phone.');
        } else {
          userCredential = await firebaseProvider.verifyOtp(_otpController.text);
        }
      }

      if (userCredential != null && mounted) {
        showSnackBar(context, '${_authMode == AuthMode.login ? 'Logged in' : 'Signed up'} successfully!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PersonaSelectionScreen()),
        );
      } else if (firebaseProvider.errorMessage != null) {
        showSnackBar(context, firebaseProvider.errorMessage!, isError: true);
      }
    } catch (e) {
      showSnackBar(context, 'An unexpected error occurred: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              const Color(0xFF8cc045),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 12.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://placehold.co/150x60/227d49/ffffff?text=RentOFlow',
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 150,
                        height: 60,
                        color: const Color(0xFF227d49),
                        alignment: Alignment.center,
                        child: const Text('RentOFlow',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _authMode == AuthMode.login ? 'Login to RentOFlow' : 'Sign Up for RentOFlow',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ToggleButtons(
                      isSelected: [
                        _authMethod == AuthMethod.email,
                        _authMethod == AuthMethod.phone,
                      ],
                      onPressed: (index) {
                        _switchAuthMethod(index == 0 ? AuthMethod.email : AuthMethod.phone);
                      },
                      borderRadius: BorderRadius.circular(10),
                      selectedColor: Colors.white,
                      fillColor: Theme.of(context).primaryColor,
                      color: Colors.grey[700],
                      borderColor: Colors.grey[300],
                      selectedBorderColor: Theme.of(context).primaryColor,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.email),
                              SizedBox(width: 8),
                              Text('Email/Password'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.phone),
                              SizedBox(width: 8),
                              Text('Phone/OTP'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_authMethod == AuthMethod.email) ...[
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                    ],
                    if (_authMethod == AuthMethod.phone) ...[
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g., 9876543210 (10 digits)',
                          prefixText: '+91 ',
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                      const SizedBox(height: 16),
                      if (_otpSent)
                        TextField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'OTP',
                            hintText: 'Enter 6-digit OTP',
                            prefixIcon: Icon(Icons.sms_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                    ],
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitAuthForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              ),
                              child: Text(
                                _authMode == AuthMode.login
                                    ? (_authMethod == AuthMethod.email ? 'LOGIN' : (_otpSent ? 'VERIFY OTP' : 'SEND OTP'))
                                    : 'SIGN UP',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _switchAuthMode,
                      child: Text(
                        _authMode == AuthMode.login
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    if (firebaseProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          firebaseProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}