import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'service_list_page.dart';

class ServiceTypePage extends StatelessWidget {
  final String acType;

  const ServiceTypePage({
    Key? key,
    required this.acType,
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
          acType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Service Type',
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
    final List<Map<String, dynamic>> serviceTypes = [
      {
        'name': 'Service',
        'icon': Icons.home_repair_service,
        'color': Color(0xFF4CAF50),
      },
      {
        'name': 'Installation',
        'icon': Icons.build_circle,
        'color': Color(0xFF2196F3),
      },
      {
        'name': 'Uninstall',
        'icon': Icons.remove_circle_outline,
        'color': Color(0xFFFF9800),
      },
      {
        'name': 'Repair',
        'icon': Icons.handyman,
        'color': Color(0xFFF44336),
      },
    ];

    return serviceTypes.map((serviceType) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bgMedium, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceListPage(
                    serviceType: 'AC Repair',
                    subCategory: acType,
                    serviceAction: serviceType['name'],
                    services: _getServicesForType(serviceType['name']),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: serviceType['color'].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      serviceType['icon'],
                      color: serviceType['color'],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      serviceType['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: AppColors.textGray,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _getServicesForType(String serviceTypeName) {
    // SPLIT AC
    if (acType == 'Split AC') {
      if (serviceTypeName == 'Service') {
        return [
          {'name': 'General Service', 'price': 499},
          {'name': 'Jet Machine Service', 'price': 550},
          {'name': 'Foam Service', 'price': 600},
          {'name': 'Spray Service', 'price': 750},
        ];
      } else if (serviceTypeName == 'Installation') {
        return [
          {'name': 'AC Installation', 'price': 1150, 'note': '⚠️ Copper pipe + Stand cost extra'},
        ];
      } else if (serviceTypeName == 'Uninstall') {
        return [
          {'name': 'AC Uninstallation', 'price': 550},
        ];
      } else if (serviceTypeName == 'Repair') {
        return [
          {'name': 'Gas Refilling', 'price': 0, 'priceType': 'inspection'},
          {'name': 'Noise Problem', 'price': 0, 'priceType': 'inspection'},
          {'name': 'Not Responding', 'price': 0, 'priceType': 'inspection'},
          {'name': 'Any Other Problem', 'price': 0, 'priceType': 'inspection'},
        ];
      }
    }

    // WINDOW AC
    if (acType == 'Window AC') {
      if (serviceTypeName == 'Service') {
        return [
          {'name': 'General Service', 'price': 449},
          {'name': 'Jet Machine Service', 'price': 499},
          {'name': 'Foam + Jet Service', 'price': 549},
          {'name': 'Spray + Jet Service', 'price': 649},
        ];
      } else if (serviceTypeName == 'Installation') {
        return [
          {'name': 'AC Installation', 'price': 649},
        ];
      } else if (serviceTypeName == 'Uninstall') {
        return [
          {'name': 'AC Uninstallation', 'price': 549},
        ];
      } else if (serviceTypeName == 'Repair') {
        return [
          {'name': 'Gas Refilling', 'price': 0, 'priceType': 'inspection'},
          {'name': 'Noise Problem', 'price': 0, 'priceType': 'inspection'},
          {'name': 'Not Responding', 'price': 0, 'priceType': 'inspection'},
          {'name': 'Any Other Problem', 'price': 0, 'priceType': 'inspection'},
        ];
      }
    }

    // CASSETTE & CENTRAL AC
    if (acType == 'Cassette AC' || acType == 'Central AC') {
      return [
        {
          'name': '${serviceTypeName} - Inspection Required',
          'price': 0,
          'priceType': 'inspection',
          'note': '💬 Final bill will be decided by Technician after visit'
        },
      ];
    }

    return [];
  }
}