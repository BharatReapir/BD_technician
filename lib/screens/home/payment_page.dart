import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../constants/colors.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_service.dart';
import '../../services/payment_service.dart';
import '../../services/coin_service.dart'; // ✅ NEW
import '../../providers/auth_provider.dart' as auth_provider;
import 'booking_success_page.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final double serviceCharge; // ✅ This already has coin discount applied from checkout
  final String date;
  final String timeSlot;
  final Map<String, String> address;
  // ✅ NEW: Coin parameters from checkout
  final int coinsUsed;
  final double coinDiscount;

  const PaymentPage({
    Key? key,
    required this.serviceName,
    required this.serviceCharge,
    required this.date,
    required this.timeSlot,
    required this.address,
    this.coinsUsed = 0,       // ✅ NEW
    this.coinDiscount = 0.0,  // ✅ NEW
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Razorpay _razorpay;
  String? _currentBookingId;
  bool _isProcessing = false;

  // Area type selection (for visiting charge)
  String _selectedArea = 'standard'; // 'standard' = ₹299, 'premium' = ₹399

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
    super.dispose();
  }

  // ==================== GST CALCULATIONS ====================
  
  double get visitingCharge {
    return _selectedArea == 'standard' ? 299.0 : 399.0;
  }

  // ✅ IMPORTANT: serviceCharge already has coin discount applied
  // So taxableAmount = (serviceCharge - coinDiscount) + visitingCharge
  double get taxableAmount {
    return widget.serviceCharge + visitingCharge;
  }

  double get gstAmount {
    return taxableAmount * 0.18; // 18% GST
  }

  double get totalAmount {
    return taxableAmount + gstAmount;
  }

  // ==================== RAZORPAY CALLBACKS ====================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success!');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');

    setState(() => _isProcessing = true);

    try {
      // 🔐 CRITICAL: Verify payment signature on backend
      final verificationResult = await PaymentService.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
        bookingId: _currentBookingId!,
      );

      if (verificationResult['verified'] == true) {
        debugPrint('✅ Payment verified by backend');

        // ✅ NEW: Redeem coins if used
        if (widget.coinsUsed > 0) {
          try {
            await CoinService.redeemCoins(
              userId: FirebaseAuth.instance.currentUser!.uid,
              bookingId: _currentBookingId!,
              coinsToRedeem: widget.coinsUsed,
            );
            debugPrint('✅ ${widget.coinsUsed} coins redeemed successfully');
          } catch (e) {
            debugPrint('⚠️ Coin redemption error: $e');
            // Continue with payment success even if coin redemption fails
          }
        }

        // Update booking status
        await FirebaseService.updateBookingStatus(_currentBookingId!, 'paid');
        await FirebaseService.updateBookingPaymentId(
          _currentBookingId!,
          response.paymentId!,
        );

        if (!mounted) return;

        // Show success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.coinsUsed > 0 
                ? 'Payment Successful! ${widget.coinsUsed} coins redeemed'
                : 'Payment Successful!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessPage(
              serviceName: widget.serviceName,
              amount: totalAmount,
              date: widget.date,
              timeSlot: widget.timeSlot,
              bookingId: _currentBookingId!,
            ),
          ),
        );
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      debugPrint('❌ Verification error: $e');
      
      if (!mounted) return;
      
      // Mark booking as payment_failed
      await FirebaseService.updateBookingStatus(_currentBookingId!, 'payment_failed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification failed: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint('❌ Payment Failed!');
    debugPrint('Code: ${response.code}');
    debugPrint('Message: ${response.message}');

    // Mark booking as payment_failed
    if (_currentBookingId != null) {
      await FirebaseService.updateBookingStatus(_currentBookingId!, 'payment_failed');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔷 External Wallet: ${response.walletName}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${response.walletName}...')),
    );
  }

  // ==================== PAYMENT FLOW ====================

  Future<void> _initiatePayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('User not logged in');

      final authProv = context.read<auth_provider.AuthProvider>();
      final userData = authProv.user ?? await FirebaseService.getUser(firebaseUser.uid);
      if (userData == null) throw Exception('User profile not found');

      // Step 1: Create booking with PENDING status
      debugPrint('📝 Creating booking...');
      final bookingId = await _createPendingBooking(userData);
      _currentBookingId = bookingId;

      // Step 2: Request backend to create Razorpay order
      debugPrint('🔐 Creating Razorpay order on backend...');
      final orderData = await PaymentService.createOrder(
        bookingId: bookingId,
        serviceCharge: widget.serviceCharge,
        area: _selectedArea,
        userId: firebaseUser.uid,
      );

      // Step 3: Update booking with Razorpay order ID and breakdown
      await _updateBookingWithOrderDetails(bookingId, orderData);

      // Step 4: Open Razorpay checkout
      debugPrint('💳 Opening Razorpay checkout...');
      _openRazorpayCheckout(orderData, userData);

    } catch (e) {
      debugPrint('❌ Payment initiation error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _payLater() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('User not logged in');

      final authProv = context.read<auth_provider.AuthProvider>();
      final userData = authProv.user ?? await FirebaseService.getUser(firebaseUser.uid);
      if (userData == null) throw Exception('User profile not found');

      // Create booking with pay_later status
      debugPrint('📝 Creating pay later booking...');
      final bookingId = await _createPayLaterBooking(userData);

      // ✅ Redeem coins if used (even for pay later)
      if (widget.coinsUsed > 0) {
        try {
          await CoinService.redeemCoins(
            userId: firebaseUser.uid,
            bookingId: bookingId,
            coinsToRedeem: widget.coinsUsed,
          );
          debugPrint('✅ ${widget.coinsUsed} coins redeemed successfully');
        } catch (e) {
          debugPrint('⚠️ Coin redemption error: $e');
          // Continue with booking even if coin redemption fails
        }
      }

      if (!mounted) return;

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.coinsUsed > 0 
              ? 'Booking confirmed! ${widget.coinsUsed} coins redeemed. Pay cash to technician.'
              : 'Booking confirmed! Pay cash to technician.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessPage(
            serviceName: widget.serviceName,
            amount: totalAmount,
            date: widget.date,
            timeSlot: widget.timeSlot,
            bookingId: bookingId,
          ),
        ),
      );

    } catch (e) {
      debugPrint('❌ Pay later error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String> _createPendingBooking(dynamic userData) async {
    final booking = BookingModel(
      id: '',
      userId: userData.uid,
      userName: userData.name,
      userPhone: userData.mobile,
      service: widget.serviceName,
      status: 'pending',
      serviceCharge: widget.serviceCharge,
      visitingCharge: visitingCharge,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      paymentStatus: 'pending',
      scheduledTime: '${widget.date} ${widget.timeSlot}',
      address: '${widget.address['address']}, ${widget.address['city']} - ${widget.address['pincode']}',
      city: widget.address['city']!,
      notes: widget.coinsUsed > 0 
          ? 'Area: $_selectedArea | Coins: ${widget.coinsUsed}' // ✅ NEW
          : 'Area: $_selectedArea',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // ✅ NEW: Add coin fields
      coinsUsed: widget.coinsUsed,
      coinDiscount: widget.coinDiscount,
    );

    return await FirebaseService.createBooking(booking);
  }

  Future<String> _createPayLaterBooking(dynamic userData) async {
    final booking = BookingModel(
      id: '',
      userId: userData.uid,
      userName: userData.name,
      userPhone: userData.mobile,
      service: widget.serviceName,
      status: 'confirmed',
      serviceCharge: widget.serviceCharge,
      visitingCharge: visitingCharge,
      taxableAmount: taxableAmount,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      paymentStatus: 'pay_later',
      scheduledTime: '${widget.date} ${widget.timeSlot}',
      address: '${widget.address['address']}, ${widget.address['city']} - ${widget.address['pincode']}',
      city: widget.address['city']!,
      notes: widget.coinsUsed > 0 
          ? 'Area: $_selectedArea | Coins: ${widget.coinsUsed} | Payment: Cash on Service'
          : 'Area: $_selectedArea | Payment: Cash on Service',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      coinsUsed: widget.coinsUsed,
      coinDiscount: widget.coinDiscount,
    );

    return await FirebaseService.createBooking(booking);
  }

  Future<void> _updateBookingWithOrderDetails(
    String bookingId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      await FirebaseService.updateBookingOrderDetails(
        bookingId: bookingId,
        razorpayOrderId: orderData['orderId'] as String,
        visitingCharge: visitingCharge,
        taxableAmount: taxableAmount,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
      );
    } catch (e) {
      debugPrint('❌ Error updating booking order details: $e');
      rethrow;
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData, dynamic userData) {
    var options = {
      'key': 'rzp_test_S4yQ9pfJFZGHEV',
      'amount': (totalAmount * 100).toInt(),
      'currency': 'INR',
      'name': 'Bharat Doorstep Repair',
      'description': widget.serviceName,
      'order_id': orderData['orderId'],
      'prefill': {
        'contact': userData.mobile,
        'email': userData.email,
        'name': userData.name,
      },
      'theme': {
        'color': '#00A86B',
      },
      'notes': {
        'booking_id': _currentBookingId,
        // ✅ NEW: Add coin info to Razorpay notes
        'coins_used': widget.coinsUsed.toString(),
        'coin_discount': widget.coinDiscount.toString(),
      },
    };

    debugPrint('🚀 Opening Razorpay with options: $options');
    _razorpay.open(options);
  }

  // ==================== UI ====================

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
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Price Breakdown Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: AppColors.bgLight,
            child: Column(
              children: [
                const Text(
                  'Payment Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPriceRow('Service Charge', widget.serviceCharge),
                
                // ✅ NEW: Show coin discount if applied
                if (widget.coinsUsed > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coin Discount',
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                          Text(
                            '(${widget.coinsUsed} coins used)',
                            style: const TextStyle(fontSize: 11, color: AppColors.textGray),
                          ),
                        ],
                      ),
                      const Text(
                        'Already applied',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Visiting Charge',
                  visitingCharge,
                  subtitle: _selectedArea == 'standard'
                      ? '(Standard Area)'
                      : '(Premium Area)',
                ),
                const Divider(height: 24),
                _buildPriceRow('Taxable Amount', taxableAmount, isBold: true),
                const SizedBox(height: 8),
                _buildPriceRow('GST @ 18%', gstAmount),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Payable',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                
                // ✅ NEW: Show savings if coins used
                if (widget.coinsUsed > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎉 You saved ₹${widget.coinDiscount.toStringAsFixed(2)} with coins!',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Area Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Area Type Selection
                  _buildAreaOption('standard', 'Standard Area', '₹299'),
                  const SizedBox(height: 12),
                  _buildAreaOption('premium', 'Premium / Remote Area', '₹399'),
                  
                  const SizedBox(height: 24),
                  
                  // Info Box
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
                      children: const [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Visiting charge is mandatory and non-refundable. Coin discount is applied before GST calculation. GST @18% is applied on taxable amount.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Payment Options Section
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pay Later (Cash) Option
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _payLater,
                    icon: const Icon(Icons.money, color: AppColors.primary),
                    label: const Text(
                      'Pay Later (Cash on Service)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Pay Now (Razorpay) Option
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _initiatePayment,
                    icon: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.payment, color: Colors.white),
                    label: Text(
                      _isProcessing ? 'Processing...' : 'Pay Now (Online)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.bgMedium,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Payment Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pay Later: Pay cash to technician after service completion\nPay Now: Secure online payment via Razorpay',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                            height: 1.4,
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
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {String? subtitle, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
          ],
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaOption(String value, String title, String price) {
    final isSelected = _selectedArea == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedArea = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.bgMedium,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Visiting Charge: $price',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}