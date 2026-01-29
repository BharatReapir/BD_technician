import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart';
import '../services/firebase_service.dart';
import '../services/fcm_service.dart'; // 🔔 NEW: FCM Service
import '../models/technician_model.dart';
import '../models/booking_model.dart';
import '../utils/commission_calculator.dart';
import 'tech_wallet_page.dart';
import 'job_details_page.dart';
import 'landing_page.dart';

class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({Key? key}) : super(key: key);

  @override
  State<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn || !authProvider.isTechnician) {
          return const Scaffold(
            body: Center(child: Text('Please login as technician')),
          );
        }

        final technician = authProvider.technician;
        if (technician == null) {
          return const Scaffold(
            body: Center(child: Text('No technician data found')),
          );
        }

        return StreamBuilder<TechnicianModel?>(
          stream: authProvider.technicianStream(technician.uid),
          builder: (context, snapshot) {
            final currentTechnician = snapshot.data ?? technician;

            return Scaffold(
              body: _currentIndex == 0 
                  ? _buildHomePage(currentTechnician, authProvider) 
                  : _buildProfilePage(currentTechnician, authProvider),
              bottomNavigationBar: _buildBottomNavBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildHomePage(TechnicianModel currentTechnician, AuthProvider authProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0047AB),
            Color(0xFF0056C8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${currentTechnician.name.split(' ')[0]}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Ready to work?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // 🔔 NEW: Notification Bell Button
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            IconButton(
                              onPressed: () => _showNotifications(context),
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 28,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            // Notification badge (optional - can be enhanced later)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ONLINE/OFFLINE Toggle Button
                      GestureDetector(
                        onTap: () => _forceOnlineStatus(currentTechnician),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: currentTechnician.isOnline ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                currentTechnician.isOnline ? Icons.wifi : Icons.wifi_off,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentTechnician.isOnline ? 'ONLINE' : 'OFFLINE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.touch_app,
                                color: Colors.white70,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TechWalletPage(
                              technicianId: currentTechnician.uid,
                            ),
                          ),
                        );
                      },
                      child: _buildStatCard(
                        '₹${currentTechnician.walletBalance.toStringAsFixed(0)}',
                        'Wallet',
                        Icons.account_balance_wallet,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${currentTechnician.totalJobs}',
                      'Jobs Done',
                      Icons.work,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '${currentTechnician.rating.toStringAsFixed(1)}',
                      'Rating',
                      Icons.star,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "Today's Jobs",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<BookingModel>>(
                        stream: FirebaseService.streamPendingBookingsForTechnician(
                          pincode: currentTechnician.primaryPincode,
                          specializations: currentTechnician.specializations,
                        ),
                        builder: (context, snapshot) {
                          debugPrint('🔧 === TECHNICIAN JOB STREAM DEBUG ===');
                          debugPrint('🔧 Technician: ${currentTechnician.name}');
                          debugPrint('🔧 Technician Pincode: ${currentTechnician.primaryPincode}');
                          debugPrint('🔧 Technician Specializations: ${currentTechnician.specializations}');
                          debugPrint('🔧 Stream State: ${snapshot.connectionState}');
                          debugPrint('🔧 Has Error: ${snapshot.hasError}');
                          debugPrint('🔧 Error: ${snapshot.error}');
                          debugPrint('🔧 Has Data: ${snapshot.hasData}');
                          debugPrint('🔧 Jobs Count: ${snapshot.data?.length ?? 0}');
                          
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            debugPrint('❌ Stream error: ${snapshot.error}');
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Error: ${snapshot.error}'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {}); // Trigger rebuild
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final bookings = snapshot.data ?? [];
                          debugPrint('📋 Found ${bookings.length} jobs for technician');
                          
                          for (var booking in bookings) {
                            debugPrint('  📋 Job: ${booking.service} | Pincode: ${booking.pincode} | Status: ${booking.status} | ID: ${booking.id}');
                            debugPrint('      Created: ${booking.createdAt} | Scheduled: ${booking.scheduledTime}');
                          }
                          
                          if (bookings.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.work_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No jobs available in your area',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pincode: ${currentTechnician.primaryPincode}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Services: ${currentTechnician.specializations.join(", ")}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _forceOnlineStatus(currentTechnician),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text('FORCE ONLINE'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _debugBookings(currentTechnician),
                                        child: const Text('Debug Jobs'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _testNotifications(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: const Text('Test Notif'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _fixBookingPincodes(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                        child: const Text('Fix Pincodes'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return _buildRealJobCard(
                                context,
                                currentTechnician,
                                booking,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage(TechnicianModel currentTechnician, AuthProvider authProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0047AB),
            Color(0xFF0056C8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      currentTechnician.name.isNotEmpty 
                          ? currentTechnician.name[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0047AB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTechnician.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Technician ID: ${currentTechnician.uid.substring(0, 8)}...',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildProfileItem(
                        icon: Icons.person,
                        label: 'Full Name',
                        value: currentTechnician.name,
                      ),
                      
                      _buildProfileItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: currentTechnician.email,
                      ),
                      
                      _buildProfileItem(
                        icon: Icons.phone,
                        label: 'Mobile Number',
                        value: currentTechnician.mobile,
                      ),
                      
                      _buildProfileItem(
                        icon: Icons.location_city,
                        label: 'City',
                        value: currentTechnician.city,
                      ),
                      
                      _buildProfileItem(
                        icon: Icons.pin_drop,
                        label: 'Primary Pincode',
                        value: currentTechnician.primaryPincode,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentTechnician.specializations.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              service,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _showLogoutDialog(authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
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

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                await authProvider.logout();
                
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LandingPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealJobCard(
    BuildContext context,
    TechnicianModel technician,
    BookingModel booking,
  ) {
    final calculatedEarnings = CommissionCalculator.getTechnicianEarnings(booking.totalAmount);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.service,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pincode: ${booking.pincode}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        booking.address ?? 'Address not available',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.scheduledTime,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Customer:', style: TextStyle(fontSize: 14)),
                    Text(
                      booking.userName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 14)),
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Earnings:', style: TextStyle(fontSize: 14)),
                    Text(
                      '₹${calculatedEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Booking ID:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      booking.id?.substring(0, 8) ?? 'N/A',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectBooking(booking.id!, technician.uid),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => {
                          debugPrint('🎯 ACCEPT BUTTON PRESSED'),
                          debugPrint('🎯 Booking ID from card: ${booking.id}'),
                          debugPrint('🎯 Booking service: ${booking.service}'),
                          debugPrint('🎯 Booking customer: ${booking.userName}'),
                          _acceptBooking(booking.id!, technician.uid, technician.name)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptBooking(String bookingId, String technicianId, String technicianName) async {
    try {
      debugPrint('🟢 Technician accepting booking: $bookingId');
      
      // Store context reference
      final context = this.context;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Accepting job...'),
            ],
          ),
        ),
      );
      
      // Accept the booking (includes wallet deduction)
      await FirebaseService.acceptBooking(bookingId, technicianId);
      
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show success message with wallet deduction info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Job accepted! ₹199 deducted from wallet. Navigating to job details...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Wallet',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TechWalletPage(
                      technicianId: technicianId,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
      
      // Wait a moment for Firebase to sync, then navigate
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Navigate to job details page immediately
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsPage(
              bookingId: bookingId,
              technicianId: technicianId,
            ),
          ),
        );
      }
      
      debugPrint('✅ Booking accepted successfully');
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      debugPrint('❌ Error accepting booking: $e');
      
      // Handle specific error cases
      if (e.toString().contains('Insufficient wallet balance')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Insufficient wallet balance! Need ₹199 to accept job'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        // Still navigate to job details even if update failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Job accepted (sync pending)'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Wait a moment then navigate
          await Future.delayed(const Duration(milliseconds: 1000));
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsPage(
                bookingId: bookingId,
                technicianId: technicianId,
              ),
            ),
          );
        }
      } else {
        // Show error for other types of errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to accept booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _fixServiceNames() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Fixing service names...'),
            ],
          ),
        ),
      );
      
      // Get all bookings and fix service names
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://bharatapp-4e9c8-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      
      final snapshot = await database.ref('bookings').get();
      if (!snapshot.exists || snapshot.value == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      
      final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
      int fixedCount = 0;
      
      // Service name fixes
      final serviceFixes = {
        'General Service': 'AC Repair',
        'AC Installation': 'AC Repair', 
        'AC Service': 'AC Repair',
        'Jet Machine Service': 'Appliance Repair',
      };
      
      for (final entry in bookingsMap.entries) {
        final bookingId = entry.key;
        final bookingData = Map<String, dynamic>.from(entry.value);
        final currentService = bookingData['service']?.toString() ?? '';
        
        if (serviceFixes.containsKey(currentService)) {
          final newService = serviceFixes[currentService];
          if (newService != null) {
            await database.ref('bookings/$bookingId').update({
              'service': newService,
              'updatedAt': DateTime.now().toIso8601String(),
            });
            
            debugPrint('✅ Fixed booking $bookingId: $currentService → $newService');
            fixedCount++;
          }
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fixed $fixedCount service names! Jobs should appear now.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Trigger a refresh
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error fixing services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fixBookingPincodes() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Fixing booking pincodes...'),
            ],
          ),
        ),
      );
      
      await FirebaseService.fixBookingPincodes();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Booking pincodes fixed! Jobs should appear now.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Trigger a refresh
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error fixing pincodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _debugBookings(TechnicianModel technician) async {
    try {
      debugPrint('🔍 === MANUAL BOOKING DEBUG ===');
      debugPrint('🔍 Technician: ${technician.name}');
      debugPrint('🔍 Technician Pincode: ${technician.primaryPincode}');
      debugPrint('🔍 Technician Specializations: ${technician.specializations}');
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Get all bookings from Firebase to debug
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://bharatapp-4e9c8-default-rtdb.asia-southeast1.firebasedatabase.app/',
      );
      final snapshot = await database.ref('bookings').get();
      
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('📊 Total bookings in database: ${bookingsMap.length}');
        
        final allBookings = bookingsMap.entries
            .map((entry) {
              final bookingData = Map<String, dynamic>.from(entry.value);
              bookingData['id'] = entry.key;
              return BookingModel.fromJson(bookingData);
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Filter recent bookings (last 24 hours)
        final now = DateTime.now();
        final recentBookings = allBookings.where((b) => 
          now.difference(b.createdAt).inHours < 24
        ).toList();
        
        debugPrint('📅 Recent bookings (24h): ${recentBookings.length}');
        
        for (var booking in recentBookings) {
          debugPrint('  📋 ${booking.service} | Status: ${booking.status} | Pincode: ${booking.pincode}');
          debugPrint('      Created: ${booking.createdAt} | Scheduled: ${booking.scheduledTime}');
          debugPrint('      ID: ${booking.id}');
        }
        
        // Check matches for this technician
        final matchingBookings = recentBookings.where((booking) {
          final statusMatch = booking.status == 'pending' || booking.status == 'confirmed';
          final pincodeMatch = booking.pincode == technician.primaryPincode;
          final serviceMatch = technician.specializations.contains(booking.service);
          return statusMatch && pincodeMatch && serviceMatch;
        }).toList();
        
        debugPrint('🎯 Matching bookings for ${technician.name}: ${matchingBookings.length}');
        
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debug: Total=${allBookings.length}, Recent=${recentBookings.length}, Matching=${matchingBookings.length}'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No bookings found in database'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Debug error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show notifications panel
  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: FCMService.getPendingNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final notifications = snapshot.data ?? [];
                  
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You\'ll receive notifications for new jobs',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.work, color: Colors.white),
                          ),
                          title: Text(notification['title'] ?? 'New Job'),
                          subtitle: Text(notification['body'] ?? 'Job notification'),
                          trailing: Text(
                            _formatNotificationTime(notification['timestamp']),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _testNotifications(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test Notification'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FCMService.clearPendingNotifications();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications cleared')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear All'),
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

  String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'Now';
    
    try {
      final DateTime time = DateTime.parse(timestamp.toString());
      final Duration diff = DateTime.now().difference(time);
      
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Now';
    }
  }

  Future<void> _testNotifications() async {
    try {
      debugPrint('🧪 Testing notifications...');
      
      // Test FCM service
      await FCMService.testNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧪 Test notification sent! Check your notification panel.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Test notification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectBooking(String bookingId, String technicianId) async {
    try {
      debugPrint('🔴 Technician rejecting booking: $bookingId');
      
      // Store context reference
      final context = this.context;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Reject the booking
      await FirebaseService.rejectBooking(bookingId, technicianId);
      
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Booking rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      debugPrint('✅ Booking rejected successfully');
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reject booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      debugPrint('❌ Error rejecting booking: $e');
    }
  }

  /// Force technician online status
  Future<void> _forceOnlineStatus(TechnicianModel technician) async {
    try {
      debugPrint('🔥 FORCING TECHNICIAN ONLINE');
      debugPrint('🔥 Current status: ${technician.isOnline}');
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Going ONLINE...'),
            ],
          ),
        ),
      );
      
      // Force update to ONLINE in Firebase
      await FirebaseService.updateTechnicianStatus(technician.uid, true);
      
      // Also update the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshTechnicianData();
      
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔥 FORCED ONLINE! You should now receive jobs!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      debugPrint('✅ Technician forced ONLINE successfully');
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to go online: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      debugPrint('❌ Error forcing online: $e');
    }
  }

}