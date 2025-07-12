// lib/screens/persona_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rentoflow/common/widgets.dart'; // For CustomCard and showSnackBar
import 'package:rentoflow/providers/firebase_provider.dart'; // For FirebaseProvider
import 'package:rentoflow/screens/owner_dashboard_screen.dart';
import 'package:rentoflow/screens/tenant_dashboard_screen.dart';
import 'package:rentoflow/screens/super_admin_dashboard_screen.dart';

class PersonaSelectionScreen extends StatefulWidget {
  const PersonaSelectionScreen({super.key});

  @override
  State<PersonaSelectionScreen> createState() => _PersonaSelectionScreenState();
}

class _PersonaSelectionScreenState extends State<PersonaSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    final userIdDisplay = firebaseProvider.userId != null
        ? Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'User ID: ${firebaseProvider.userId!.substring(0, 8)}...',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  const Color(0xFFA5D6A7),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: CustomCard( // Using CustomCard here
                  elevation: 12.0,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        'https://placehold.co/150x60/227d49/ffffff?text=RentOFlow',
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
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
                        'Welcome to RentOFlow!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your all-in-one rental property management system.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Select Your Persona',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPersonaButton(
                        context,
                        'Property Owner',
                        Icons.business_center_rounded,
                        () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const OwnerDashboardScreen()),
                          );
                        },
                        const Color(0xFF81C784),
                      ),
                      const SizedBox(height: 16),
                      _buildPersonaButton(
                        context,
                        'Tenant',
                        Icons.person,
                        () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const TenantDashboardScreen()),
                          );
                        },
                        const Color(0xFFFFD54F),
                      ),
                      const SizedBox(height: 16),
                      _buildPersonaButton(
                        context,
                        'Super Admin',
                        Icons.admin_panel_settings,
                        () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SuperAdminDashboardScreen()),
                          );
                        },
                        Colors.grey[700]!,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'A free version is available for owners managing one tenant. Pro users can register multiple tenants at 1/- per day per tenant.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          userIdDisplay,
        ],
      ),
    );
  }

  Widget _buildPersonaButton(BuildContext context, String text, IconData icon, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
        ),
      ),
    );
  }
}
