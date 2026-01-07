import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final String serviceName;
  final String price;
  final String date;
  final String timeSlot;
  final Map<String, String> address;

  const CheckoutPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.date,
    required this.timeSlot,
    required this.address,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController couponController = TextEditingController();
  String? appliedCoupon;
  double discount = 0;

  final List<Map<String, dynamic>> availableCoupons = [
    {'code': 'FIRST40', 'discount': 40, 'type': 'percentage'},
    {'code': 'SAVE100', 'discount': 100, 'type': 'flat'},
    {'code': 'WEEKEND200', 'discount': 200, 'type': 'flat'},
  ];

  void applyCoupon(String code) {
    final coupon = availableCoupons.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {},
    );

    if (coupon.isNotEmpty) {
      setState(() {
        appliedCoupon = code;
        final basePrice = double.parse(widget.price.replaceAll('₹', '').replaceAll(',', ''));
        if (coupon['type'] == 'percentage') {
          discount = basePrice * coupon['discount'] / 100;
        } else {
          discount = coupon['discount'].toDouble();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double getBasePrice() {
    return double.parse(widget.price.replaceAll('₹', '').replaceAll(',', ''));
  }

  double getGST() {
    return (getBasePrice() - discount) * 0.18;
  }

  double getPlatformFee() {
    return 20;
  }

  double getTotalAmount() {
    return getBasePrice() - discount + getGST() + getPlatformFee();
  }

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
          'Checkout',
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
                  // Service Details Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Service', widget.serviceName),
                        _buildDetailRow('Date & Time', '${widget.date} • ${widget.timeSlot.split(' - ')[0]}'),
                        _buildDetailRow('Address', widget.address['type']!),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Apply Coupon Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Apply Coupon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: couponController,
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon code',
                                  prefixIcon: const Icon(Icons.local_offer, color: AppColors.textGray),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.bgMedium),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.bgMedium),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (couponController.text.isNotEmpty) {
                                  applyCoupon(couponController.text.toUpperCase());
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Available Coupons
                        if (appliedCoupon == null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Available Coupons:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...availableCoupons.map((coupon) {
                            return GestureDetector(
                              onTap: () {
                                couponController.text = coupon['code'];
                                applyCoupon(coupon['code']);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.bgMedium),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_offer, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${coupon['code']} - ${coupon['type'] == 'percentage' ? '${coupon['discount']}% Off' : '₹${coupon['discount']} Off'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Price Breakdown Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPriceRow('Base Price', '₹${getBasePrice().toStringAsFixed(0)}'),
                        if (discount > 0)
                          _buildPriceRow('Discount', '-₹${discount.toStringAsFixed(0)}', isDiscount: true),
                        _buildPriceRow('GST (18%)', '₹${getGST().toStringAsFixed(0)}'),
                        _buildPriceRow('Platform Fee', '₹${getPlatformFee().toStringAsFixed(0)}'),
                        const Divider(height: 32),
                        _buildPriceRow(
                          'Total Amount',
                          '₹${getTotalAmount().toStringAsFixed(0)}',
                          isTotal: true,
                          color: AppColors.primary,
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
                      builder: (context) => PaymentPage(
                        serviceName: widget.serviceName,
                        totalAmount: getTotalAmount(),
                        date: widget.date,
                        timeSlot: widget.timeSlot,
                        address: widget.address, // ADDED THIS LINE
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
                  'Proceed to Pay',
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isDiscount = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? AppColors.textDark : AppColors.textGray),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isDiscount ? Colors.green : (isTotal ? AppColors.primary : AppColors.textDark)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    couponController.dispose();
    super.dispose();
  }
}