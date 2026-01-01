import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'booking_success_page.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final double totalAmount;
  final String date;
  final String timeSlot;

  const PaymentPage({
    Key? key,
    required this.serviceName,
    required this.totalAmount,
    required this.date,
    required this.timeSlot,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int selectedPaymentMethod = 0;
  final TextEditingController upiController = TextEditingController();

  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'UPI', 'icon': Icons.smartphone},
    {'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'name': 'Net Banking', 'icon': Icons.account_balance},
    {'name': 'Wallet', 'icon': Icons.account_balance_wallet},
    {'name': 'Pay After Service', 'icon': Icons.payments},
  ];

  void processPayment() {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading dialog
      
      // Navigate to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessPage(
            serviceName: widget.serviceName,
            amount: widget.totalAmount,
            date: widget.date,
            timeSlot: widget.timeSlot,
          ),
        ),
      );
    });
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
          'Payment',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Amount to Pay
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppColors.bgLight,
            child: Column(
              children: [
                const Text(
                  'Amount to Pay',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  
                  // Payment Methods
                  ...paymentMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedPaymentMethod == index
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedPaymentMethod == index
                                ? AppColors.primary
                                : AppColors.bgMedium,
                            width: selectedPaymentMethod == index ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selectedPaymentMethod == index
                                    ? AppColors.primary
                                    : AppColors.bgLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                method['icon'],
                                color: selectedPaymentMethod == index
                                    ? Colors.white
                                    : AppColors.textGray,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                method['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selectedPaymentMethod == index
                                      ? AppColors.primary
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                            if (selectedPaymentMethod == index)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // UPI ID Input (shown when UPI is selected)
                  if (selectedPaymentMethod == 0)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enter UPI ID',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: upiController,
                            decoration: InputDecoration(
                              hintText: 'example@upi',
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
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 100),
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
                  if (selectedPaymentMethod == 0 && upiController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter UPI ID'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  processPayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay Now',
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

  @override
  void dispose() {
    upiController.dispose();
    super.dispose();
  }
}