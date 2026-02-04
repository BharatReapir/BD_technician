
import 'package:bharatapp/constants/colors.dart';
import 'package:bharatapp/screens/home/home_page.dart';
import 'package:bharatapp/widgets/service_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final String icon;
  final String bgColor;
  final String type;
  final String category;
  final String basePrice;
  final String? description;
  final bool comingSoon;
  final int order;

  ServiceModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.type,
    required this.category,
    required this.basePrice,
    this.description,
    required this.comingSoon,
    required this.order,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'build',
      bgColor: data['bgColor'] ?? '#E0F7F4',
      type: data['type'] ?? 'coming_soon',
      category: data['category'] ?? '',
      basePrice: data['basePrice'] ?? '₹0',
      description: data['description'],
      comingSoon: data['comingSoon'] ?? false,
      order: data['order'] ?? 0,
    );
  }

  // Convert to the format your existing UI expects
  Map<String, dynamic> toServiceMap() {
    return {
      'name': name,
      'icon': _getIconData(icon),
      'bgColor': _getColorFromHex(bgColor),
      'type': comingSoon ? 'coming_soon' : type,
    };
  }

  // Helper method to convert icon string to IconData
  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'water_drop':
        return Icons.water_drop;
      case 'microwave':
        return Icons.microwave;
      case 'tv':
        return Icons.tv;
      case 'bolt':
        return Icons.bolt;
      case 'build':
        return Icons.build;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'home_repair_service':
        return Icons.home_repair_service;
      default:
        return Icons.build;
    }
  }

  // Helper method to convert hex color to Color
  static Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class ServicesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'services';

  // Get all active services for mobile app
  static Future<List<ServiceModel>> getActiveServices() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .orderBy('order')
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Get services in the format your existing UI expects
  static Future<List<Map<String, dynamic>>> getServicesForUI() async {
    try {
      List<ServiceModel> services = await getActiveServices();
      return services.map((service) => service.toServiceMap()).toList();
    } catch (e) {
      print('Error converting services for UI: $e');
      return [];
    }
  }

  // Listen to real-time updates
  static Stream<List<ServiceModel>> getActiveServicesStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'active')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList());
  }
}

// Updated HomePage widget - replace your existing _HomeContentState class with this:
class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch services from Firebase
      List<Map<String, dynamic>> services = await ServicesService.getServicesForUI();
      
      setState(() {
        _allServices = services;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading services: $e');
      setState(() => _isLoading = false);
      
      // Fallback to hardcoded services if Firebase fails
      _allServices = [
        {'name': 'AC Repair', 'icon': Icons.ac_unit, 'bgColor': const Color(0xFFE0F7F4), 'type': 'ac'},
        {'name': 'Refrigerator', 'icon': Icons.kitchen, 'bgColor': const Color(0xFFD4F1F4), 'type': 'refrigerator'},
        // ... add other fallback services
      ];
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    if (_searchQuery.isEmpty) {
      return _allServices;
    }
    return _allServices.where((service) =>
        service['name'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  // ... rest of your existing methods remain the same

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... your existing header code

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9596)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ... your existing banner and search code

                        // Services Grid
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
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.85,
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
  
  void _navigateToService(service, service2, service3) {}
}