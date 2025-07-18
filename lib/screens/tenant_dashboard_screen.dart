// lib/screens/tenant_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For DateFormat

import 'package:rentoflow/common/widgets.dart'; // For common widgets
import 'package:rentoflow/common/extensions.dart'; // For NumExtension
import 'package:rentoflow/providers/firebase_provider.dart'; // For FirebaseProvider
import 'package:rentoflow/screens/persona_selection_screen.dart'; // For navigation
import 'package:rentoflow/screens/auth_screen.dart';
import 'package:rentoflow/screens/owner_dashboard_screen.dart';
import 'package:rentoflow/screens/profile_view.dart';
import 'package:rentoflow/common/app_navigation_bar.dart';
import 'package:rentoflow/services/data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        userName: 'Tenant User',
        userEmail: firebaseProvider.currentUser?.email ?? 'No Email',
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
      bottomNavigationBar: AppNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OwnerDashboardScreen()),
              );
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileView(
                    userName: firebaseProvider.currentUser?.displayName ?? firebaseProvider.currentUser?.email ?? 'Tenant',
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

  Widget _buildTenantProfileSection(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userName = firebaseProvider.currentUser?.displayName ?? firebaseProvider.currentUser?.email ?? 'Tenant User';
    const appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');
    
    return StreamBuilder<QuerySnapshot>(
      stream: firebaseProvider.db?.collectionGroup('tenants')
          .where('email', isEqualTo: firebaseProvider.currentUser?.email ?? '')
          .snapshots(),
      builder: (context, tenantSnapshot) {
        String propertyName = 'Not assigned';
        String ownerName = 'Not assigned';
        String propertyId = '';
        
        if (tenantSnapshot.hasData && tenantSnapshot.data!.docs.isNotEmpty) {
          final tenantData = tenantSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          propertyId = tenantData['propertyId'] ?? '';
        }
        
        return StreamBuilder<QuerySnapshot>(
          stream: propertyId.isNotEmpty 
              ? firebaseProvider.db?.collectionGroup('properties')
                  .where(FieldPath.documentId, isEqualTo: propertyId)
                  .snapshots()
              : null,
          builder: (context, propertySnapshot) {
            if (propertySnapshot?.hasData == true && propertySnapshot!.data!.docs.isNotEmpty) {
              final propertyData = propertySnapshot.data!.docs.first.data() as Map<String, dynamic>;
              propertyName = propertyData['name'] ?? 'Not assigned';
              
              // Get owner info from the document path
              final docPath = propertySnapshot.data!.docs.first.reference.path;
              final ownerUserId = docPath.split('/')[3]; // Extract userId from path
              
              return StreamBuilder<DocumentSnapshot>(
                stream: firebaseProvider.db?.collection('artifacts/$appId/users/$ownerUserId/profile').doc('info').snapshots(),
                builder: (context, ownerSnapshot) {
                  if (ownerSnapshot.hasData && ownerSnapshot.data!.exists) {
                    final ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>;
                    ownerName = ownerData['name'] ?? 'Owner';
                  }
                  
                  return _buildTenantProfileCard(context, userName, propertyName, ownerName);
                },
              );
            }
            
            return _buildTenantProfileCard(context, userName, propertyName, ownerName);
          },
        );
      },
    );
  }
  
  Widget _buildTenantProfileCard(BuildContext context, String userName, String propertyName, String ownerName) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

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
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final userId = firebaseProvider.userId;
    
    if (userId == null || firebaseProvider.db == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final dataService = DataService(firebaseProvider.db!, userId);
    
    // Get real data from Firebase instead of dummy data
    final upcomingDues = <Map<String, dynamic>>[];
    final advanceRent = 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 1.0,
      children: [
        _buildRentManagementCard(
          context,
          'Current Rent Due',
          upcomingDues.isNotEmpty ? (upcomingDues[0]['amount'] as num).toLocaleString() : 'No Dues',
          upcomingDues.isNotEmpty ? 'Due on ${DateFormat.yMMMd('en_IN').format(upcomingDues[0]['date'] as DateTime)}' : '',
          Icons.payments,
          const Color(0xFF81C784),
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
          const Color(0xFFFFD54F),
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: dataService.getPayments(limit: 20),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No payments found'));
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final payment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
                        final date = payment['date'] != null ? 
                          (payment['date'] as Timestamp).toDate() : DateTime.now();
                        final status = payment['status'] ?? 'Unknown';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(amount.toLocaleString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(DateFormat.yMMMd('en_IN').format(date)),
                              Text(status, style: TextStyle(color: status == 'Paid' ? Colors.green : Colors.red)),
                            ],
                          ),
                        );
                      },
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
                fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    if (isSmallScreen) {
      return Column(
        children: [
          _buildNotificationsCard(context),
          const SizedBox(height: 16),
          _buildSupportCard(context),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNotificationsCard(context),
        const SizedBox(width: 16),
        _buildSupportCard(context),
      ],
    );
  }

  Widget _buildNotificationsCard(BuildContext context) {
    return Expanded(
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
              child: const Center(
                child: Text(
                  'No notifications yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Expanded(
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
                  backgroundColor: const Color(0xFFFFD54F),
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
    );
  }

  Widget _buildOldNotificationsAndSupportSection(BuildContext context) {
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
                  child: const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(color: Colors.grey),
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
                      backgroundColor: const Color(0xFFFFD54F),
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