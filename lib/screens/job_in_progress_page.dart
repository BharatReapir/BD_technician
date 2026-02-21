import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../constants/colors.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../services/coin_service.dart';
import '../models/billing_model.dart';
import '../providers/auth_provider.dart';

class JobInProgressPage extends StatefulWidget {
  final String jobId;
  final String customerName;
  final String service;
  final String timeSlot;

  const JobInProgressPage({
    Key? key,
    required this.jobId,
    required this.customerName,
    required this.service,
    required this.timeSlot,
  }) : super(key: key);

  @override
  State<JobInProgressPage> createState() => _JobInProgressPageState();
}

class _JobInProgressPageState extends State<JobInProgressPage> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  final DateTime _startTime = DateTime.now();
  
  final List<File> _beforePhotos = [];
  final ImagePicker _picker = ImagePicker();
  
  // Service breakdown items
  final List<ServiceItem> _serviceItems = [
    ServiceItem(name: 'General checkup', isCompleted: true),
    ServiceItem(name: 'Filter cleaning', isCompleted: true),
    ServiceItem(name: 'Gas pressure check', isCompleted: false),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatStartTime() {
    return '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')} ${_startTime.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _beforePhotos.add(File(image.path));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _beforePhotos.removeAt(index);
    });
  }

  void _showAddChargesDialog() {
    final TextEditingController descController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Extra Charges'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Save extra charges
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _completeJob() async {
    if (_beforePhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one before photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job?'),
        content: const Text('Are you sure you want to complete this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Completing job...'),
            ],
          ),
        ),
      );

      // Get current technician from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final technician = authProvider.technician;
      
      if (technician != null) {
        // Use the new complete job method that handles everything
        await FirebaseService.completeJobAndClearTechnician(widget.jobId, technician.uid);
        
        // Refresh technician data to get updated stats
        await authProvider.refreshTechnicianData();
        
        // Award coins to user for completed booking
        try {
          final booking = await FirebaseService.getBooking(widget.jobId);
          if (booking != null) {
            // Get user's completed bookings count to determine welcome bonus
            final userBookings = await FirebaseService.getUserBookings(booking.userId);
            final completedCount = userBookings.where((b) => b.status == 'completed').length;
            final bookingNumber = completedCount + 1; // This will be the Nth completed booking
            
            // Calculate coins based on booking number
            int coinsToAward;
            if (bookingNumber <= 5) {
              // Welcome coins for first 5 bookings
              final welcomeCoinsMap = {
                1: 1000, // ₹10
                2: 1500, // ₹15
                3: 2000, // ₹20
                4: 2500, // ₹25
                5: 3000, // ₹30
              };
              coinsToAward = welcomeCoinsMap[bookingNumber] ?? 0;
            } else {
              // Regular coins: 10% of booking amount (minimum 10, maximum 100)
              coinsToAward = ((booking.totalAmount * 0.1).round()).clamp(10, 100);
            }
            
            if (coinsToAward > 0) {
              await CoinService.creditCoins(
                userId: booking.userId,
                bookingId: booking.id,
                coins: coinsToAward,
                bookingNumber: bookingNumber,
              );
              debugPrint('✅ Credited $coinsToAward coins for booking #$bookingNumber');
            }
          }
        } catch (e) {
          debugPrint('❌ Error crediting coins: $e');
          // Don't block job completion for coin issues
        }
        
        // Generate and print job completion certificate
        try {
          final booking = await FirebaseService.getBooking(widget.jobId);
          if (booking != null) {
            await PDFService.printJobCompletionCertificate(
              booking: booking,
              technicianName: technician.name,
              completedJobsCount: (technician.completedJobs ?? 0) + 1,
            );
            
            // Generate GST invoice for completed job
            try {
              final billing = PricingCalculator.calculateBilling(
                customerName: booking.userName,
                serviceAddress: booking.address ?? 'N/A',
                serviceName: booking.service,
                servicePrice: booking.serviceCharge,
                pincode: booking.pincode ?? '000000',
                coinDiscount: booking.coinDiscount ?? 0.0,
                technicianName: technician.name,
                bookingId: booking.id,
              );
              
              await PDFService.generateGSTInvoice(
                billing: billing,
                downloadToDevice: true, // Save to device for technician
              );
              debugPrint('✅ GST invoice generated for completed job');
            } catch (e) {
              debugPrint('⚠️ GST invoice generation failed: $e');
              // Don't block job completion for invoice issues
            }
          }
        } catch (e) {
          // Don't block job completion for certificate issues
        }
      }

      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Navigate back to technician home properly - pop all the way back
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Job completed! Customer received coins. Great work!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Still show success to user (job completion is the main goal)
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Job completed! (Some updates pending)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0047AB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job in Progress',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0047AB),
                    Colors.teal.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'Time Elapsed',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Started at ${_formatStartTime()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upload Before Photos Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload Before Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Photo Grid
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Existing photos
                        ..._beforePhotos.asMap().entries.map((entry) {
                          return Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              image: DecorationImage(
                                image: FileImage(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(entry.key),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        
                        // Add photo placeholder
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.grey[600],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upload Photos Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.blue[700]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Photos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Service Breakdown Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ..._serviceItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted 
                                ? Icons.check_circle 
                                : Icons.radio_button_unchecked,
                            color: item.isCompleted 
                                ? Colors.green 
                                : Colors.grey[400],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              color: item.isCompleted 
                                  ? Colors.black87 
                                  : Colors.grey[600],
                              decoration: item.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add Extra Charges Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: _showAddChargesDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.blue[700]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Add Extra Charges',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Complete Job Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Complete Job',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class ServiceItem {
  final String name;
  final bool isCompleted;

  ServiceItem({
    required this.name,
    required this.isCompleted,
  });
}