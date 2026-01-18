import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../constants/colors.dart';
import '../../models/booking_model.dart';
import '../../services/firebase_service.dart';
import '../../services/payment_service.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import 'booking_success_page.dart';

class PaymentPage extends StatefulWidget {
  final String serviceName;
  final double serviceCharge; // Base service price (e.g., ₹1000)
  final String date;
  final String timeSlot;
  final Map<String, String> address;

  const PaymentPage({
    Key? key,
    required this.serviceName,
    required this.serviceCharge,
    required this.date,
    required this.timeSlot,
    required this.address,
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

  // Payment breakdown (calculated by backend)
  double? _visitingCharge;
  double? _taxableAmount;
  double? _gstAmount;
  double? _totalAmount;

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

        // Update booking status
        await FirebaseService.updateBookingStatus(_currentBookingId!, 'paid');
        await FirebaseService.updateBookingPaymentId(
          _currentBookingId!,
          response.paymentId!,
        );

        if (!mounted) return;

        // Show success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessPage(
              serviceName: widget.serviceName,
              amount: _totalAmount ?? 0,
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
          backgroundColor: Colors.red,
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
        backgroundColor: Colors.red,
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

      // Step 3: Store payment breakdown from backend
      setState(() {
        _visitingCharge = orderData['breakdown']['visitingCharge'];
        _taxableAmount = orderData['breakdown']['taxableAmount'];
        _gstAmount = orderData['breakdown']['gstAmount'];
        _totalAmount = orderData['breakdown']['totalAmount'];
      });

      // Step 4: Update booking with Razorpay order ID and breakdown
      await _updateBookingWithOrderDetails(bookingId, orderData);

      // Step 5: Open Razorpay checkout
      debugPrint('💳 Opening Razorpay checkout...');
      _openRazorpayCheckout(orderData, userData);

    } catch (e) {
      debugPrint('❌ Payment initiation error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
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
      status: 'pending', // Will change to 'paid' after verification
      serviceCharge: widget.serviceCharge,
      visitingCharge: 0, // Will be updated from backend
      taxableAmount: 0,
      gstAmount: 0,
      totalAmount: 0,
      paymentStatus: 'pending',
      scheduledTime: '${widget.date} ${widget.timeSlot}',
      address: '${widget.address['address']}, ${widget.address['city']}',
      city: widget.address['city'],
      notes: 'Area: $_selectedArea',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await FirebaseService.createBooking(booking);
  }

  Future<void> _updateBookingWithOrderDetails(
    String bookingId,
    Map<String, dynamic> orderData,
  ) async {
    await FirebaseService._realtimeDb.ref('bookings/$bookingId').update({
      'razorpayOrderId': orderData['orderId'],
      'visitingCharge': orderData['breakdown']['visitingCharge'],
      'taxableAmount': orderData['breakdown']['taxableAmount'],
      'gstAmount': orderData['breakdown']['gstAmount'],
      'totalAmount': orderData['breakdown']['totalAmount'],
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData, dynamic userData) {
    var options = {
      'key': 'YOUR_RAZORPAY_KEY_ID', // 🔒 REPLACE with your Razorpay Test Key
      'amount': orderData['amount'], // Amount in paise (from backend)
      'currency': 'INR',
      'name': 'Bharat Doorstep Repair',
      'description': widget.serviceName,
      'order_id': orderData['orderId'], // CRITICAL: Use order_id from backend
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
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Visiting Charge',
                  _selectedArea == 'standard' ? 299 : 399,
                  subtitle: _selectedArea == 'standard'
                      ? '(Standard Area)'
                      : '(Premium Area)',
                ),
                const Divider(height: 24),
                _buildPriceRow('GST @ 18%', null, isCalculating: true),
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
                      '₹${_calculateDisplayTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
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
                            'Visiting charge is mandatory and non-refundable. GST @18% will be applied on total taxable amount.',
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

          // Pay Now Button
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
                onPressed: _isProcessing ? null : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.bgMedium,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
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

  Widget _buildPriceRow(String label, double? amount,
      {String? subtitle, bool isCalculating = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
          ],
        ),
        Text(
          isCalculating
              ? 'Calculated on backend'
              : '₹${amount!.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
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

  double _calculateDisplayTotal() {
    final visitingCharge = _selectedArea == 'standard' ? 299 : 399;
    final taxable = widget.serviceCharge + visitingCharge;
    final gst = taxable * 0.18;
    return taxable + gst;
  }
}