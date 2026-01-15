import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../constants/colors.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_service.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import 'booking_success_page.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final double totalAmount;
  final String date;
  final String timeSlot;
  final Map<String, String> address;

  const PaymentPage({
    Key? key,
    required this.serviceName,
    required this.totalAmount,
    required this.date,
    required this.timeSlot,
    required this.address,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int selectedPaymentMethod = 0;
  String? selectedBank;
  String? selectedWallet;
  final TextEditingController upiController = TextEditingController();

  // Card details controllers
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  // Razorpay instance
  late Razorpay _razorpay;
  String? _currentBookingId;

  final List<Map<String, dynamic>> paymentMethods = [
    {'name': 'UPI', 'icon': Icons.smartphone},
    {'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'name': 'Net Banking', 'icon': Icons.account_balance},
    {'name': 'Wallet', 'icon': Icons.account_balance_wallet},
    {'name': 'Pay After Service', 'icon': Icons.payments},
  ];

  final List<Map<String, String>> banks = [
    {'name': 'State Bank of India', 'code': 'SBI'},
    {'name': 'HDFC Bank', 'code': 'HDFC'},
    {'name': 'ICICI Bank', 'code': 'ICICI'},
    {'name': 'Axis Bank', 'code': 'AXIS'},
    {'name': 'Kotak Mahindra Bank', 'code': 'KOTAK'},
    {'name': 'Punjab National Bank', 'code': 'PNB'},
    {'name': 'Bank of Baroda', 'code': 'BOB'},
    {'name': 'Canara Bank', 'code': 'CANARA'},
  ];

  final List<Map<String, String>> wallets = [
    {'name': 'Paytm', 'logo': '💳'},
    {'name': 'PhonePe', 'logo': '📱'},
    {'name': 'Google Pay', 'logo': 'G'},
    {'name': 'Amazon Pay', 'logo': 'A'},
    {'name': 'Mobikwik', 'logo': '💰'},
    {'name': 'Freecharge', 'logo': '⚡'},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    upiController.dispose();
    cardNumberController.dispose();
    cardHolderController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Payment Success: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');

    // Update booking status to confirmed
    if (_currentBookingId != null) {
      _updateBookingAfterPayment(_currentBookingId!, 'confirmed', response.paymentId);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Successful! ID: ${response.paymentId}'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to success page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSuccessPage(
          serviceName: widget.serviceName,
          amount: widget.totalAmount,
          date: widget.date,
          timeSlot: widget.timeSlot,
          bookingId: _currentBookingId ?? '',
        ),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Error: ${response.code} - ${response.message}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );

    // Mark booking as payment failed
    if (_currentBookingId != null) {
      FirebaseService.updateBookingStatus(_currentBookingId!, 'payment_failed');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
      ),
    );
  }

  Future<void> _updateBookingAfterPayment(String bookingId, String status, String? paymentId) async {
    try {
      await FirebaseService.updateBookingStatus(bookingId, status);
      if (paymentId != null) {
        await FirebaseService.updateBookingPaymentId(bookingId, paymentId);
      }
    } catch (e) {
      debugPrint('Error updating booking: $e');
    }
  }

  Future<void> _openRazorpayCheckout() async {
    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Create booking first
      final bookingId = await _createBooking('pending');
      _currentBookingId = bookingId;

      var options = {
        'key': 'YOUR_RAZORPAY_KEY_ID', // Replace with your key
        'amount': (widget.totalAmount * 100).toInt(), // Amount in paise
        'name': 'Service Booking',
        'description': widget.serviceName,
        'order_id': bookingId, // Optional: generate from backend
        'prefill': {
          'contact': currentUser.mobile,
          'email': currentUser.email ?? '',
          'name': currentUser.name,
        },
        'theme': {
          'color': '#FF6B6B',
        },
        'timeout': 300,
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
      };

      // Set payment method preference
      if (selectedPaymentMethod == 0) {
        options['method'] = 'upi';
      } else if (selectedPaymentMethod == 1) {
        options['method'] = 'card';
      } else if (selectedPaymentMethod == 2) {
        options['method'] = 'netbanking';
      } else if (selectedPaymentMethod == 3) {
        options['method'] = 'wallet';
      }

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _createBooking(String status) async {
    final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || firebaseUser == null) {
      throw Exception('User not logged in');
    }

    final booking = BookingModel(
      id: '',
      userId: currentUser.uid,
      userName: currentUser.name,
      userPhone: currentUser.mobile,
      service: widget.serviceName,
      status: status,
      earnings: widget.totalAmount,
      scheduledTime: '${widget.date} ${widget.timeSlot}',
      address: '${widget.address['address']}, ${widget.address['city']}',
      notes: 'Payment method: ${paymentMethods[selectedPaymentMethod]['name']}',
      city: widget.address['city'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await FirebaseService.createBooking(booking);
  }

  Future<void> processPayment() async {
    // For Pay After Service
    if (selectedPaymentMethod == 4) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        final bookingId = await _createBooking('pending');
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.pop(context);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessPage(
              serviceName: widget.serviceName,
              amount: widget.totalAmount,
              date: widget.date,
              timeSlot: widget.timeSlot,
              bookingId: bookingId,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate based on payment method for online payments
    if (selectedPaymentMethod == 0 && upiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter UPI ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == 1) {
      if (cardNumberController.text.isEmpty ||
          cardHolderController.text.isEmpty ||
          expiryController.text.isEmpty ||
          cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all card details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (selectedPaymentMethod == 2 && selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPaymentMethod == 3 && selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a wallet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Open Razorpay for online payment
    _openRazorpayCheckout();
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
                  
                  // UPI ID Input
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

                  // Card Details
                  if (selectedPaymentMethod == 1)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: cardNumberController,
                            keyboardType: TextInputType.number,
                            maxLength: 16,
                            decoration: InputDecoration(
                              hintText: '1234 5678 9012 3456',
                              counterText: '',
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
                          const SizedBox(height: 16),
                          const Text(
                            'Card Holder Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: cardHolderController,
                            decoration: InputDecoration(
                              hintText: 'John Doe',
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
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Expiry Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: expiryController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'MM/YY',
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CVV',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: cvvController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 3,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText: '123',
                                        counterText: '',
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
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Net Banking
                  if (selectedPaymentMethod == 2)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Your Bank',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...banks.map((bank) {
                            final isSelected = selectedBank == bank['code'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedBank = bank['code'];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.bgMedium,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.bgLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        bank['name']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  // Wallet
                  if (selectedPaymentMethod == 3)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Your Wallet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: wallets.length,
                            itemBuilder: (context, index) {
                              final wallet = wallets[index];
                              final isSelected = selectedWallet == wallet['name'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedWallet = wallet['name'];
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.bgMedium,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        wallet['logo']!,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        wallet['name']!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                onPressed: processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedPaymentMethod == 4 
                      ? Colors.green 
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  selectedPaymentMethod == 4 ? 'Confirm Booking' : 'Pay Now',
                  style: const TextStyle(
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
}