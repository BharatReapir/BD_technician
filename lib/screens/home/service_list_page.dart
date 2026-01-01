import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'service_details_page.dart';

class ServiceListPage extends StatelessWidget {
  final String serviceType;
  final String subCategory;

  const ServiceListPage({
    Key? key,
    required this.serviceType,
    required this.subCategory,
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
          subCategory,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Popular Services',
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
              children: [
                _buildServiceCard(
                  context,
                  'General Service & Repair',
                  4.8,
                  2341,
                  '₹499',
                ),
                _buildServiceCard(
                  context,
                  'Gas Refilling',
                  4.7,
                  1842,
                  '₹1,299',
                ),
                _buildServiceCard(
                  context,
                  'Deep Cleaning',
                  4.9,
                  3156,
                  '₹799',
                ),
                _buildServiceCard(
                  context,
                  'Installation & Uninstallation',
                  4.6,
                  1234,
                  '₹599',
                ),
                _buildServiceCard(
                  context,
                  'Complete Overhaul',
                  4.8,
                  987,
                  '₹1,999',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    double rating,
    int reviews,
    String price,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$rating',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• $reviews reviews',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time, size: 14, color: AppColors.textGray),
                          const SizedBox(width: 4),
                          const Text(
                            '45 mins',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsPage(
                        serviceName: title,
                        price: price,
                        rating: rating,
                        reviews: reviews,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}