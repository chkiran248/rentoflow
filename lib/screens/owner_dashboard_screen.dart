// lib/screens/owner_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math'; // For pow function

import 'package:rentoflow/common/widgets.dart'; // For common widgets
import 'package:rentoflow/common/extensions.dart'; // For NumExtension
import 'package:rentoflow/providers/firebase_provider.dart'; // For FirebaseProvider
import 'package:rentoflow/screens/persona_selection_screen.dart'; // For navigation

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

  Future<void> _deleteProperty(BuildContext context, String propertyDocId, FirebaseFirestore db, String userId, String appId) async {
    try {
      await db.collection('artifacts/$appId/users/$userId/properties').doc(propertyDocId).delete();
      showSnackBar(context, "Property deleted successfully!");
    } catch (e) {
      debugPrint("Error deleting property: $e");
      showSnackBar(context, "Failed to delete property: $e", isError: true);
    }
  }

  Future<void> _addTenant(BuildContext context, String tenantName, String phoneNumber, String? selectedPropertyId) async {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    final db = firebaseProvider.db;
    final userId = firebaseProvider.userId;
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    if (db == null || userId == null) {
      showSnackBar(context, "Firebase not initialized or user not logged in.", isError: true);
      return;
    }

    if (tenantName.isEmpty || phoneNumber.isEmpty || selectedPropertyId == null) {
      showSnackBar(context, "Please fill all fields and select a property.", isError: true);
      return;
    }

    final newTenant = {
      'id': _uuid.v4(),
      'name': tenantName,
      'phone': phoneNumber,
      'propertyId': selectedPropertyId,
      'status': 'Active',
      'checkInDate': DateTime.now().toIso8601String(),
      'kycStatus': 'Pending',
      'rentalHistory': [],
    };

    try {
      await db.collection('artifacts/$appId/users/$userId/tenants').add(newTenant);
      showSnackBar(context, "Tenant added successfully!");
      Navigator.of(context).pop(); // Close the modal
    } catch (e) {
      debugPrint("Error adding tenant: $e");
      showSnackBar(context, "Failed to add tenant: $e", isError: true);
    }
  }

  Future<void> _deleteTenant(BuildContext context, String tenantDocId, FirebaseFirestore db, String userId, String appId) async {
    try {
      await db.collection('artifacts/$appId/users/$userId/tenants').doc(tenantDocId).delete();
      showSnackBar(context, "Tenant deleted successfully!");
    } catch (e) {
      debugPrint("Error deleting tenant: $e");
      showSnackBar(context, "Failed to delete tenant: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final db = firebaseProvider.db;
    final userId = firebaseProvider.userId;
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    // Mock complaint data
    final List<Map<String, String>> mockComplaints = [
      {'id': 'c1', 'description': 'Leaking tap in bathroom', 'status': 'Open', 'assignedTo': 'Plumber'},
      {'id': 'c2', 'description': 'AC not working', 'status': 'Pending', 'assignedTo': 'Electrician'},
      {'id': 'c3', 'description': 'Wall paint chipping', 'status': 'Resolved', 'assignedTo': 'Painter'},
    ];

    // Example financial instrument images/links
    final List<Map<String, String>> financialInstrumentImages = [
      {'src': 'https://placehold.co/400x160/227d49/ffffff?text=Invest+in+Mutual+Funds', 'link': '#mutualfunds'},
      {'src': 'https://placehold.co/400x160/c79e1c/ffffff?text=Explore+Fixed+Deposits', 'link': '#fixeddeposits'},
      {'src': 'https://placehold.co/400x160/8cc045/ffffff?text=Grow+Your+Wealth', 'link': '#wealthmanagement'},
    ];

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Property Owner Portal',
        userId: userId ?? 'Loading...',
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
                  MaterialPageRoute(builder: (context) => const PersonaSelectionScreen()),
                );
              }
            : null,
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
                  _buildPropertiesAndTenantsOverview(context, db, userId, appId),
                  const SizedBox(height: 24),
                  _buildRentTrackingAndComplaints(context, mockComplaints),
                  const SizedBox(height: 24),
                  _buildMarketingAndFinancialCarousel(context, financialInstrumentImages),
                ],
              ),
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
        ElevatedButton.icon(
          onPressed: () {
            _showAddTenantModal(context);
          },
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Add New Tenant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.grey[800],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            showSnackBar(context, "Sending reminders (simulated)...");
          },
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Send Reminders'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.grey[800],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    // Mock data for financial overview
    final totalRentalIncome = 150000.0;
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
                  fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesAndTenantsOverview(BuildContext context, FirebaseFirestore? db, String? userId, String appId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomCard(
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
                  child: db == null || userId == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
                          stream: db.collection('artifacts/$appId/users/$userId/properties').snapshots(),
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
                                return _buildPropertyListItem(context, property, propertyId, db, userId, appId);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined, color: Theme.of(context).colorScheme.secondary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Your Tenants',
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
                  child: db == null || userId == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
                          stream: db.collection('artifacts/$appId/users/$userId/tenants').snapshots(),
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
                                  'No tenants added yet. Tap "Add New Tenant" to get started!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final tenant = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                                final tenantId = snapshot.data!.docs[index].id;
                                return _buildTenantListItem(context, tenant, tenantId, db, userId, appId);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyListItem(BuildContext context, Map<String, dynamic> property, String propertyDocId, FirebaseFirestore db, String userId, String appId) {
    Color statusColor;
    Color statusTextColor;
    switch (property['status']) {
      case 'Vacant':
        statusColor = Colors.blue[100]!;
        statusTextColor = Colors.blue[800]!;
        break;
      case 'Occupied':
        statusColor = Colors.green[100]!;
        statusTextColor = Colors.green[800]!;
        break;
      case 'Dues':
        statusColor = Colors.red[100]!;
        statusTextColor = Colors.red[800]!;
        break;
      case 'New Booking':
        statusColor = Colors.yellow[100]!;
        statusTextColor = Colors.yellow[800]!;
        break;
      default:
        statusColor = Colors.grey[100]!;
        statusTextColor = Colors.grey[800]!;
    }

    return CustomCard(
      padding: const EdgeInsets.all(12.0),
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property['name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  property['status'] ?? 'N/A',
                  style: TextStyle(fontSize: 10, color: statusTextColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(property['address'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                onPressed: () {
                  showSnackBar(context, "Edit property (not yet implemented)");
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () async {
                  await _deleteProperty(context, propertyDocId, db, userId, appId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenantListItem(BuildContext context, Map<String, dynamic> tenant, String tenantDocId, FirebaseFirestore db, String userId, String appId) {
    return CustomCard(
      padding: const EdgeInsets.all(12.0),
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tenant['name'] ?? 'N/A',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(tenant['phone'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                onPressed: () {
                  showSnackBar(context, "Edit tenant (not yet implemented)");
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () async {
                  await _deleteTenant(context, tenantDocId, db, userId, appId);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentTrackingAndComplaints(BuildContext context, List<Map<String, String>> mockComplaints) {
    final rentDues = 2;
    final vacantProperties = 1;
    final occupiedProperties = 5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Theme.of(context).primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Rent Tracking & Financials',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMetricRow('Properties with Dues:', '$rentDues', Colors.red[600]!),
                const SizedBox(height: 8),
                _buildMetricRow('Vacant Properties:', '$vacantProperties', Colors.orange[600]!),
                const SizedBox(height: 8),
                _buildMetricRow('Occupied Properties:', '$occupiedProperties', Colors.blue[600]!),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showSnackBar(context, "Viewing detailed reports (simulated)...");
                    },
                    icon: const Icon(Icons.bar_chart, size: 20),
                    label: const Text('View Detailed Reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ca24a),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: Theme.of(context).colorScheme.secondary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Complaint Handling',
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
                  height: 150,
                  child: ListView.builder(
                    itemCount: mockComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = mockComplaints[index];
                      Color statusColor;
                      Color textColor;
                      switch (complaint['status']) {
                        case 'Open':
                          statusColor = Colors.red[100]!;
                          textColor = Colors.red[800]!;
                          break;
                        case 'Pending':
                          statusColor = Colors.yellow[100]!;
                          textColor = Colors.yellow[800]!;
                          break;
                        case 'Resolved':
                          statusColor = Colors.green[100]!;
                          textColor = Colors.green[800]!;
                          break;
                        default:
                          statusColor = Colors.grey[100]!;
                          textColor = Colors.grey[800]!;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  complaint['description']!,
                                  style: TextStyle(color: textColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                complaint['status']!,
                                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showSnackBar(context, "Managing complaints (simulated)...");
                    },
                    icon: const Icon(Icons.list_alt, size: 20),
                    label: const Text('Manage Complaints'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ca24a),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingAndFinancialCarousel(BuildContext context, List<Map<String, String>> carouselImages) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomCard(
            color: Colors.blue[600],
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ready to expand your portfolio?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover new investment opportunities with RentOFlow!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    showSnackBar(context, "Learning more about investments (simulated)...");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Learn More', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomCard(
            padding: EdgeInsets.zero,
            child: Carousel(images: carouselImages),
          ),
        ),
      ],
    );
  }

  void _showAddPropertyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                      setState(() {
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
                    prefixText: '₹ ', // Indian Rupee symbol
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
  }

  void _showAddTenantModal(BuildContext context) {
    final TextEditingController tenantNameController = TextEditingController();
    final TextEditingController phoneNumberController = TextEditingController();
    String? selectedPropertyId;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final firebaseProvider = Provider.of<FirebaseProvider>(dialogContext);
        final db = firebaseProvider.db;
        final userId = firebaseProvider.userId;
        const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: const Text('Add New Tenant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tenantNameController,
                  decoration: const InputDecoration(labelText: 'Tenant Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., +919876543210', // Indian format hint
                    prefixText: '+91', // Pre-fill country code
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                FutureBuilder<QuerySnapshot>(
                  future: db?.collection('artifacts/$appId/users/$userId/properties').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error loading properties: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No properties available to assign.');
                    }

                    List<DropdownMenuItem<String>> propertyItems = [
                      const DropdownMenuItem(value: null, child: Text('Select Property'))
                    ];
                    for (var doc in snapshot.data!.docs) {
                      propertyItems.add(
                        DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name'] ?? 'Unknown Property'),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Assign to Property'),
                      value: selectedPropertyId,
                      items: propertyItems,
                      onChanged: (value) {
                        selectedPropertyId = value;
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
                tenantNameController.dispose();
                phoneNumberController.dispose();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _addTenant(dialogContext, tenantNameController.text, phoneNumberController.text, selectedPropertyId);
                tenantNameController.dispose();
                phoneNumberController.dispose();
              },
              child: const Text('Add Tenant'),
            ),
          ],
        );
      },
    );
  }
}
