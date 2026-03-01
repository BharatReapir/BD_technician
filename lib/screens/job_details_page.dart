import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Add this package
import '../constants/colors.dart';
import '../models/booking_model.dart';
import '../utils/commission_calculator.dart';
import 'job_in_progress_page.dart';
import 'complete_job_page.dart';

class JobDetailsPage extends StatefulWidget {
  final String bookingId;
  final String technicianId;

  const JobDetailsPage({
    Key? key,
    required this.bookingId,
    required this.technicianId,
  }) : super(key: key);

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  BookingModel? booking;
  bool isLoading = true;
  bool isConnected = true;
  bool _isDisposed = false;
  
  // NEW: Track both internet and Firebase connection
  bool hasInternet = true;
  bool firebaseConnected = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 === JOB DETAILS PAGE INIT ===');
    debugPrint('🔍 Received Booking ID: ${widget.bookingId}');
    debugPrint('🔍 Received Technician ID: ${widget.technicianId}');
    _initializeConnectionChecks();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _isDisposed = true;
    debugPrint('🗑️ JobDetailsPage disposed');
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _initializeConnectionChecks() async {
    _checkInternetConnection();
    
    _checkFirebaseConnection();
  }

  Future<void> _checkInternetConnection() async {
    try {
      // Listen to connectivity changes
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        if (_isDisposed) return;
        
        final connected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
        _safeSetState(() {
          hasInternet = connected;
          // Overall connection status is true if EITHER internet OR Firebase is connected
          isConnected = hasInternet || firebaseConnected;
        });
        
        debugPrint('🌐 Internet connectivity: ${connected ? "CONNECTED" : "DISCONNECTED"}');
      });
      
      // Check initial state
      final connectivityResults = await Connectivity().checkConnectivity();
      if (!_isDisposed) {
        _safeSetState(() {
          hasInternet = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
          isConnected = hasInternet || firebaseConnected;
        });
        debugPrint('🌐 Initial internet status: $hasInternet');
      }
    } catch (e) {
      debugPrint('❌ Error checking internet connectivity: $e');
      // Assume connected if we can't check
      if (!_isDisposed) {
        _safeSetState(() {
          hasInternet = true;
          isConnected = true;
        });
      }
    }
  }

  /// Check Firebase connection status
  Future<void> _checkFirebaseConnection() async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://bharat-doorstep-native-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      
      final connectedRef = database.ref('.info/connected');
      connectedRef.onValue.listen((event) {
        if (_isDisposed) return;
        
        final connected = event.snapshot.value as bool? ?? false;
        _safeSetState(() {
          firebaseConnected = connected;
          // Overall connection status is true if EITHER internet OR Firebase is connected
          isConnected = hasInternet || firebaseConnected;
        });
        debugPrint('🔥 Firebase connection: ${connected ? "CONNECTED" : "DISCONNECTED"}');
        debugPrint('🌐 Overall connection status: $isConnected');
      });
    } catch (e) {
      debugPrint('❌ Error checking Firebase connection: $e');
      // Assume connected if we can't check
      if (!_isDisposed) {
        _safeSetState(() {
          firebaseConnected = true;
          isConnected = true;
        });
      }
    }
  }

  Future<void> _loadBookingDetails() async {
    if (_isDisposed) return;
    
    // NEW: Wait a moment to let connection checks initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      debugPrint('🔍 === ENHANCED BOOKING LOAD START ===');
      debugPrint('🔍 Booking ID: ${widget.bookingId}');
      debugPrint('🔍 Technician ID: ${widget.technicianId}');
      debugPrint('🔍 Has Internet: $hasInternet');
      debugPrint('🔍 Firebase Connected: $firebaseConnected');
      debugPrint('🔍 Overall Connected: $isConnected');
      
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://bharat-doorstep-native-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      
      // Strategy 1: Direct fetch with shorter timeout
      debugPrint('🔍 Strategy 1: Direct booking fetch...');
      try {
        if (_isDisposed) return;
        
        final snapshot = await database.ref('bookings/${widget.bookingId}').get().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏰ Direct fetch timed out (5s)');
            throw Exception('Direct fetch timeout');
          },
        );
        
        if (_isDisposed) return;
        
        debugPrint('📊 Direct fetch - Snapshot exists: ${snapshot.exists}');
        
        if (snapshot.exists && snapshot.value != null) {
          final bookingData = Map<String, dynamic>.from(snapshot.value as Map);
          bookingData['id'] = widget.bookingId;
          
          debugPrint('✅ Strategy 1 SUCCESS: Direct fetch');
          await _processBookingData(bookingData);
          return;
        }
      } catch (e) {
        if (_isDisposed) return;
        debugPrint('❌ Strategy 1 FAILED: $e');
      }
      
      // Strategy 2: Search by technician ID (most likely to work)
      debugPrint('🔍 Strategy 2: Search by technician ID...');
      try {
        if (_isDisposed) return;
        
        final techBookingsSnapshot = await database.ref('bookings')
            .orderByChild('technicianId')
            .equalTo(widget.technicianId)
            .limitToLast(10)
            .get().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            throw Exception('Technician search timeout');
          },
        );
        
        if (_isDisposed) return;
        
        if (techBookingsSnapshot.exists && techBookingsSnapshot.value != null) {
          final bookingsMap = Map<String, dynamic>.from(techBookingsSnapshot.value as Map);
          debugPrint('📊 Found ${bookingsMap.length} bookings for technician');
          
          // Look for exact match first
          if (bookingsMap.containsKey(widget.bookingId)) {
            final bookingData = Map<String, dynamic>.from(bookingsMap[widget.bookingId]);
            bookingData['id'] = widget.bookingId;
            debugPrint('✅ Strategy 2 SUCCESS: Exact match in technician bookings');
            await _processBookingData(bookingData);
            return;
          }
          
          final sortedBookings = bookingsMap.entries.toList()
            ..sort((a, b) {
              final aTime = (a.value as Map)['acceptedAt'] ?? 0;
              final bTime = (b.value as Map)['acceptedAt'] ?? 0;
              return bTime.compareTo(aTime);
            });
          
          if (sortedBookings.isNotEmpty) {
            final bookingData = Map<String, dynamic>.from(sortedBookings.first.value);
            bookingData['id'] = sortedBookings.first.key;
            debugPrint('✅ Strategy 2 SUCCESS: Most recent booking ${sortedBookings.first.key}');
            await _processBookingData(bookingData);
            return;
          }
        }
      } catch (e) {
        if (_isDisposed) return;
        debugPrint('❌ Strategy 2 FAILED: $e');
      }
      
      // Strategy 3: Create fallback booking
      debugPrint('🔍 Strategy 3: Creating fallback booking...');
      await _createFallbackBooking();
      
    } catch (e) {
      if (_isDisposed) return;
      debugPrint('❌ All strategies failed: $e');
      await _handleLoadingError(e);
    }
  }

  /// Create a fallback booking when the original cannot be found
  Future<void> _createFallbackBooking() async {
    try {
      debugPrint('🆘 Creating fallback booking for job continuation...');
      
      String technicianName = 'Technician';
      String technicianPincode = '000000';
      
      // Only try to get technician data if we have internet
      if (hasInternet) {
        try {
          final database = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: 'https://bharat-doorstep-native-default-rtdb.asia-southeast1.firebasedatabase.app/',
          );
          
          final techSnapshot = await database.ref('technicians/${widget.technicianId}').get().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⏰ Technician data fetch timed out, using defaults');
              throw Exception('Technician fetch timeout');
            },
          );
          
          if (techSnapshot.exists && techSnapshot.value != null) {
            final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
            technicianName = techData['name'] ?? 'Technician';
            technicianPincode = techData['primaryPincode'] ?? '000000';
            debugPrint('✅ Got technician data: $technicianName, $technicianPincode');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to get technician data, using defaults: $e');
        }
      } else {
        debugPrint('🔌 No internet - using default technician data');
      }
      
      // Create fallback booking data with enhanced details
      final fallbackBookingData = {
        'id': widget.bookingId,
        'userId': 'fallback_user',
        'userName': hasInternet ? 'Customer (Loading...)' : 'Customer Name',
        'userPhone': '+91 9876543210',
        'service': 'AC Service', // More generic service name
        'status': 'accepted',
        'serviceCharge': 299.0,
        'visitingCharge': 99.0,
        'taxableAmount': 338.0,
        'gstAmount': 60.84,
        'totalAmount': 398.84,
        'paymentStatus': 'pending',
        'scheduledTime': '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${_formatTimeSlot()}',
        'address': hasInternet 
            ? 'Customer Address, Pincode: $technicianPincode'
            : 'Customer Address, Pincode: 410210',
        'city': 'Pune',
        'pincode': technicianPincode.isNotEmpty ? technicianPincode : '410210',
        'technicianId': widget.technicianId,
        'technicianName': technicianName,
        'notes': hasInternet 
            ? 'Fallback booking - original data loading failed. Please contact customer for details.'
            : 'Offline fallback booking - check connection and sync later',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        // Enhanced job details
        'customerRequirements': hasInternet ? 'Loading customer requirements...' : 'Check with customer directly',
        'problemDescription': hasInternet ? 'Loading problem details...' : 'Ask customer about the issue',
        'preferredTime': hasInternet ? 'Loading preferred time...' : 'Confirm timing with customer',
        'specialInstructions': hasInternet ? 'Loading instructions...' : 'No special instructions available offline',
      };
      
      debugPrint('🆘 Fallback booking created with ${hasInternet ? "online" : "offline"} data');
      await _processBookingData(fallbackBookingData);
      
      // Show appropriate warning to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasInternet 
                ? '⚠️ Using fallback data - some details may be incomplete'
                : '🔌 Offline mode - limited booking details available'),
            backgroundColor: hasInternet ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Error creating fallback booking: $e');
      rethrow;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _formatTimeSlot() {
    final now = DateTime.now();
    final startHour = (now.hour + 1) % 24;
    final endHour = (startHour + 2) % 24;
    
    String formatHour(int hour) {
      if (hour == 0) return '12:00 AM';
      if (hour < 12) return '${hour}:00 AM';
      if (hour == 12) return '12:00 PM';
      return '${hour - 12}:00 PM';
    }
    
    return '${formatHour(startHour)} - ${formatHour(endHour)}';
  }

  Future<void> _processBookingData(Map<String, dynamic> bookingData) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('📋 Processing booking data...');
      debugPrint('📋 Customer: ${bookingData['userName']}');
      debugPrint('📋 Service: ${bookingData['service']}');
      debugPrint('📋 Status: ${bookingData['status']}');
      
      final loadedBooking = BookingModel.fromJson(bookingData);
      
      _safeSetState(() {
        booking = loadedBooking;
        isLoading = false;
      });
      
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Job details loaded: ${loadedBooking.service}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error processing booking data: $e');
      rethrow;
    }
  }

  /// Handle loading errors with appropriate user feedback
  Future<void> _handleLoadingError(dynamic error) async {
    
    debugPrint('❌ Handling loading error: $error');
    
    _safeSetState(() {
      isLoading = false;
    });
    
    if (!_isDisposed && mounted) {
      String errorMessage = 'Error loading booking';
      Color errorColor = Colors.red;
      
      if (error.toString().contains('timeout') || error.toString().contains('Timeout')) {
        errorMessage = 'Connection timeout - please check your internet';
        errorColor = Colors.orange;
      } else if (error.toString().contains('not found')) {
        errorMessage = 'Booking not found - it may have been updated';
        errorColor = Colors.orange;
      } else if (error.toString().contains('permission')) {
        errorMessage = 'Permission denied - please try again';
        errorColor = Colors.red;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              if (!_isDisposed) {
                _safeSetState(() {
                  isLoading = true;
                  booking = null;
                });
                _loadBookingDetails();
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Connection status indicator
    Widget connectionIndicator = Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        if (!isConnected) ...[
          const SizedBox(width: 8),
          const Text(
            'Offline',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ],
    );

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0047AB),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Text('Job Details', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              connectionIndicator,
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                isConnected ? 'Loading job details...' : 'Loading offline...',
                style: const TextStyle(fontSize: 16),
              ),
              if (!isConnected) ...[
                const SizedBox(height: 8),
                const Text(
                  'Limited data available in offline mode',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobInProgressPage(
                        jobId: widget.bookingId,
                        customerName: 'Customer (Quick Start)',
                        service: 'Service Job',
                        timeSlot: 'ASAP',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Job Now'),
              ),
            ],
          ),
        ),
      );
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0047AB),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Text('Job Details', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              connectionIndicator,
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                if (!_isDisposed) {
                  _safeSetState(() {
                    isLoading = true;
                    booking = null;
                  });
                  _loadBookingDetails();
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking details not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${widget.bookingId.substring(0, 8)}...',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!_isDisposed) {
                        _safeSetState(() {
                          isLoading = true;
                          booking = null;
                        });
                        _loadBookingDetails();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047AB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobInProgressPage(
                            jobId: widget.bookingId,
                            customerName: 'Customer (Loading...)',
                            service: 'Service Job',
                            timeSlot: 'ASAP',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isConnected)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No internet connection. You can still start the job with limited data.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final earnings = CommissionCalculator.getTechnicianEarnings(booking!.totalAmount);
    final commission = CommissionCalculator.getCommission(booking!.totalAmount);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0047AB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Job Details',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            connectionIndicator,
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              if (!_isDisposed) {
                _safeSetState(() {
                  isLoading = true;
                  booking = null;
                });
                _loadBookingDetails();
              }
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Information Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name:', booking!.userName),
                  const SizedBox(height: 12),
                  _buildInfoRow('Phone:', booking!.userPhone),
                  const SizedBox(height: 12),
                  _buildInfoRow('Address:', booking!.address ?? 'Not provided'),
                  const SizedBox(height: 12),
                  _buildInfoRow('City:', booking!.city ?? 'Not specified'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Pincode:', booking!.pincode ?? 'Not available'),
                  const SizedBox(height: 24),
                  
                  // Call Customer Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement call functionality
                      },
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text(
                        'Call Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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

            const Divider(height: 1, thickness: 1),

            // Service Details Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Service:', booking!.service),
                  const SizedBox(height: 12),
                  _buildInfoRow('Time Slot:', booking!.scheduledTime),
                  const SizedBox(height: 12),
                  _buildInfoRow('Status:', booking!.status.toUpperCase(), 
                      valueColor: booking!.status == 'accepted' ? Colors.green : AppColors.primary),
                  const SizedBox(height: 12),
                  _buildInfoRow('Your Earnings:', '₹${earnings.toStringAsFixed(0)}', 
                      valueColor: Colors.green),
                  const SizedBox(height: 12),
                  _buildInfoRow('Commission:', '-₹${commission.toStringAsFixed(0)} (20%)', 
                      valueColor: AppColors.primary),
                  const SizedBox(height: 12),
                  _buildInfoRow('Total Amount:', '₹${booking!.totalAmount.toStringAsFixed(0)}', 
                      valueColor: Colors.black87),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // ── Invoice / Bill Summary ────────────────────────────────
            Container(
              color: const Color(0xFFF8FAFF),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Invoice Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInvoiceRow(
                    'Service Charge',
                    '₹${booking!.serviceCharge.toStringAsFixed(0)}',
                  ),
                  if (booking!.visitingCharge > 0) ...[
                    const SizedBox(height: 8),
                    _buildInvoiceRow(
                      'Visiting Charge',
                      '₹${booking!.visitingCharge.toStringAsFixed(0)}',
                    ),
                  ],
                  if (booking!.gstAmount > 0) ...[
                    const SizedBox(height: 8),
                    _buildInvoiceRow(
                      'GST (18%)',
                      '₹${booking!.gstAmount.toStringAsFixed(2)}',
                    ),
                  ],
                  if ((booking!.coinDiscount ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    _buildInvoiceRow(
                      'Coin Discount',
                      '-₹${booking!.coinDiscount!.toStringAsFixed(0)}',
                      valueColor: Colors.green,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(thickness: 1),
                  ),
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
                        '₹${booking!.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Technician Earnings summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Earnings (after 20% commission)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '₹${earnings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Platform fee',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black38,
                              ),
                            ),
                            Text(
                              '-₹${commission.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Additional Job Information Section (if available)
            if (booking!.notes != null && booking!.notes!.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        booking!.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Bottom Action Button — fully status-aware
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStatusActionButton(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Build the bottom action button based on booking status
  Widget _buildStatusActionButton() {
    final status = booking?.status ?? '';

    if (status == 'completed') {
      // ✅ Job Completed badge — non-tappable
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text(
              '✅ Job Completed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'in_progress') {
      // Resume Job button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobInProgressPage(
                  jobId: widget.bookingId,
                  customerName: booking!.userName,
                  service: booking!.service,
                  timeSlot: booking!.scheduledTime,
                ),
              ),
            );
          },
          icon: const Icon(Icons.play_circle_fill, color: Colors.white),
          label: const Text(
            'Resume Job',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      );
    }

    if (status == 'accepted') {
      // Start Job + Complete Job buttons side by side
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobInProgressPage(
                      jobId: widget.bookingId,
                      customerName: booking!.userName,
                      service: booking!.service,
                      timeSlot: booking!.scheduledTime,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                'Start Job',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompleteJobPage(booking: booking!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                'Complete Job',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    // Default: Start Job button for any other status
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobInProgressPage(
                jobId: widget.bookingId,
                customerName: booking!.userName,
                service: booking!.service,
                timeSlot: booking!.scheduledTime,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: const Text(
          'Start Job',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}