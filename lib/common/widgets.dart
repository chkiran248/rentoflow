// lib/common/widgets.dart
import 'package:flutter/material.dart';

// --- Global Message Box (Snackbar equivalent) ---
void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

// --- Common AppBar for Dashboards ---
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userId;
  final String userName;
  final String userEmail;
  final VoidCallback onChangePersona;
  final VoidCallback? onSignOut;
  final VoidCallback? onProfile;

  const DashboardAppBar({
    required this.title,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.onChangePersona,
    this.onSignOut,
    this.onProfile,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Image.network(
            'https://placehold.co/80x30/227d49/ffffff?text=RentOFlow',
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Container(
                  width: 80,
                  height: 30,
                  color: const Color(0xFF227d49),
                  alignment: Alignment.center,
                  child: const Text('RentOFlow',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        // Marketing Banner (simplified for Flutter)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Invest Now!',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              icon: CircleAvatar(
                radius: 16,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      const Text('My Profile'),
                    ],
                  ),
                ),
                DropdownMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 8),
                      const Text('Logout'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == 'profile' && onProfile != null) {
                  onProfile!();
                } else if (value == 'logout' && onSignOut != null) {
                  onSignOut!();
                }
              },
              selectedItemBuilder: (context) {
                return [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontSize: 12)),
                          if (userEmail.isNotEmpty)
                            Text(userEmail, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ];
              },
            ),
          ),
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16.0),
        ),
      ),
    );
  }
}

// --- Common Card Widget ---
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double elevation;

  const CustomCard({
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.color,
    this.elevation = 4.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: color ?? Theme.of(context).cardColor,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

// --- Carousel Widget ---
class Carousel extends StatelessWidget {
  final List<Map<String, String>> images;
  const Carousel({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160, // Set a fixed height for the carousel
      child: PageView(
        children: images.map((img) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                // Handle link navigation if needed
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  img['src'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 160,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}