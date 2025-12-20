import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AdminPricingPage extends StatefulWidget {
  const AdminPricingPage({Key? key}) : super(key: key);

  @override
  State<AdminPricingPage> createState() => _AdminPricingPageState();
}

class _AdminPricingPageState extends State<AdminPricingPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pricing',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage service pricing and commission rates',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddServiceDialog(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Commission Settings Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.percent, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Commission Rate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '20%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Services Pricing Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 3;
                if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                }
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                }
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildServiceCard('AC Repair', '₹399', '₹499', Icons.ac_unit, const Color(0xFFE8F5E9)),
                    _buildServiceCard('TV Repair', '₹299', '₹399', Icons.tv, const Color(0xFFE3F2FD)),
                    _buildServiceCard('Refrigerator', '₹499', '₹699', Icons.kitchen, const Color(0xFFFFF3E0)),
                    _buildServiceCard('Washing Machine', '₹399', '₹549', Icons.local_laundry_service, const Color(0xFFF3E5F5)),
                    _buildServiceCard('Electrical', '₹199', '₹299', Icons.electrical_services, const Color(0xFFE8F5E9)),
                    _buildServiceCard('Plumbing', '₹249', '₹349', Icons.plumbing, const Color(0xFFE3F2FD)),
                    _buildServiceCard('Painting', '₹999', '₹1499', Icons.format_paint, const Color(0xFFFFF3E0)),
                    _buildServiceCard('Carpentry', '₹599', '₹899', Icons.handyman, const Color(0xFFF3E5F5)),
                    _buildServiceCard('Furniture Assembly', '₹499', '₹699', Icons.weekend, const Color(0xFFE8F5E9)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String service, String minPrice, String maxPrice, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Pricing')),
                  const PopupMenuItem(value: 'disable', child: Text('Disable Service')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            service,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Price: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              Expanded(
                child: Text(
                  '$minPrice - $maxPrice',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text(
                'Commission: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '20%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final minPriceController = TextEditingController();
    final maxPriceController = TextEditingController();
    final commissionController = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Min Price',
                          prefixText: '₹',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Price',
                          prefixText: '₹',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commissionController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Commission Rate',
                    suffixText: '%',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle add service
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Service added successfully'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add Service'),
            ),
          ],
        );
      },
    );
  }
}