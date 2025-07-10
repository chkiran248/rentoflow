// lib/common/widgets.dart
import 'package:flutter/material.dart';
// Removed unused imports:
// import 'package:provider/provider.dart';
// import 'package:rentoflow/providers/firebase_provider.dart';

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
  final VoidCallback onChangePersona;
  final VoidCallback? onSignOut;

  const DashboardAppBar({
    required this.title,
    required this.userId,
    required this.onChangePersona,
    this.onSignOut,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16.0); // Add extra padding for rounded bottom

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
        Tooltip(
          message: 'Your User ID: $userId',
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(
                'ID: ${userId.substring(0, 4)}...',
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: Colors.grey[200],
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'change_persona') {
              // This navigation needs to be handled by the calling screen
              // as PersonaSelectionScreen is not directly imported here.
              onChangePersona();
            } else if (value == 'sign_out' && onSignOut != null) {
              onSignOut!();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'change_persona',
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, size: 20),
                  SizedBox(width: 8),
                  Text('Change Persona'),
                ],
              ),
            ),
            if (onSignOut != null)
              PopupMenuItem<String>(
                value: 'sign_out',
                child: Row(
                  children: const [
                    Icon(Icons.lock_open, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
          ],
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
class Carousel extends StatefulWidget {
  final List<Map<String, String>> images;
  final Duration interval;

  const Carousel({
    required this.images,
    this.interval = const Duration(seconds: 3),
    super.key,
  });

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late PageController _pageController;
  int _currentPage = 0;
  // Removed: late final Future<void> _initFuture; // This field was unused

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(widget.interval, () {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      }
      _startAutoScroll(); // Loop back
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Center(child: Text("No images to display."));
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Handle link tap if needed
                if (widget.images[index]['link'] != null) {
                  showSnackBar(context, "Navigating to: ${widget.images[index]['link']}");
                  // You would typically use url_launcher package here
                  // Uri.parse(widget.images[index]['link']!).launchUrl();
                }
              },
              child: Image.network(
                widget.images[index]['src']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Text(
                      'Image ${index + 1}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.images.length > 1)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                },
              ),
            ),
          ),
        if (widget.images.length > 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                },
              ),
            ),
          ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
