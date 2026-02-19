import 'package:bharatapp/screens/chimney_page.dart';
import 'package:bharatapp/screens/microwave_page.dart';
import 'package:bharatapp/screens/water_purifier_page.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/firebase_service.dart';
import '../../services/address_service.dart';
import '../bookings_page.dart';
import '../wallet_page.dart';
import '../support_page.dart';
import '../profile_page.dart';
import '../saved_addresses_page.dart';
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
                  : const ProfilePage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
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
  List<Map<String, dynamic>> _allServices = [];
  bool _isLoading = true;
  String _userAddress = 'Loading...';
  bool _isLoadingAddress = true;

  final List<Map<String, dynamic>> _fallbackServices = [
    {'name': 'AC Repair', 'icon': Icons.ac_unit, 'bgColor': const Color(0xFF4A90E2), 'type': 'ac'},
    {'name': 'Refrigerator', 'icon': Icons.kitchen, 'bgColor': const Color(0xFF50C878), 'type': 'refrigerator'},
    {'name': 'Washing Machine', 'icon': Icons.local_laundry_service, 'bgColor': const Color(0xFFFF6B6B), 'type': 'washing_machine'},
    {'name': 'Water Purifier', 'icon': Icons.water_drop, 'bgColor': const Color(0xFF1E88E5), 'type': 'water_purifier'},
    {'name': 'Microwave', 'icon': Icons.microwave, 'bgColor': const Color(0xFF9B59B6), 'type': 'microwave'},
    {'name': 'Chimney', 'icon': Icons.kitchen_outlined, 'bgColor': const Color(0xFFE74C3C), 'type': 'chimney'},
    {'name': 'TV Repair', 'icon': Icons.tv, 'bgColor': const Color(0xFFFFA500), 'type': 'coming_soon'},
    {'name': 'Electrician', 'icon': Icons.electrical_services, 'bgColor': const Color(0xFF8B4513), 'type': 'coming_soon'},
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    try {
      setState(() => _isLoadingAddress = true);
      
      // Try to get user's saved address
      final addresses = await AddressService.getSavedAddresses();
      
      if (addresses.isNotEmpty) {
        // Use the first saved address
        final address = addresses.first;
        setState(() {
          _userAddress = '${address['area'] ?? ''}, ${address['city'] ?? ''}, ${address['state'] ?? ''}'.trim();
          if (_userAddress.isEmpty || _userAddress == ', , ') {
            _userAddress = address['fullAddress'] ?? 'Mumbai, Maharashtra';
          }
          // Remove extra commas and spaces
          _userAddress = _userAddress.replaceAll(RegExp(r',\s*,'), ',').replaceAll(RegExp(r'^,\s*|,\s*$'), '');
          _isLoadingAddress = false;
        });
        return;
      }
      
      // Fallback to default location
      setState(() {
        _userAddress = 'Mumbai, Maharashtra';
        _isLoadingAddress = false;
      });
    } catch (e) {
      debugPrint('Error loading address: $e');
      setState(() {
        _userAddress = 'Mumbai, Maharashtra';
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      setState(() => _isLoading = true);
      List<Map<String, dynamic>> allServices = List.from(_fallbackServices);
      final hardcodedNames = _fallbackServices.map((s) => s['name'].toString().toLowerCase()).toSet();
      final firebaseServices = await FirebaseService.getActiveServices();
      
      if (firebaseServices.isNotEmpty) {
        for (var fbService in firebaseServices) {
          final serviceName = fbService['name'] ?? '';
          if (!hardcodedNames.contains(serviceName.toLowerCase())) {
            allServices.add({
              'name': serviceName,
              'icon': _getIconFromString(fbService['icon'] ?? 'build'),
              'bgColor': _getColorFromHex(fbService['bgColor'] ?? '#4A90E2'),
              'type': fbService['type'] ?? 'coming_soon',
            });
          }
        }
      }
      
      setState(() {
        _allServices = allServices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allServices = _fallbackServices;
        _isLoading = false;
      });
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'ac_unit': return Icons.ac_unit;
      case 'kitchen': return Icons.kitchen;
      case 'local_laundry_service': return Icons.local_laundry_service;
      case 'water_drop': return Icons.water_drop;
      case 'microwave': return Icons.microwave;
      case 'kitchen_outlined': return Icons.kitchen_outlined;
      case 'tv': return Icons.tv;
      case 'bolt': return Icons.bolt;
      case 'build': return Icons.build;
      case 'videocam': case 'cctv': return Icons.videocam;
      case 'plumbing': return Icons.plumbing;
      case 'electrical_services': return Icons.electrical_services;
      case 'carpenter': return Icons.carpenter;
      case 'format_paint': case 'painting': return Icons.format_paint;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'home_repair_service': return Icons.home_repair_service;
      default: return Icons.build;
    }
  }

  Color _getColorFromHex(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) return _allServices;
    return _allServices.where((service) => service['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _navigateToService(String serviceType, String type, IconData icon) {
    switch (type) {
      case 'ac':
        Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceCategoryPage(serviceType: serviceType, icon: icon)));
        break;
      case 'refrigerator':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const RefrigeratorTypePage()));
        break;
      case 'washing_machine':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WashingMachineTypePage()));
        break;
      case 'water_purifier':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WaterPurifierPage()));
        break;
      case 'microwave':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MicrowavePage()));
        break;
      case 'chimney':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ChimneyPage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service coming soon!'), duration: Duration(seconds: 2)));
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
      child: CustomScrollView(
        slivers: [
          // Header with location and notification
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to address selection page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SavedAddressesPage(),
                          ),
                        ).then((_) {
                          // Reload address after returning
                          _loadUserAddress();
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'DELIVERING TO',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _isLoadingAddress
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : Text(
                                  _userAddress,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_outlined, size: 24, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search for AC repair, plumbing...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // Seasonal Offer Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SEASONAL OFFER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Beat the Heat!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'AC Servicing at ₹499',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // What are you looking for? Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: const Text(
                'What are you looking for?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Services Grid (2x4)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: _isLoading
                ? SliverToBoxAdapter(
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _filteredServices[index];
                        return _buildServiceItem(
                          icon: service['icon'],
                          label: service['name'],
                          color: service['bgColor'],
                          onTap: () => _navigateToService(service['name'], service['type'], service['icon']),
                        );
                      },
                      childCount: _filteredServices.length > 8 ? 8 : _filteredServices.length,
                    ),
                  ),
          ),

          // 100% Verified Professionals Badge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_user, color: Color(0xFF1E88E5), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Verified Professionals',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Background checked and safety-trained experts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trending Services Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trending Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trending Services Horizontal List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTrendingCard(
                    'Deep Home Cleaning',
                    'Starting at ₹1,299',
                    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
                  ),
                  const SizedBox(width: 16),
                  _buildTrendingCard(
                    'Switchboard Repair',
                    'Starting at ₹149',
                    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400',
                  ),
                  const SizedBox(width: 16),
                  _buildTrendingCard(
                    'Plumbing Services',
                    'Starting at ₹199',
                    'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400',
                  ),
                ],
              ),
            ),
          ),

          // New at BharatDoorstep Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: const Text(
                'New at BharatDoorstep',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // New Service Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Home Painting',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Transform your home with\nexpert finishing',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(String title, String price, String imageUrl) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming Soon!')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E88E5),
                      side: const BorderSide(color: Color(0xFF1E88E5)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
