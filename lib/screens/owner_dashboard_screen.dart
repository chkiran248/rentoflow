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
import 'package:rentoflow/services/reminder_service.dart';

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
  final TextEditingController _tenantNameController = TextEditingController();
  final TextEditingController _tenantPhoneController = TextEditingController();
  final TextEditingController _tenantEmailController = TextEditingController();
  String _selectedPropertyType = 'Flat';
  String? _selectedPropertyId;
  DateTime? _selectedDueDate;
  final List<String> _propertyTypes = [
    'Flat', 'Shared', 'Land', 'Hostel/PG', 'Co-Living', 'Studio'
  ];

  @override
  void dispose() {
    _propertyNameController.dispose();
    _addressController.dispose();
    _rentPriceController.dispose();
    _descriptionController.dispose();
    _tenantNameController.dispose();
    _tenantPhoneController.dispose();
    _tenantEmailController.dispose();
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
      'rentDueDate': _selectedDueDate?.day ?? 1,
      'status': 'Vacant',
      'description': _descriptionController.text,
      'photos': ['https://placehold.co/600x400/2ca24a/ffffff?text=Property'],
      'facilities': 'Wi-Fi, AC, Geyser',
      'tenants': [],
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await db.collection('artifacts/$appId/users/$userId/properties').add(newProperty);
      
      // Trigger reminder check for new property
      final reminderService = ReminderService(db, userId);
      await reminderService.checkAndCreateReminders();
      
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
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => profile_screen.ProfileView(
                    userName: firebaseProvider.currentUser?.displayName ?? firebaseProvider.currentUser?.email ?? 'Owner',
                    userEmail: firebaseProvider.currentUser?.email ?? '',
                  ),
                ),
              );
              break;
            case 2:
              showSnackBar(context, "Settings feature coming soon!");
              break;
          }
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        SizedBox(
          width: isSmallScreen ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () {
              _showAddPropertyModal(context);
            },
            icon: const Icon(Icons.add_home_work_outlined),
            label: const Text('Add New Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81C784),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 12
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(
          width: isSmallScreen ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () {
              _showAddTenantModal(context);
            },
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add New Tenant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 12
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.2,
          children: [
            _buildFinancialCard(
              context,
              'Total Rental Income',
              totalRentalIncome.toLocaleString(),
              'Overall revenue from all properties.',
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
              LinearGradient(
                colors: [const Color(0xFF81C784), const Color(0xFFA5D6A7)],
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
                colors: [const Color(0xFFFFD54F), const Color(0xFFFFE082)],
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
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis,
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
                          final propertyId = snapshot.data!.docs[index].id;
                          return Card(
                            child: ListTile(
                              title: Text(property['name'] ?? 'N/A'),
                              subtitle: Text(property['address'] ?? 'N/A'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('₹${property['rentPrice']?.toString() ?? '0'}'),
                                  const SizedBox(width: 8),
                                  Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                                ],
                              ),
                              onTap: () => _showEditPropertyModal(context, propertyId, property),
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
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          helpText: 'Select Rent Due Date',
                        );
                        if (picked != null) {
                          setModalState(() {
                            _selectedDueDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDueDate != null
                                  ? 'Due Date: ${_selectedDueDate!.day}${_getOrdinalSuffix(_selectedDueDate!.day)} of every month'
                                  : 'Select Rent Due Date',
                              style: TextStyle(
                                color: _selectedDueDate != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    _selectedDueDate = null;
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

  void _showEditPropertyModal(BuildContext context, String propertyId, Map<String, dynamic> property) {
    _propertyNameController.text = property['name'] ?? '';
    _addressController.text = property['address'] ?? '';
    _rentPriceController.text = property['rentPrice']?.toString() ?? '';
    _descriptionController.text = property['description'] ?? '';
    _selectedPropertyType = property['type'] ?? 'Flat';
    _selectedDueDate = property['rentDueDate'] != null ? DateTime(2024, 1, property['rentDueDate']) : null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: const Text('Edit Property'),
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
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          helpText: 'Select Rent Due Date',
                        );
                        if (picked != null) {
                          setModalState(() {
                            _selectedDueDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDueDate != null
                                  ? 'Due Date: ${_selectedDueDate!.day}${_getOrdinalSuffix(_selectedDueDate!.day)} of every month'
                                  : 'Select Rent Due Date',
                              style: TextStyle(
                                color: _selectedDueDate != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    _clearForm();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateProperty(dialogContext, propertyId);
                  },
                  child: const Text('Update Property'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateProperty(BuildContext context, String propertyId) async {
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

    final updatedProperty = {
      'name': _propertyNameController.text,
      'address': _addressController.text,
      'type': _selectedPropertyType,
      'rentPrice': double.tryParse(_rentPriceController.text) ?? 0.0,
      'rentDueDate': _selectedDueDate?.day ?? 1,
      'description': _descriptionController.text,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await db.collection('artifacts/$appId/users/$userId/properties').doc(propertyId).update(updatedProperty);
      
      // Trigger reminder check for updated property
      final reminderService = ReminderService(db, userId);
      await reminderService.checkAndCreateReminders();
      
      showSnackBar(context, "Property updated successfully!");
      Navigator.of(context).pop();
      _clearForm();
    } catch (e) {
      debugPrint("Error updating property: $e");
      showSnackBar(context, "Failed to update property: $e", isError: true);
    }
  }

  void _clearForm() {
    _propertyNameController.clear();
    _addressController.clear();
    _rentPriceController.clear();
    _descriptionController.clear();
    _selectedPropertyType = 'Flat';
    _selectedDueDate = null;
  }

  void _addTenant(BuildContext context) async {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    final db = firebaseProvider.db;
    final userId = firebaseProvider.userId;
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    if (db == null || userId == null) {
      showSnackBar(context, "Firebase not initialized or user not logged in.", isError: true);
      return;
    }

    if (_tenantNameController.text.isEmpty ||
        _tenantPhoneController.text.isEmpty ||
        _selectedPropertyId == null) {
      showSnackBar(context, "Please fill in all required fields.", isError: true);
      return;
    }

    final newTenant = {
      'id': _uuid.v4(),
      'name': _tenantNameController.text,
      'phone': _tenantPhoneController.text,
      'email': _tenantEmailController.text,
      'propertyId': _selectedPropertyId,
      'status': 'Active',
      'checkInDate': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await db.collection('artifacts/$appId/users/$userId/tenants').add(newTenant);
      
      // Update property status to Occupied
      await db.collection('artifacts/$appId/users/$userId/properties').doc(_selectedPropertyId!).update({
        'status': 'Occupied',
        'tenantId': newTenant['id'],
      });
      
      showSnackBar(context, "Tenant added successfully!");
      Navigator.of(context).pop();
      _tenantNameController.clear();
      _tenantPhoneController.clear();
      _tenantEmailController.clear();
      _selectedPropertyId = null;
    } catch (e) {
      debugPrint("Error adding tenant: $e");
      showSnackBar(context, "Failed to add tenant: $e", isError: true);
    }
  }

  void _showAddTenantModal(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    final db = firebaseProvider.db;
    final userId = firebaseProvider.userId;
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: const Text('Add New Tenant'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tenantNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tenant Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tenantPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tenantEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: db?.collection('artifacts/$appId/users/$userId/properties')
                          .where('status', isEqualTo: 'Vacant')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No vacant properties available');
                        }
                        
                        return DropdownButtonFormField<String>(
                          value: _selectedPropertyId,
                          decoration: const InputDecoration(
                            labelText: 'Select Property',
                            prefixIcon: Icon(Icons.home),
                          ),
                          items: snapshot.data!.docs.map((doc) {
                            final property = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(property['name'] ?? 'N/A'),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setModalState(() {
                              _selectedPropertyId = newValue;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _tenantNameController.clear();
                    _tenantPhoneController.clear();
                    _tenantEmailController.clear();
                    _selectedPropertyId = null;
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addTenant(dialogContext);
                  },
                  child: const Text('Add Tenant'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}