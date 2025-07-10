// lib/screens/tenant_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For DateFormat

import 'package:rentoflow/common/widgets.dart'; // For common widgets
import 'package:rentoflow/common/extensions.dart'; // For NumExtension
import 'package:rentoflow/providers/firebase_provider.dart'; // For FirebaseProvider
import 'package:rentoflow/screens/persona_selection_screen.dart'; // For navigation

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userId = firebaseProvider.userId;

    return Scaffold(
      appBar: DashboardAppBar(
        title: 'Tenant Portal',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tenant Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildTenantProfileSection(context),
            const SizedBox(height: 24),
            _buildRentManagementSection(context),
            const SizedBox(height: 24),
            _buildNotificationsAndSupportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantProfileSection(BuildContext context) {
    // Mock data for tenant profile
    final tenantProfile = {
      'name': 'Tenant User',
      'phone': '+91 98765 43210',
      'status': 'Active',
      'property': 'Apt 4B, Green Towers',
    };

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  showSnackBar(context, "Editing profile (not yet implemented)");
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileRow(Icons.person, 'Name:', tenantProfile['name']!),
          _buildProfileRow(Icons.phone, 'Phone:', tenantProfile['phone']!),
          _buildProfileRow(Icons.home, 'Property:', tenantProfile['property']!),
          _buildProfileRow(Icons.check_circle_outline, 'Status:', tenantProfile['status']!),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            '$label ',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildRentManagementSection(BuildContext context) {
    final upcomingDues = [
      {'date': DateTime.now().add(const Duration(days: 5)), 'amount': 12000.0, 'status': 'Due'}
    ];
    final advanceRent = 24000.0;
    final last20Payments = [
      {'date': DateTime.now().subtract(const Duration(days: 20)), 'amount': 12000.0, 'status': 'Paid'},
      {'date': DateTime.now().subtract(const Duration(days: 50)), 'amount': 12000.0, 'status': 'Paid'},
      {'date': DateTime.now().subtract(const Duration(days: 80)), 'amount': 11500.0, 'status': 'Paid'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.2,
      children: [
        _buildRentManagementCard(
          context,
          'Current Rent Due',
          upcomingDues.isNotEmpty ? (upcomingDues[0]['amount'] as num).toLocaleString() : 'No Dues',
          upcomingDues.isNotEmpty ? 'Due on ${DateFormat.yMMMd('en_IN').format(upcomingDues[0]['date'] as DateTime)}' : '', // Use en_IN locale
          Icons.payments,
          const Color(0xFF2ca24a),
          () {
            showSnackBar(context, "Simulating rent payment...");
          },
        ),
        _buildRentManagementCard(
          context,
          'Advance Rent Paid',
          advanceRent.toLocaleString(),
          'Balance available for future payments.',
          Icons.wallet,
          const Color(0xFFc79e1c),
          null,
        ),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 20 Payments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: last20Payments.length,
                  itemBuilder: (context, index) {
                    final payment = last20Payments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text((payment['amount'] as num).toLocaleString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat.yMMMd('en_IN').format(payment['date'] as DateTime)), // Use en_IN locale
                          Text(payment['status'].toString(), style: TextStyle(color: payment['status'] == 'Paid' ? Colors.green : Colors.red)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showSnackBar(context, "Viewing all payments (simulated)...");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View All Payments'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRentManagementCard(
      BuildContext context,
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback? onPressed,
      ) {
    return CustomCard(
      color: color,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.9)),
          ),
          if (onPressed != null) ...[
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Pay Rent Now'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsAndSupportSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView(
                    children: [
                      _buildNotificationItem(
                        'Rent for July is due on July 5, 2025.',
                        DateFormat.yMMMd('en_IN').add_jm().format(DateTime(2025, 7, 5, 10, 0)), // Use en_IN locale
                        Colors.blue[50]!,
                      ),
                      _buildNotificationItem(
                        'Your KYC documents are pending verification.',
                        DateFormat.yMMMd('en_IN').add_jm().format(DateTime(2025, 6, 28, 9, 0)), // Use en_IN locale
                        Colors.yellow[50]!,
                      ),
                      _buildNotificationItem(
                        'Payment of ₹12,000 received for June rent.',
                        DateFormat.yMMMd('en_IN').add_jm().format(DateTime(2025, 6, 5, 11, 30)), // Use en_IN locale
                        Colors.green[50]!,
                      ),
                    ],
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
                Text(
                  'Support & Assistance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Need help or have a question? Contact your property owner directly.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showSnackBar(context, "Contacting owner (simulated)...");
                    },
                    icon: const Icon(Icons.send, size: 20),
                    label: const Text('Contact Property Owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFc79e1c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'For rental disputes or payment issues, reach out to support.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String title, String subtitle, Color backgroundColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}