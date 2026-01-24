import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/booking_model.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart' as auth_provider;
import '../providers/coin_provider.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('👤 Current user ID: ${currentUser.uid}');
      debugPrint('📥 Loading bookings for user: ${currentUser.uid}');
      
      // Get bookings from Firebase
      final bookings = await FirebaseService.getUserBookings(currentUser.uid);
      
      debugPrint('✅ Loaded ${bookings.length} bookings');
      for (var booking in bookings) {
        debugPrint('  - ${booking.service} | ${booking.status} | ${booking.scheduledTime}');
      }
      
      setState(() {
        _allBookings = bookings;
        _isLoading = false;
      });

      // Credit coins for completed bookings
      await _creditCoinsForCompletedBookings();
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading bookings: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookings: $e'),
            backgroundColor: AppColors.primary,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadBookings,
            ),
          ),
        );
      }
    }
  }

  Future<void> _creditCoinsForCompletedBookings() async {
    if (!mounted) return;

    try {
      final coinProvider = context.read<CoinProvider>();

      for (final booking in _allBookings) {
        if (booking.status == 'completed') {
          final coins = _calculateCoins(booking.totalAmount);

          debugPrint('💰 Attempting to credit $coins coins for booking ${booking.id}');

          await coinProvider.creditCoins(
            bookingId: booking.id,
            coins: coins,
            bookingNumber: 1, // You can track this separately if needed
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error crediting coins: $e');
    }
  }

  int _calculateCoins(double amount) {
    if (amount >= 900) return 50;
    if (amount >= 700) return 40;
    if (amount >= 500) return 30;
    if (amount >= 300) return 20;
    return 10;
  }

  List<BookingModel> _getUpcomingBookings() {
    return _allBookings
        .where((b) => b.status == 'pending' || b.status == 'accepted' || b.status == 'in_progress')
        .toList();
  }

  List<BookingModel> _getCompletedBookings() {
    return _allBookings.where((b) => b.status == 'completed').toList();
  }

  List<BookingModel> _getCancelledBookings() {
    return _allBookings.where((b) => b.status == 'cancelled').toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Upcoming (${_getUpcomingBookings().length})'),
            Tab(text: 'Completed (${_getCompletedBookings().length})'),
            Tab(text: 'Cancelled (${_getCancelledBookings().length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_getUpcomingBookings(), 'upcoming'),
                _buildBookingsList(_getCompletedBookings(), 'completed'),
                _buildBookingsList(_getCancelledBookings(), 'cancelled'),
              ],
            ),
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
      onRefresh: _loadBookings,
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
      debugPrint('❌ Cancelling booking: ${booking.id}');
      await FirebaseService.updateBookingStatus(booking.id, 'cancelled');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload bookings
      await _loadBookings();
    } catch (e) {
      debugPrint('❌ Error cancelling booking: $e');
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
}