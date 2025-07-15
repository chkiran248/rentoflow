// lib/screens/super_admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rentoflow/common/widgets.dart'; // For common widgets
import 'package:rentoflow/providers/firebase_provider.dart'; // For FirebaseProvider
import 'package:rentoflow/screens/persona_selection_screen.dart'; // For navigation
import 'package:rentoflow/screens/auth_screen.dart';
import 'package:rentoflow/common/app_navigation_bar.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final List<Map<String, dynamic>> _mockOwnerUsers = [];

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userId = firebaseProvider.userId;

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Super Admin Portal',
        userId: userId ?? 'Loading...',
        userName: firebaseProvider.currentUser?.displayName ?? 'Super Admin',
        userEmail: firebaseProvider.currentUser?.email ?? 'N/A',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Super Admin Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildSystemMetrics(context),
            const SizedBox(height: 24),
            _buildUserManagement(context),
            const SizedBox(height: 24),
            _buildPropertyValidation(context),
            const SizedBox(height: 24),
            _buildPlatformNotification(context),
          ],
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          // TODO: Implement navigation logic for super admin dashboard
        },
      ),
    );
  }

  Widget _buildSystemMetrics(BuildContext context) {
    final totalProperties = 0;
    final totalTenants = 0;
    final activeUsers = 0;
    final flaggedIssues = 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildMetricCard(context, 'Total Properties', '$totalProperties', Icons.apartment, Colors.blue[600]!),
        _buildMetricCard(context, 'Total Tenants', '$totalTenants', Icons.group, Colors.purple[600]!),
        _buildMetricCard(context, 'Active Users', '$activeUsers', Icons.person_outline, Colors.orange[600]!),
        _buildMetricCard(context, 'Flagged Issues', '$flaggedIssues', Icons.flag_outlined, Colors.red[600]!),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return CustomCard(
      color: color,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagement(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management (Property Owners)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Owner Name')),
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _mockOwnerUsers.map((owner) {
                return DataRow(cells: [
                  DataCell(Text(owner['name'])),
                  DataCell(Text('${owner['id'].toString().substring(0, 10)}...')),
                  DataCell(
                    Chip(
                      label: Text(owner['type']),
                      backgroundColor: owner['type'] == 'Pro' ? Colors.green[100] : Colors.grey[200],
                      labelStyle: TextStyle(color: owner['type'] == 'Pro' ? Colors.green[800] : Colors.grey[800]),
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(owner['status']),
                      backgroundColor: owner['status'] == 'Active' ? Colors.green[100] : Colors.red[100],
                      labelStyle: TextStyle(color: owner['status'] == 'Active' ? Colors.green[800] : Colors.red[800]),
                    ),
                  ),
                  DataCell(Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showSnackBar(context, "Toggling status for ${owner['name']}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[800],
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(owner['status'] == 'Active' ? 'Deactivate' : 'Activate'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          showSnackBar(context, "Toggling type for ${owner['name']}");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[100],
                          foregroundColor: Colors.orange[800],
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text('Toggle to ${owner['type'] == 'Pro' ? 'Basic' : 'Pro'}'),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyValidation(BuildContext context) {
    final pendingProperties = <Map<String, String>>[];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Validation Queue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (pendingProperties.isEmpty)
            const Text('No properties currently pending validation.', style: TextStyle(color: Colors.grey))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingProperties.length,
              itemBuilder: (context, index) {
                final prop = pendingProperties[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prop['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(prop['address']!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showSnackBar(context, "Validating property ${prop['name']}");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Validate'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformNotification(BuildContext context) {
    final TextEditingController notificationController = TextEditingController();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Platform-wide Notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notificationController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter message for all users (e.g., "System maintenance on Sunday...")',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (notificationController.text.isNotEmpty) {
                  showSnackBar(context, "Notification sent: ${notificationController.text}");
                  notificationController.clear();
                } else {
                  showSnackBar(context, "Notification message cannot be empty.", isError: true);
                }
              },
              icon: const Icon(Icons.send, size: 20),
              label: const Text('Send Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ca24a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
