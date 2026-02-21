import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'service_type_page.dart';

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
          // Common AC Service Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgMedium,
            ),
            child: Image.network(
              'https://images.unsplash.com/photo-1631545806609-4b0e36e4c824?w=800',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.bgMedium,
                child: Center(
                  child: Icon(icon, size: 80, color: AppColors.primary),
                ),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select AC Type',
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
              children: _getACTypes(context),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  List<Widget> _getACTypes(BuildContext context) {
    // Only for AC Repair - show AC types
    if (serviceType != 'AC Repair') {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'Services coming soon',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGray,
              ),
            ),
          ),
        ),
      ];
    }

    final List<Map<String, dynamic>> acTypes = [
      {
        'name': 'Split AC',
        'icon': Icons.ac_unit,
        'description': '4 services available',
      },
      {
        'name': 'Window AC',
        'icon': Icons.window,
        'description': '4 services available',
      },
      {
        'name': 'Cassette AC',
        'icon': Icons.square,
        'description': '4 services available',
      },
      {
        'name': 'Central AC',
        'icon': Icons.business,
        'description': '4 services available',
      },
    ];

    return acTypes.map((acType) {
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
            child: Icon(acType['icon'], color: AppColors.primary),
          ),
          title: Text(
            acType['name'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            acType['description'],
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
                builder: (context) => ServiceTypePage(
                  acType: acType['name'],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}