import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'washing_machine_service_options.dart';
import 'washing_machine_repair_page.dart';

class WashingMachineServicePage extends StatelessWidget {
  final String machineType;

  const WashingMachineServicePage({
    Key? key,
    required this.machineType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        'name': 'Repair',
        'icon': Icons.handyman,
        'color': Color(0xFFF44336),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          machineType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Select Service Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: serviceTypes.length,
              itemBuilder: (context, index) {
                final serviceType = serviceTypes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFF5F5F5), width: 2),
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
                        if (serviceType['name'] == 'Service') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WashingMachineServiceOptions(
                                machineType: machineType,
                              ),
                            ),
                          );
                        } else if (serviceType['name'] == 'Repair') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WashingMachineRepairPage(
                                machineType: machineType,
                              ),
                            ),
                          );
                        } else {
                          // Installation
                          // Navigate to installation booking
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
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
                            const SizedBox(width: 20),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}