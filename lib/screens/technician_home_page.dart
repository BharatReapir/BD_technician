import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/booking_model.dart';
import '../models/technician_model.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart' as auth_provider;
import 'job_details_page.dart';
import 'technician_wallet_page.dart';

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({Key? key}) : super(key: key);

  @override
  State<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  bool _isOnline = true;
  TechnicianModel? _technician;
  List<BookingModel> _pendingBookings = [];
  List<BookingModel> _myBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTechnicianData();
  }

  Future<void> _loadTechnicianData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<auth_provider.AuthProvider>(context, listen: false);
      final currentTech = authProvider.technician;

      if (currentTech == null) {
        debugPrint('❌ No technician logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      debugPrint('📥 Loading data for technician: ${currentTech.uid}');

      // Get technician details
      final techData = await FirebaseService.getTechnician(currentTech.uid);
      
      // Get pending bookings for this technician's city and specializations
      final pendingBookings = await FirebaseService.getPendingBookingsForTechnician(
        city: currentTech.city,
        specializations: currentTech.specializations,
      );

      // Get technician's accepted bookings
      final myBookings = await FirebaseService.getTechnicianBookings(currentTech.uid);

      setState(() {
        _technician = techData ?? currentTech;
        _isOnline = _technician?.isOnline ?? true;
        _pendingBookings = pendingBookings;
        _myBookings = myBookings.where((b) => 
          b.status == 'accepted' || b.status == 'in_progress'
        ).toList();
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_pendingBookings.length} pending bookings');
      debugPrint('✅ Loaded ${_myBookings.length} accepted bookings');
    } catch (e) {
      debugPrint('❌ Error loading technician data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_technician == null) return;

    try {
      final newStatus = !_isOnline;
      await FirebaseService.updateTechnicianStatus(_technician!.uid, newStatus);
      
      setState(() {
        _isOnline = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'You are now online' : 'You are now offline'),
          backgroundColor: newStatus ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error toggling status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptBooking(BookingModel booking) async {
    if (_technician == null) return;

    // Check wallet balance
    if (_technician!.walletBalance < 200) {
      _showLowBalanceDialog();
      return;
    }

    try {
      debugPrint('✅ Accepting booking: ${booking.id}');

      // Deduct ₹200 from wallet
      final newBalance = _technician!.walletBalance - 200;
      
      // Update technician's wallet
      await FirebaseService.updateTechnicianWallet(_technician!.uid, newBalance);

      // Assign booking to technician
      await FirebaseService.assignTechnicianToBooking(
        booking.id,
        _technician!.uid,
        _technician!.name,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking accepted! ₹200 deducted from wallet'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
      await _loadTechnicianData();
    } catch (e) {
      debugPrint('❌ Error accepting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLowBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Wallet Balance'),
        content: const Text(
          'Your wallet balance is insufficient. You need ₹200 to accept a booking. Please recharge your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TechnicianWalletPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Recharge Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_technician?.name ?? "Technician"}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ready to work?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      // Online/Offline Toggle
                      GestureDetector(
                        onTap: _toggleOnlineStatus,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isOnline ? AppColors.primary : Colors.grey[600],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _isOnline ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '₹${_technician?.monthlyEarnings.toStringAsFixed(0) ?? "0"}',
                          'This Month',
                          Icons.currency_rupee,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '${_technician?.totalJobs ?? 0}',
                          'Jobs Done',
                          Icons.work,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '${_technician?.rating.toStringAsFixed(1) ?? "0.0"}',
                          'Rating',
                          Icons.star,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Wallet Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TechnicianWalletPage(),
                        ),
                      ).then((_) => _loadTechnicianData());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.white),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Wallet Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '₹${_technician?.walletBalance.toStringAsFixed(0) ?? "0"}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Recharge',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Jobs List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTechnicianData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Requests Section
                      if (_pendingBookings.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Requests (${_pendingBookings.length})',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '₹200 per acceptance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ..._pendingBookings.map((booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildJobCard(
                            booking: booking,
                            isNew: true,
                          ),
                        )).toList(),
                        
                        const SizedBox(height: 24),
                      ],
                      
                      // My Bookings Section
                      if (_myBookings.isNotEmpty) ...[
                        Text(
                          'My Bookings (${_myBookings.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ..._myBookings.map((booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildJobCard(
                            booking: booking,
                            isNew: false,
                          ),
                        )).toList(),
                      ],
                      
                      // Empty state
                      if (_pendingBookings.isEmpty && _myBookings.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.work_outline,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No jobs available',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'New jobs will appear here',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    required BookingModel booking,
    required bool isNew,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew ? AppColors.primary : Colors.grey[300]!,
          width: isNew ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNew)
            Row(
              children: const [
                Icon(Icons.notifications, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'New Job Request!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          if (isNew) const SizedBox(height: 16),
          
          _buildJobDetailRow('Customer:', booking.userName),
          const SizedBox(height: 12),
          _buildJobDetailRow('Service:', booking.service),
          const SizedBox(height: 12),
          _buildJobDetailRow('Time:', booking.scheduledTime),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earnings:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '₹${booking.earnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (isNew)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // Reject booking
                      await FirebaseService.updateBookingStatus(booking.id, 'cancelled');
                      await _loadTechnicianData();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptBooking(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept (₹200)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          if (!isNew)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailsPage(
                      booking: booking, customer: '', service: '', earnings: '', time: '',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Details'),
            ),
        ],
      ),
    );
  }

  Widget _buildJobDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}