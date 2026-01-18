import 'package:bharatapp/screens/home/book_slot_page.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class WashingMachineServiceOptions extends StatelessWidget {
  final String machineType;

  const WashingMachineServiceOptions({
    Key? key,
    required this.machineType,
  }) : super(key: key);

  List<Map<String, dynamic>> _getServiceOptions() {
    if (machineType == 'Semi Washing Machine') {
      return [
        {
          'name': 'Standard Service',
          'price': 399,
          'description': '• Ploster Cleaning\n• Filter Cleaning\n• Basic Maintenance',
        },
      ];
    } else {
      // Top Load / Front Load
      return [
        {
          'name': 'Normal Service',
          'price': 499,
          'description': '• Ploster Cleaning\n• Filter Cleaning\n• Basic Testing',
        },
        {
          'name': 'Deep Cleaning',
          'price': 1200,
          'priceMax': 1500,
          'description': '• Drum Deep Clean\n• Pipe & Filter Wash\n• Bad Smell Removal',
          'note': 'Final amount depends on condition & dirt level',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _getServiceOptions();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Service',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final hasPriceRange = service['priceMax'] != null;
          
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          service['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFE53935).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasPriceRange
                              ? '₹${service['price']} - ₹${service['priceMax']}'
                              : '₹${service['price']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray,
                      height: 1.6,
                    ),
                  ),
                  if (service['note'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              service['note'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookSlotPage(
                              serviceName: '${machineType} - ${service['name']}',
                              price: hasPriceRange 
                                ? '₹${service['price']} - ₹${service['priceMax']}'
                                : '₹${service['price']}',
                              basePrice: service['price'].toDouble(),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}