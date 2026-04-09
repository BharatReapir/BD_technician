import 'package:bdr_technician_app/services/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/booking_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../providers/auth_provider.dart';

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

  File? _afterPhoto;
  String _paymentMode = 'Cash';
  bool _paymentReceived = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _materialCostController.dispose();
    _extraChargesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  double get _materialCost => double.tryParse(_materialCostController.text) ?? 0.0;
  double get _extraCharges => double.tryParse(_extraChargesController.text) ?? 0.0;
  double get _serviceCharge => widget.booking.serviceCharge;
  double get _gst => (_serviceCharge + _materialCost + _extraCharges) * 0.18;
  double get _totalAmount => _serviceCharge + _materialCost + _extraCharges + _gst;

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
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAfterPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2563EB)),
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


  Future<void> _generateInvoice() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final technician = authProvider.technician;
      if (technician == null) throw Exception('Technician not found');

      // Use Job Completion Certificate (not GST invoice — that's for the customer)
      await PDFService.printJobCompletionCertificate(
        booking: widget.booking,
        technicianName: technician.name,
        completedJobsCount: technician.completedJobs ?? 0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Certificate generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

      // Complete the job
      await FirebaseService.completeJobAndClearTechnician(
        widget.booking.id,
        technician.uid,
      );

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

      // Generate invoice automatically
      try {
        await _generateInvoice();
      } catch (e) {
        debugPrint('⚠️ Auto invoice generation failed: $e');
      }

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Job completed successfully! Customer received coins.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
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
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                    child: Text(
                      widget.booking.userName.isNotEmpty
                          ? widget.booking.userName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
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
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF2563EB).withOpacity(0.35),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: const Color(0xFF2563EB).withOpacity(0.6),
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Tap to upload after photo',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
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

            // ── Bill Summary ──────────────────────────────────────────
            _buildCard(
              backgroundColor: const Color(0xFFEFF6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.summarize_outlined,
                    title: 'Bill Summary',
                  ),
                  const SizedBox(height: 14),
                  _buildBillRow('Service Charge',
                      '₹${_serviceCharge.toStringAsFixed(0)}'),
                  if (_materialCost > 0)
                    _buildBillRow(
                        'Material Cost', '₹${_materialCost.toStringAsFixed(0)}'),
                  if (_extraCharges > 0)
                    _buildBillRow(
                        'Extra Charges', '₹${_extraCharges.toStringAsFixed(0)}'),
                  _buildBillRow('GST (18%)', '₹${_gst.toStringAsFixed(2)}'),
                  const Divider(height: 24, color: Color(0xFFBDD7FF)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Payment Details ───────────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: Icons.payment_outlined,
                    title: 'Payment Details',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'Cash',
                        groupValue: _paymentMode,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) => setState(() => _paymentMode = v!),
                      ),
                      const Text('Cash'),
                      const SizedBox(width: 24),
                      Radio<String>(
                        value: 'UPI',
                        groupValue: _paymentMode,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (v) => setState(() => _paymentMode = v!),
                      ),
                      const Text('UPI'),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                            'Payment Received',
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
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _generateInvoice,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text(
                        'Generate Invoice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
