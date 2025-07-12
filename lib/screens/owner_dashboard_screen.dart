// lib/screens/owner_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

import 'package:rentoflow/common/widgets.dart';
import 'package:rentoflow/common/extensions.dart';
import 'package:rentoflow/providers/firebase_provider.dart';
import 'package:rentoflow/screens/persona_selection_screen.dart';
import 'package:rentoflow/screens/auth_screen.dart';
import 'package:rentoflow/common/app_navigation_bar.dart';
import 'package:rentoflow/screens/profile_view.dart' as profile_screen;
import 'package:rentoflow/services/data_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _uuid = const Uuid();
  final TextEditingController _propertyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _rentPriceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedPropertyType = 'Flat';
  final List<String> _propertyTypes = [
    'Flat', 'Shared', 'Land', 'Hostel/PG', 'Co-Living', 'Studio'
  ];

  @override
  void dispose() {
    _propertyNameController.dispose();
    _addressController.dispose();
    _rentPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addProperty(BuildContext context) async {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    final db = firebaseProvider.db;
    final userId = firebaseProvider.userId;
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    if (db == null || userId == null) {
      showSnackBar(context, "Firebase not initialized or user not logged in.", isError: true);
      return;
    }

    if (_propertyNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _rentPriceController.text.isEmpty) {
      showSnackBar(context, "Please fill in all required fields.", isError: true);
      return;
    }

    final newProperty = {
      'id': _uuid.v4(),
      'name': _propertyNameController.text,
      'address': _addressController.text,
      'type': _selectedPropertyType,
      'rentPrice': double.tryParse(_rentPriceController.text) ?? 0.0,
      'status': 'Vacant',
      'description': _descriptionController.text,
      'photos': ['https://placehold.co/600x400/2ca24a/ffffff?text=Property'],
      'facilities': 'Wi-Fi, AC, Geyser',
      'tenants': [],
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await db.collection('artifacts/$appId/users/$userId/properties').add(newProperty);
      showSnackBar(context, "Property added successfully!");
      Navigator.of(context).pop();
      _propertyNameController.clear();
      _addressController.clear();
      _rentPriceController.clear();
      _descriptionController.clear();
      _selectedPropertyType = 'Flat';
    } catch (e) {
      debugPrint("Error adding property: $e");
      showSnackBar(context, "Failed to add property: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userId = firebaseProvider.userId;

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Property Owner Portal',
        userId: userId ?? 'Loading...',
        userName: firebaseProvider.currentUser?.displayName ?? firebaseProvider.currentUser?.email ?? 'Owner',
        userEmail: firebaseProvider.currentUser?.email ?? '',
        onChangePersona: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PersonaSelectionScreen()),
          );
        },
        onSignOut: firebaseProvider.currentUser != null && !firebaseProvider.currentUser!.isAnonymous
            ? () async {
                await firebaseProvider.signOutUser();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            : null,
        onProfile: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => profile_screen.ProfileView(
                userName: firebaseProvider.currentUser?.displayName ?? firebaseProvider.currentUser?.email ?? 'Owner',
                userEmail: firebaseProvider.currentUser?.email ?? '',
              ),
            ),
          );
        },
      ),
      body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                  const SizedBox(height: 24),
                  _buildFinancialOverview(context),
                  const SizedBox(height: 24),
                  _buildPropertiesOverview(context),
                ],
              ),
            ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _showAddPropertyModal(context);
          },
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('Add New Property'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ca24a),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userId = firebaseProvider.userId;
    
    if (userId == null || firebaseProvider.db == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return FutureBuilder<QuerySnapshot>(
      future: firebaseProvider.db!.collection('artifacts/default-app-id/users/$userId/properties').get(),
      builder: (context, snapshot) {
        double totalRentalIncome = 0;
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalRentalIncome += (data['rentPrice'] as num?)?.toDouble() ?? 0;
          }
        }
        
        final totalInvested = totalRentalIncome * 0.3;
        final projectedIncome = totalInvested * pow(1.07, 20);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.8,
          children: [
            _buildFinancialCard(
              context,
              'Total Rental Income',
              totalRentalIncome.toLocaleString(),
              'Overall revenue from all properties.',
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
              LinearGradient(
                colors: [const Color(0xFF2ca24a), const Color(0xFF8cc045)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _buildFinancialCard(
              context,
              'Rental Income Invested',
              totalInvested.toLocaleString(),
              'Portion of income allocated to savings/investments.',
              const Icon(Icons.savings_outlined, color: Colors.white, size: 36),
              LinearGradient(
                colors: [const Color(0xFFc79e1c), Colors.amber[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _buildFinancialCard(
              context,
              'Projected Income (20 yrs)',
              projectedIncome.toLocaleString(),
              'Estimated income from savings after 20 years (7% annual growth).',
              const Icon(Icons.trending_up, color: Colors.white, size: 36),
              LinearGradient(
                colors: [Colors.green[700]!, Colors.green[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinancialCard(
      BuildContext context,
      String title,
      String value,
      String subtitle,
      Icon icon,
      Gradient gradient,
      ) {
    return CustomCard(
      color: Colors.transparent,
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesOverview(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userId = firebaseProvider.userId;
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_work_outlined, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: userId == null || firebaseProvider.db == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: firebaseProvider.db!.collection('artifacts/$appId/users/$userId/properties').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No properties added yet. Tap "Add New Property" to get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final property = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              title: Text(property['name'] ?? 'N/A'),
                              subtitle: Text(property['address'] ?? 'N/A'),
                              trailing: Text('₹${property['rentPrice']?.toString() ?? '0'}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddPropertyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: const Text('Add New Property'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _propertyNameController,
                      decoration: const InputDecoration(labelText: 'Property Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPropertyType,
                      decoration: const InputDecoration(labelText: 'Property Type'),
                      items: _propertyTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            _selectedPropertyType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rentPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Rent Price (per month)',
                        hintText: 'e.g., 15000',
                        prefixText: '₹ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _propertyNameController.clear();
                    _addressController.clear();
                    _rentPriceController.clear();
                    _descriptionController.clear();
                    _selectedPropertyType = 'Flat';
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addProperty(dialogContext);
                  },
                  child: const Text('Add Property'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}