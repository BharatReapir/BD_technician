import 'package:bdr_technician_app/services/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/booking_model.dart';
import '../models/billing_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../providers/auth_provider.dart';
import '../utils/commission_calculator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CompleteJobPage extends StatefulWidget {
  final BookingModel booking;
  final List<File>? beforePhotos;

  const CompleteJobPage({
    Key? key,
    required this.booking,
    this.beforePhotos,
  }) : super(key: key);

  @override
  State<CompleteJobPage> createState() => _CompleteJobPageState();
}

class _CompleteJobPageState extends State<CompleteJobPage> {
  final TextEditingController _materialCostController = TextEditingController();
  final TextEditingController _extraChargesController = TextEditingController();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  final ImagePicker _picker = ImagePicker();

  late Razorpay _razorpay;

  File? _afterPhoto;
  String _paymentMode = 'Cash';
  bool _paymentReceived = false;
  bool _isLoading = false;
  bool _showQRCode = false;

  // Check if customer already paid online
  bool get _isAlreadyPaid => 
      widget.booking.paymentStatus == 'paid' || 
      widget.booking.paymentStatus == 'completed';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    // Auto-set payment received if already paid online
    if (_isAlreadyPaid) {
      _paymentReceived = true;
      _paymentMode = widget.booking.paymentMethod ?? 'UPI';
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (mounted) {
      setState(() {
        _paymentReceived = true;
        _paymentMode = 'UPI (Razorpay)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _materialCostController.dispose();
    _extraChargesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  double get _materialCost => double.tryParse(_materialCostController.text) ?? 0.0;
  double get _extraCharges => double.tryParse(_extraChargesController.text) ?? 0.0;

  /// Service Amount = base service charge + material + extra charges
  /// This is the "kaam ka charge" - the actual work amount
  double get _serviceAmount => widget.booking.serviceCharge + _materialCost + _extraCharges;

  /// Visiting charge from the booking (if applicable)
  double get _visitingCharge => widget.booking.visitingCharge;

  /// GST is calculated on Service Amount only (Rule #3)
  double get _gst => CommissionCalculator.getGSTAmount(_serviceAmount);

  /// Final Bill = Service Amount + GST (Rule #3)
  double get _finalBill => _serviceAmount + _gst;

  /// Commission is based on Service Amount only, NOT Final Bill (Rule #4, #11)
  double get _commissionToCompany => CommissionCalculator.getCommission(_serviceAmount);

  /// GST goes to company
  double get _gstToCompany => _gst;

  /// Technician Net Earning = Final Bill - GST - Commission = Service Amount - Commission (Rule #9)
  double get _technicianEarnings => CommissionCalculator.getTechnicianEarnings(_serviceAmount);

  Future<void> _pickAfterPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _afterPhoto = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1E286D)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAfterPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1E286D)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAfterPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }



  Future<void> _completeJob() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get customer signature first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_paymentReceived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm payment received'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_afterPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an after photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final technician = authProvider.technician;
      if (technician == null) throw Exception('Technician not found');

      // Upload photos to Firebase Storage
      List<String> beforePhotoUrls = [];
      String? afterPhotoUrl;

      try {
        if (widget.beforePhotos != null && widget.beforePhotos!.isNotEmpty) {
          for (int i = 0; i < widget.beforePhotos!.length; i++) {
            final url = await FirebaseService.uploadJobPhoto(
              widget.beforePhotos![i], 
              widget.booking.id, 
              'before_$i'
            );
            beforePhotoUrls.add(url);
          }
        }

        if (_afterPhoto != null) {
          afterPhotoUrl = await FirebaseService.uploadJobPhoto(
            _afterPhoto!, 
            widget.booking.id, 
            'after'
          );
        }

        // Update photo URLs in booking
        await FirebaseService.updateBookingPhotos(
          bookingId: widget.booking.id,
          beforePhotos: beforePhotoUrls,
          afterPhoto: afterPhotoUrl,
        );
      } catch (e) {
        debugPrint('⚠️ Error uploading photos, but continuing job completion: $e');
        // We still continue to complete the job even if photo upload fails
      }

      // Update payment status in Firebase
      if (!_isAlreadyPaid) {
        await FirebaseService.updatePaymentStatus(
          bookingId: widget.booking.id,
          paymentStatus: 'paid',
          paymentMethod: _paymentMode,
        );
      }

      // Complete the job
      await FirebaseService.completeJobAndClearTechnician(
        widget.booking.id,
        technician.uid,
      );

      // Credit technician earnings (GST & commission go to company)
      // Rule: Commission is based on Service Amount only, NOT Final Bill
      try {
        final earningsData = CommissionCalculator.calculateEarnings(_serviceAmount);
        await FirebaseService.creditTechnicianEarnings(
          technicianId: technician.uid,
          bookingId: widget.booking.id,
          serviceAmount: _serviceAmount,
          earnings: earningsData['technicianEarnings'],
          gstAmount: earningsData['gstAmount'],
          commission: earningsData['commission'],
          finalBill: _finalBill,
          visitingCharge: _visitingCharge,
          paymentMethod: _paymentMode,
        );
      } catch (e) {
        debugPrint('⚠️ Error crediting earnings: $e');
      }

      await authProvider.refreshTechnicianData();

      // Award coins to user
      try {
        final userBookings = await FirebaseService.getUserBookings(widget.booking.userId);
        final completedCount = userBookings.where((b) => b.status == 'completed').length;
        final bookingNumber = completedCount + 1;

        int coinsToAward;
        if (bookingNumber <= 5) {
          final welcomeCoinsMap = {1: 1000, 2: 1500, 3: 2000, 4: 2500, 5: 3000};
          coinsToAward = welcomeCoinsMap[bookingNumber] ?? 0;
        } else {
          coinsToAward = ((widget.booking.totalAmount * 0.1).round()).clamp(10, 100);
        }

        if (coinsToAward > 0) {
          await CoinService.creditCoins(
            userId: widget.booking.userId,
            bookingId: widget.booking.id,
            coins: coinsToAward,
            bookingNumber: bookingNumber,
          );
        }
      } catch (e) {
        debugPrint('❌ Error crediting coins: $e');
      }

      // Credit logic moved above and auto-invoice removed

      setState(() => _isLoading = false);

      // Show success sheet instead of immediate pop
      if (mounted) {
        _showJobSuccessSheet();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E286D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Job',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Customer Info Header ──────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF1E286D).withOpacity(0.12),
                    child: Text(
                      widget.booking.userName.isNotEmpty
                          ? widget.booking.userName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E286D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.booking.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.booking.service,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (widget.booking.scheduledTime.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                widget.booking.scheduledTime,
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '₹${widget.booking.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Upload After Photo ────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.camera_alt_outlined,
                    title: 'Upload After Photo',
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: _afterPhoto != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _afterPhoto!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _afterPhoto = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _showPhotoOptions,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF1E286D).withOpacity(0.35),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: const Color(0xFF1E286D).withOpacity(0.6),
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tap to upload after photo',
                                  style: TextStyle(
                                    color: Color(0xFF1E286D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Camera or Gallery',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Additional Costs ──────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.receipt_long_outlined,
                    title: 'Additional Costs',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _materialCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Material Cost',
                      hintText: '0',
                      prefixText: '₹  ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _extraChargesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Extra Charges',
                      hintText: '0',
                      prefixText: '₹  ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Invoice Breakdown (Customer Bill) ──────────────────────
            _buildCard(
              backgroundColor: const Color(0xFFEFF6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.receipt_outlined,
                    title: 'Invoice Breakdown',
                  ),
                  const SizedBox(height: 14),
                  _buildBillRow('Service Amount',
                      '₹${widget.booking.serviceCharge.toStringAsFixed(0)}'),
                  if (_materialCost > 0)
                    _buildBillRow(
                        'Material Cost', '₹${_materialCost.toStringAsFixed(0)}'),
                  if (_extraCharges > 0)
                    _buildBillRow(
                        'Extra Charges', '₹${_extraCharges.toStringAsFixed(0)}'),
                  if (_visitingCharge > 0) ...[
                    _buildBillRow(
                        'Visiting Charge', '₹${_visitingCharge.toStringAsFixed(0)}'),
                    _buildBillRow(
                        'Visiting Charge (Adjusted)', '-₹${_visitingCharge.toStringAsFixed(0)}'),
                  ],
                  _buildBillRow('GST (18%)', '₹${_gst.toStringAsFixed(0)}'),
                  const Divider(height: 24, color: Color(0xFFBDD7FF)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '₹${_finalBill.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E286D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Commission slab info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E286D).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Commission Slab: Service Amount ₹${_serviceAmount.toStringAsFixed(0)} '
                      '${_serviceAmount > 1000 ? '(> ₹1000 = ₹399)' : '(<= ₹1000 = ₹199)'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF1E286D).withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Earnings Breakdown (Technician) ──────────────────────
            _buildCard(
              backgroundColor: Colors.green.withOpacity(0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Your Earnings Breakdown',
                  ),
                  const SizedBox(height: 14),
                  _buildBillRow('Service Amount', '₹${_serviceAmount.toStringAsFixed(0)}'),
                  _buildBillRow('GST Deduction (to Company)', '-₹${_gstToCompany.toStringAsFixed(0)}'),
                  _buildBillRow('Commission Deduction (to Company)', '-₹${_commissionToCompany.toStringAsFixed(0)}'),
                  const Divider(height: 16, color: Colors.green),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Earning',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '₹${_technicianEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Payment Status & Collection ────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.payment_outlined,
                    title: 'Payment Collection',
                  ),
                  const SizedBox(height: 12),

                  // ✅ Already Paid indicator
                  if (_isAlreadyPaid) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Already Paid',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Payment via ${widget.booking.paymentMethod ?? 'Online'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ❌ Not Paid - Show payment options
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Payment Pending - Collect from customer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Cash Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _paymentMode = 'Cash';
                              _showQRCode = false;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _paymentMode == 'Cash'
                                    ? const Color(0xFF1E286D).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _paymentMode == 'Cash'
                                      ? const Color(0xFF1E286D)
                                      : Colors.grey.withOpacity(0.3),
                                  width: _paymentMode == 'Cash' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.money,
                                    color: _paymentMode == 'Cash'
                                        ? const Color(0xFF1E286D)
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pay via Cash',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _paymentMode == 'Cash'
                                          ? const Color(0xFF1E286D)
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // UPI Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _paymentMode = 'UPI';
                              _showQRCode = true;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _paymentMode == 'UPI'
                                    ? const Color(0xFF1E286D).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _paymentMode == 'UPI'
                                      ? const Color(0xFF1E286D)
                                      : Colors.grey.withOpacity(0.3),
                                  width: _paymentMode == 'UPI' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code_2,
                                    color: _paymentMode == 'UPI'
                                        ? const Color(0xFF1E286D)
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pay via UPI',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _paymentMode == 'UPI'
                                          ? const Color(0xFF1E286D)
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // QR Code Display for UPI (Hide once payment is confirmed)
                    if (!(_paymentReceived) && (_showQRCode || _paymentMode == 'UPI')) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E286D).withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Scan to Pay via UPI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E286D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Static QR Code Image
                            Container(
                              height: 250,
                              width: 250,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/upi_qr.jpeg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        Text(
                                          'UPI QR Code\n(Add assets/upi_qr.jpeg)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Amount Payable: ₹${_finalBill.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ask customer to scan this QR with any UPI app (GPay, PhonePe, Paytm). Once payment is received, mark as paid below to finish the job.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Payment confirmed toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentReceived
                            ? Colors.green.withOpacity(0.09)
                            : Colors.grey.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _paymentReceived
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _paymentReceived
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _paymentReceived
                                ? Colors.green
                                : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paymentReceived ? 'Payment Confirmed' : 'Confirm Payment Received',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _paymentReceived
                                    ? Colors.green.shade700
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Switch(
                            value: _paymentReceived,
                            activeColor: Colors.green,
                            onChanged: (v) => setState(() => _paymentReceived = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Customer Signature ────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        icon: Icons.draw_outlined,
                        title: 'Customer Signature *',
                      ),
                      TextButton.icon(
                        onPressed: () => _signatureController.clear(),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Signature(
                      controller: _signatureController,
                      backgroundColor: Colors.grey[50]!,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask customer to sign above to confirm service completion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Action Buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _completeJob,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isLoading ? 'Processing...' : 'Complete Job',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  void _showJobSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Job Completed Successfully!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Job has been marked as finished. Your wallet has been updated based on the payment method.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _generateInvoice(),
                icon: const Icon(Icons.verified_outlined),
                label: const Text(
                  'Certificate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E286D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E286D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _generateInvoice() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final technician = authProvider.technician;
      if (technician == null) throw Exception('Technician not found');

      await PDFService.printJobCompletionCertificate(
        booking: widget.booking,
        technicianName: technician.name,
        completedJobsCount: technician.completedJobs ?? 0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating certificate: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCard({required Widget child, Color? backgroundColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
