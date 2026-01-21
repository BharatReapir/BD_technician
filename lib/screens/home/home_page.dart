import 'dart:ui';
import 'package:bharatapp/screens/chimney_page.dart';
import 'package:bharatapp/screens/microwave_page.dart';
import 'package:bharatapp/screens/water_purifier_page.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/service_card.dart';
import '../bookings_page.dart';
import '../wallet_page.dart';
import '../support_page.dart';
import '../profile_page.dart';
import 'service_category_page.dart';
import '../refrigerator/refrigerator_type_page.dart';
import '../washing_machine/washing_machine_type_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _selectedIndex == 0
          ? const HomeContent()
          : _selectedIndex == 1
              ? const BookingsPage()
              : _selectedIndex == 2
                  ? const WalletPage()
                  : _selectedIndex == 3
                      ? const SupportPage()
                      : const ProfilePage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2D9596),
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones_outlined),
              activeIcon: Icon(Icons.headphones),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allServices = [
    {
      'name': 'AC Repair',
      'icon': Icons.ac_unit,
      'bgColor': const Color(0xFFE0F7F4),
      'type': 'ac',
    },
    {
      'name': 'Refrigerator',
      'icon': Icons.kitchen,
      'bgColor': const Color(0xFFD4F1F4),
      'type': 'refrigerator',
    },
    {
      'name': 'Washing Machine',
      'icon': Icons.local_laundry_service,
      'bgColor': const Color(0xFFC8E9E5),
      'type': 'washing_machine',
    },
    {
      'name': 'Water Purifier',
      'icon': Icons.water_drop,
      'bgColor': const Color(0xFFE0F7F4),
      'type': 'water_purifier',
    },
    {
      'name': 'Microwave',
      'icon': Icons.microwave,
      'bgColor': const Color(0xFFD4F1F4),
      'type': 'microwave',
    },
    {
      'name': 'Chimney',
      'icon': Icons.kitchen_outlined,
      'bgColor': const Color(0xFFC8E9E5),
      'type': 'chimney',
    },
    {
      'name': 'TV Repair',
      'icon': Icons.tv,
      'bgColor': const Color(0xFFE0F7F4),
      'type': 'coming_soon',
    },
    {
      'name': 'Electrician',
      'icon': Icons.bolt,
      'bgColor': const Color(0xFFD4F1F4),
      'type': 'coming_soon',
    },
    {
      'name': 'Plumber',
      'icon': Icons.build,
      'bgColor': const Color(0xFFC8E9E5),
      'type': 'coming_soon',
    },
  ];

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) {
      return _allServices;
    }
    return _allServices
        .where((service) =>
            service['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _navigateToService(String serviceType, String type, IconData icon) {
    switch (type) {
      case 'ac':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceCategoryPage(
              serviceType: serviceType,
              icon: icon,
            ),
          ),
        );
        break;
      case 'refrigerator':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RefrigeratorTypePage(),
          ),
        );
        break;
      case 'washing_machine':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WashingMachineTypePage(),
          ),
        );
        break;
      case 'water_purifier':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WaterPurifierPage(),
          ),
        );
        break;
      case 'microwave':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MicrowavePage(),
          ),
        );
        break;
      case 'chimney':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChimneyPage(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✨ Header with logo.png
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D9596), Color(0xFF9AD0C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✨ Logo.png instead of text
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white.withOpacity(0.2),
                            child: Image.asset(
                              'assets/logo.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bharat Doorstep',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Your Trusted Service Partner',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 28),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Mumbai',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner with Glass Buttons (16:9 ratio)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          children: [
                            // Banner Image
                            Positioned.fill(
                              child: Image.asset(
                                'assets/banner.png',
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.45),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),

                            // Text Overlay
                            const Positioned(
                              left: 20,
                              bottom: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expert Home Repairs',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Professional services at your doorstep',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Glass Service Buttons
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 20,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildGlassButton(
                                    icon: Icons.ac_unit,
                                    title: 'AC Repair',
                                    onTap: () => _navigateToService(
                                      'AC Repair',
                                      'ac',
                                      Icons.ac_unit,
                                    ),
                                  ),
                                  _buildGlassButton(
                                    icon: Icons.plumbing,
                                    title: 'Plumbing',
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Coming Soon!')),
                                      );
                                    },
                                  ),
                                  _buildGlassButton(
                                    icon: Icons.electrical_services,
                                    title: 'Electrician',
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Coming Soon!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for services...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[400]),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✨ All Services Header (Glassy look)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2D9596).withOpacity(0.15),
                                const Color(0xFF9AD0C2).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2D9596).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D9596).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.grid_view_rounded,
                                  color: Color(0xFF2D9596),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'All Services',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D9596),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✨ Smaller Services Grid
                  _filteredServices.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'No services found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textGray,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // ✨ 3 columns instead of 2
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85, // ✨ Smaller cards
                            ),
                            itemCount: _filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = _filteredServices[index];
                              return GestureDetector(
                                onTap: () => _navigateToService(
                                  service['name'],
                                  service['type'],
                                  service['icon'],
                                ),
                                child: ServiceCard(
                                  icon: service['icon'],
                                  title: service['name'],
                                  bgColor: service['bgColor'],
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glass Button Widget
  Widget _buildGlassButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}