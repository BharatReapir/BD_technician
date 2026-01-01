import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'service_list_page.dart';

class ServiceCategoryPage extends StatelessWidget {
  final String serviceType;
  final IconData icon;

  const ServiceCategoryPage({
    Key? key,
    required this.serviceType,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          serviceType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _getServiceTypes(context),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<Widget> _getServiceTypes(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> serviceCategories = {
      'AC Repair': [
        {'name': 'Split AC', 'icon': Icons.ac_unit, 'services': 8},
        {'name': 'Window AC', 'icon': Icons.window, 'services': 6},
        {'name': 'Cassette AC', 'icon': Icons.square, 'services': 5},
        {'name': 'Central AC', 'icon': Icons.business, 'services': 4},
      ],
      'TV Repair': [
        {'name': 'LED TV', 'icon': Icons.tv, 'services': 7},
        {'name': 'Smart TV', 'icon': Icons.smart_display, 'services': 6},
        {'name': 'LCD TV', 'icon': Icons.monitor, 'services': 5},
      ],
      'Refrigerator': [
        {'name': 'Single Door', 'icon': Icons.kitchen, 'services': 6},
        {'name': 'Double Door', 'icon': Icons.kitchen_outlined, 'services': 7},
        {'name': 'Side by Side', 'icon': Icons.countertops, 'services': 5},
      ],
      'Washing Machine': [
        {'name': 'Top Load', 'icon': Icons.local_laundry_service, 'services': 6},
        {'name': 'Front Load', 'icon': Icons.local_laundry_service_outlined, 'services': 7},
        {'name': 'Semi Automatic', 'icon': Icons.wash, 'services': 5},
      ],
    };

    final types = serviceCategories[serviceType] ?? [];
    
    return types.map((type) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bgMedium),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(type['icon'], color: AppColors.primary),
          ),
          title: Text(
            type['name'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            '${type['services']} services available',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textGray),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceListPage(
                  serviceType: serviceType,
                  subCategory: type['name'],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}