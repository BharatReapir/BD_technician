import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../data/service_details_data.dart';
import 'book_slot_page.dart';

class ServiceDetailsPage extends StatefulWidget {
  final String serviceName;
  final String price;
  final double rating;
  final int reviews;
  final int basePrice;
  final String? priceType;
  final String? acType;

  const ServiceDetailsPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.basePrice,
    this.priceType,
    this.acType,
  }) : super(key: key);

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  @override
  Widget build(BuildContext context) {
    // Get detailed service information
    final serviceDetails = widget.acType != null 
        ? ServiceDetailsData.getServiceDetail(widget.acType!, widget.serviceName)
        : null;
    
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
                  // Service Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Name and Rating
                        Text(
                          serviceDetails?['title'] ?? widget.serviceName,
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
                              widget.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '• ${widget.reviews} reviews',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 16, color: AppColors.textGray),
                            const SizedBox(width: 4),
                            Text(
                              serviceDetails?['duration'] ?? '30-45 mins',
                              style: const TextStyle(
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
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
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
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    widget.price,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.priceType != 'inspection') ...[
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
                                        'Final amount will be calculated at checkout including visiting charge and GST',
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
                      ],
                    ),
                  ),
                  
                  // Service Details Content
                  if (serviceDetails != null) ...[
                    _buildServiceSection('What\'s Included', serviceDetails['included']),
                    _buildServiceSection('What\'s Not Included', serviceDetails['notIncluded']),
                    _buildServiceSection('Service Process', serviceDetails['process']),
                    if (serviceDetails['bestFor'] != null)
                      _buildBestForSection('Best For', serviceDetails['bestFor']),
                    if (serviceDetails['additionalCharges'] != null)
                      _buildServiceSection('Additional Charges (If Applicable)', serviceDetails['additionalCharges']),
                    if (serviceDetails['importantNotes'] != null)
                      _buildImportantNotesSection('Important Notes', serviceDetails['importantNotes']),
                  ] else ...[
                    // Default content when no specific details available
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Professional ${widget.serviceName} service with experienced technicians. Quality service guaranteed.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textDark,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Book Now Button
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
                        serviceName: widget.serviceName,
                        price: widget.price,
                        basePrice: widget.basePrice.toDouble(),
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
                  'Book Now',
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

  Widget _buildServiceSection(String title, List<String>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: items.map((item) => _buildServiceItem(item, title.contains('Not Included'))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestForSection(String title, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
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

  Widget _buildImportantNotesSection(String title, List<String>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: items.map((item) => _buildImportantNoteItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String text, [bool isNotIncluded = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNotIncluded ? Icons.cancel : Icons.check_circle, 
            color: isNotIncluded ? Colors.red : AppColors.primary, 
            size: 20
          ),
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

  Widget _buildImportantNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
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

  Widget _buildPriceInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textGray,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}