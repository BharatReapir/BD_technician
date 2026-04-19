import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/booking_model.dart';
import '../models/billing_model.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../providers/coin_provider.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _lastRefresh = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh when returning to this page
    _forceRefreshIfNeeded();
  }

  void _forceRefreshIfNeeded() {
    final now = DateTime.now();
    if (_lastRefresh == null || now.difference(_lastRefresh!).inSeconds > 5) {
      debugPrint('🔄 Force refreshing bookings page...');
      _lastRefresh = now;
      // Trigger a rebuild to refresh the stream
      if (mounted) {
        setState(() {});
      }
    }
  }

  int _calculateCoins(double amount) {
    if (amount >= 900) return 50;
    if (amount >= 700) return 40;
    if (amount >= 500) return 30;
    if (amount >= 300) return 20;
    return 10;
  }

  Future<void> _testFirebaseConnection(String userId) async {
    try {
      debugPrint('🧪 === FIREBASE DEBUG TEST ===');
      debugPrint('🧪 AuthProvider user ID: $userId');
      
      // Test 1: Check Firebase Auth current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      debugPrint('🧪 Firebase Auth user ID: ${firebaseUser?.uid}');
      debugPrint('🧪 Firebase Auth email: ${firebaseUser?.email}');
      debugPrint('🧪 Firebase Auth phone: ${firebaseUser?.phoneNumber}');
      debugPrint('🧪 User ID match: ${firebaseUser?.uid == userId}');
      
      // Test 2: Direct fetch using FirebaseService (this should work)
      debugPrint('🧪 Testing direct fetch via FirebaseService...');
      final directBookings = await FirebaseService.getUserBookings(userId);
      debugPrint('🧪 Direct fetch result: ${directBookings.length} bookings');
      
      for (var booking in directBookings) {
        debugPrint('🧪   - ${booking.service} | ${booking.status} | User: ${booking.userId} | ID: ${booking.id} | Created: ${booking.createdAt}');
      }
      
      // Test 3: Check if the stream is working
      debugPrint('🧪 Testing stream...');
      final streamBookings = await FirebaseService.streamUserBookings(userId).first;
      debugPrint('🧪 Stream result: ${streamBookings.length} bookings');
      
      for (var booking in streamBookings) {
        debugPrint('🧪 Stream - ${booking.service} | ${booking.status} | Created: ${booking.createdAt}');
      }
      
      // Test 4: Check specific status filtering
      final upcomingFromDirect = _getUpcomingBookings(directBookings);
      final upcomingFromStream = _getUpcomingBookings(streamBookings);
      debugPrint('🧪 Upcoming from direct: ${upcomingFromDirect.length}');
      debugPrint('🧪 Upcoming from stream: ${upcomingFromStream.length}');
      
      // Test 5: Check for recent bookings (last 24 hours)
      final now = DateTime.now();
      final recent = directBookings.where((b) => 
        now.difference(b.createdAt).inHours < 24
      ).toList();
      debugPrint('🧪 Recent bookings (24h): ${recent.length}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Debug: Direct=${directBookings.length}, Stream=${streamBookings.length}, Recent=${recent.length}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🧪 Test failed: $e');
      debugPrint('🧪 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<BookingModel> _getUpcomingBookings(List<BookingModel> bookings) {
    return bookings
        .where((b) => 
            b.status == 'pending' || 
            b.status == 'confirmed' ||  // ✅ ADD: Pay Later bookings
            b.status == 'accepted' || 
            b.status == 'in_progress')
        .toList();
  }

  List<BookingModel> _getCompletedBookings(List<BookingModel> bookings) {
    return bookings.where((b) => b.status == 'completed').toList();
  }

  List<BookingModel> _getCancelledBookings(List<BookingModel> bookings) {
    return bookings.where((b) => b.status == 'cancelled').toList();
  }

  Future<void> _creditCoinsForCompletedBookings(List<BookingModel> bookings) async {
    if (!mounted) return;

    try {
      final coinProvider = context.read<CoinProvider>();
      
      // Get completed bookings sorted by date
      final completedBookings = bookings
          .where((b) => b.status == 'completed')
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (int i = 0; i < completedBookings.length; i++) {
        final booking = completedBookings[i];
        final bookingNumber = i + 1; // 1st, 2nd, 3rd, etc.
        
        // Calculate coins based on booking number
        int coins;
        if (bookingNumber <= 5) {
          // Welcome coins for first 5 bookings
          final welcomeCoinsMap = {
            1: 1000, // ₹10
            2: 1500, // ₹15
            3: 2000, // ₹20
            4: 2500, // ₹25
            5: 3000, // ₹30
          };
          coins = welcomeCoinsMap[bookingNumber] ?? 0;
        } else {
          // Regular coins: 10% of booking amount
          coins = _calculateCoins(booking.totalAmount);
        }

        debugPrint('💰 Attempting to credit $coins coins for booking #$bookingNumber (${booking.id})');

        await coinProvider.creditCoins(
          bookingId: booking.id,
          coins: coins,
          bookingNumber: bookingNumber,
        );
      }
    } catch (e) {
      debugPrint('❌ Error crediting coins: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<auth_provider.AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUser = authProvider.user;
        
        debugPrint('🔍 Current user: ${currentUser?.uid}');
        debugPrint('🔍 User name: ${currentUser?.name}');
        
        if (currentUser == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: const Text('My Bookings', style: TextStyle(color: Colors.white)),
            ),
            body: const Center(
              child: Text('Please login to view bookings'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              'My Bookings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  debugPrint('🔄 Manual refresh triggered');
                  setState(() {
                    _lastRefresh = DateTime.now();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                onPressed: () => _testFirebaseConnection(currentUser.uid),
              ),
            ],
          ),
          body: StreamBuilder<List<BookingModel>>(
            stream: FirebaseService.streamUserBookings(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              
              if (snapshot.hasError) {
                // Check if it's a permission error
                final errorStr = snapshot.error.toString().toLowerCase();
                final isPermissionError = errorStr.contains('permission') || 
                                        errorStr.contains('denied') ||
                                        errorStr.contains('unauthorized');
                
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPermissionError ? Icons.security : Icons.error_outline, 
                        size: 64, 
                        color: Colors.red
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPermissionError 
                          ? 'Permission Error\nTrying to reconnect...'
                          : 'Connection Error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild to retry
                            },
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _testFirebaseConnection(currentUser.uid),
                            child: const Text('Debug'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              
              final allBookings = snapshot.data ?? [];
              debugPrint('📋 All bookings: ${allBookings.length}');
              for (var booking in allBookings) {
                debugPrint('  - ${booking.service} | ${booking.status} | ID: ${booking.id} | Created: ${booking.createdAt}');
              }
              
              final upcomingBookings = _getUpcomingBookings(allBookings);
              final completedBookings = _getCompletedBookings(allBookings);
              final cancelledBookings = _getCancelledBookings(allBookings);
              
              debugPrint('📊 Upcoming: ${upcomingBookings.length}, Completed: ${completedBookings.length}, Cancelled: ${cancelledBookings.length}');
              
              // Credit coins for completed bookings
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _creditCoinsForCompletedBookings(allBookings);
              });
              
              return Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Upcoming (${upcomingBookings.length})'),
                      Tab(text: 'Completed (${completedBookings.length})'),
                      Tab(text: 'Cancelled (${cancelledBookings.length})'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingsList(upcomingBookings, 'upcoming'),
                        _buildBookingsList(completedBookings, 'completed'),
                        _buildBookingsList(cancelledBookings, 'cancelled'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.calendar_today_outlined
                  : type == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 80,
              color: AppColors.textGray,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming'
                  ? 'No upcoming bookings'
                  : type == 'completed'
                      ? 'No completed bookings'
                      : 'No cancelled bookings',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book a service to see it here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger a rebuild to refresh the stream
        setState(() {});
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, type);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, String type) {
    Color statusColor = AppColors.primary;
    String statusText = booking.status.toUpperCase();
    bool showActions = type == 'upcoming';

    switch (booking.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'PENDING';
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'CONFIRMED';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'ACCEPTED';
        break;
      case 'in_progress':
        statusColor = AppColors.primary;
        statusText = 'IN PROGRESS';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'COMPLETED';
        break;
      case 'cancelled':
        statusColor = AppColors.primary;
        statusText = 'CANCELLED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.service,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Booking ID
          Row(
            children: [
              const Icon(Icons.tag, size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                'ID: ${booking.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                booking.scheduledTime,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Address
          if (booking.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textGray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.address!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Technician info
          if (booking.technicianName != null) ...[
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.textGray),
                const SizedBox(width: 6),
                Text(
                  'Technician: ${booking.technicianName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Price & Payment Status
          Row(
            children: [
              const Icon(Icons.currency_rupee, size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                '₹${booking.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (booking.paymentStatus == 'paid')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (booking.paymentStatus == 'pay_later')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PAY ON SERVICE',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (booking.paymentStatus == 'pending')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Show coin savings if used
          if (booking.coinsUsed != null && booking.coinsUsed! > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.discount, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  '${booking.coinsUsed} coins used • Saved ₹${(booking.coinDiscount ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          
          // Notes
          if (booking.notes != null && booking.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.textGray),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Action buttons for upcoming bookings
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(booking);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showBookingDetails(booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // 📄 Restore: PDF option for completed bookings
          if (booking.status == 'completed') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewCertificatePDF(booking),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          ],
        ),
      );
  }

  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    try {
      await FirebaseService.updateBookingStatus(booking.id, 'cancelled');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload bookings by triggering stream refresh
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.bgMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildDetailRow('Service', booking.service),
              _buildDetailRow('Booking ID', booking.id.substring(0, 12).toUpperCase()),
              _buildDetailRow('Status', booking.status.toUpperCase()),
              _buildDetailRow('Date & Time', booking.scheduledTime),
              
              const Divider(height: 32),
              
              // Payment Breakdown
              const Text(
                'Payment Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildDetailRow('Service Charge', '₹${booking.serviceCharge.toStringAsFixed(2)}'),
              _buildDetailRow('Visiting Charge', '₹${booking.visitingCharge.toStringAsFixed(2)}'),
              
              if (booking.coinsUsed != null && booking.coinsUsed! > 0)
                _buildDetailRow(
                  'Coin Discount (${booking.coinsUsed} coins)',
                  '- ₹${(booking.coinDiscount ?? 0).toStringAsFixed(2)}',
                  valueColor: Colors.green,
                ),
              
              const Divider(height: 24),
              _buildDetailRow('Taxable Amount', '₹${booking.taxableAmount.toStringAsFixed(2)}'),
              _buildDetailRow('GST (18%)', '₹${booking.gstAmount.toStringAsFixed(2)}'),
              const Divider(height: 24),
              
              _buildDetailRow(
                'Total Amount',
                '₹${booking.totalAmount.toStringAsFixed(2)}',
                isBold: true,
              ),
              _buildDetailRow('Payment Status', _getPaymentStatusText(booking.paymentStatus)),
              
              const Divider(height: 32),
              
              if (booking.address != null)
                _buildDetailRow('Address', booking.address!),
              if (booking.technicianName != null)
                _buildDetailRow('Technician', booking.technicianName!),
              if (booking.notes != null)
                _buildDetailRow('Notes', booking.notes!),
              _buildDetailRow('Booked On', _formatDateTime(booking.createdAt)),
              
              const SizedBox(height: 24),
              
              if (booking.technicianName != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Call technician functionality
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text(
                      'Call Technician',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? AppColors.textDark,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPaymentStatusText(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'PAID';
      case 'pay_later':
        return 'PAY ON SERVICE';
      case 'pending':
        return 'PAYMENT PENDING';
      case 'payment_failed':
        return 'PAYMENT FAILED';
      default:
        return paymentStatus.toUpperCase();
    }
  }


  /// 📄 View job certificate
  Future<void> _viewCertificatePDF(BookingModel booking) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              const Text('Generating Certificate...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
      
      await PDFService.printJobCompletionCertificate(
        booking: booking,
        technicianName: booking.technicianName ?? 'Partner',
        completedJobsCount: 0, // Fallback
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      debugPrint('❌ Error viewing certificate: $e');
    }
  }

}
