import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final String serviceName;
  final String price;
  final double basePrice;
  final String date;
  final String timeSlot;
  final Map<String, String> address;

  const CheckoutPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.basePrice,
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
    {'code': 'FIRST40', 'discount': 40, 'type': 'percentage', 'desc': '40% off on first booking'},
    {'code': 'SAVE100', 'discount': 100, 'type': 'flat', 'desc': 'Flat ₹100 off'},
    {'code': 'WEEKEND200', 'discount': 200, 'type': 'flat', 'desc': 'Weekend special ₹200 off'},
  ];

  void applyCoupon(String code) {
    final coupon = availableCoupons.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {},
    );

    if (coupon.isNotEmpty) {
      setState(() {
        appliedCoupon = code;
        if (coupon['type'] == 'percentage') {
          discount = widget.basePrice * coupon['discount'] / 100;
        } else {
          discount = coupon['discount'].toDouble();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon applied successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void removeCoupon() {
    setState(() {
      appliedCoupon = null;
      discount = 0;
      couponController.clear();
    });
  }

  double getDiscountedPrice() {
    return widget.basePrice - discount;
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
                        _buildDetailRow('Address', '${widget.address['type']} - ${widget.address['city']}'),
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
                        Row(
                          children: const [
                            Icon(Icons.local_offer, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Apply Coupon',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (appliedCoupon != null) ...[
                          // Applied Coupon Display
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appliedCoupon!,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'You saved ₹${discount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: removeCoupon,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.red, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Coupon Input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: couponController,
                                  textCapitalization: TextCapitalization.characters,
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
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.bgLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.bgMedium),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.local_offer, color: AppColors.primary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            coupon['code'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          Text(
                                            coupon['desc'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'APPLY',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
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
                        Row(
                          children: const [
                            Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Price Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildPriceRow('Service Charge', '₹${widget.basePrice.toStringAsFixed(0)}'),
                              if (discount > 0) ...[
                                const SizedBox(height: 8),
                                _buildPriceRow(
                                  'Discount Applied',
                                  '-₹${discount.toStringAsFixed(0)}',
                                  isDiscount: true,
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                'Subtotal',
                                '₹${getDiscountedPrice().toStringAsFixed(0)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Additional Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Visiting charge, GST & any additional costs will be added in next step',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDark,
                                  ),
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
                      builder: (context) => PaymentPage(
                        serviceName: widget.serviceName,
                        serviceCharge: getDiscountedPrice(),
                        date: widget.date,
                        timeSlot: widget.timeSlot,
                        address: widget.address,
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
                  'Proceed to Payment',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.green : AppColors.textDark,
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