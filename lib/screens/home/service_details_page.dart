import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'book_slot_page.dart';

class ServiceDetailsPage extends StatelessWidget {
  final String serviceName;
  final String price;
  final double rating;
  final int reviews;
  final int basePrice;
  final String? priceType;

  const ServiceDetailsPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.basePrice,
    this.priceType,
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
        title: const Text(
          'Service Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Image Header
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.tertiary.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.build_circle_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Name and Rating
                        Text(
                          serviceName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '• $reviews reviews',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 16, color: AppColors.textGray),
                            const SizedBox(width: 4),
                            const Text(
                              '45-60 mins',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Price Breakdown
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Base Service Price',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (priceType != 'inspection') ...[
                                const Divider(height: 24),
                                _buildPriceInfoRow('Visiting Charge', 'Applicable'),
                                const SizedBox(height: 8),
                                _buildPriceInfoRow('GST @18%', 'On total amount'),
                                const Divider(height: 24),
                                const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Final bill may vary based on technician inspection',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // What's Included
                        const Text(
                          "What's Included",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildIncludedItem('Professional technician visit'),
                        _buildIncludedItem('General checkup and diagnostics'),
                        _buildIncludedItem('Performance inspection'),
                        _buildIncludedItem('Basic troubleshooting'),
                        _buildIncludedItem('Service completion report'),
                        const SizedBox(height: 24),
                        
                        // What's Not Included
                        const Text(
                          "What's Not Included",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNotIncludedItem('Spare parts replacement (charged separately)'),
                        _buildNotIncludedItem('Additional materials (copper pipe, stand, etc.)'),
                        _buildNotIncludedItem('Gas refilling (if applicable)'),
                        _buildNotIncludedItem('Deep cleaning or overhaul'),
                        const SizedBox(height: 24),
                        
                        // Additional Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '📋 Service Policy',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Visiting charge is mandatory and non-refundable\n• Final bill amount will be determined after technician inspection\n• Additional charges may apply for parts and materials\n• Payment to be made after service completion',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookSlotPage(
                        serviceName: serviceName,
                        price: price,
                        basePrice: basePrice.toDouble(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Book',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildPriceInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}