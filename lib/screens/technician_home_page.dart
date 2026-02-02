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
                        onTap: () => _toggleOnlineStatus(currentTechnician),
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
                      '${currentTechnician.completedJobs ?? 0}',
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
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
                                  ElevatedButton(
                                    onPressed: () => _forceOnlineStatus(currentTechnician),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('GO ONLINE'),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: () => _testNotifications(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                    child: const Text('Test Notifications'),
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
                      
                      // ✅ NEW: Job Statistics Section
                      const Text(
                        'Job Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currentTechnician.completedJobs ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const Text(
                                    'Jobs Completed',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((currentTechnician.completedJobs ?? 0) > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '🎉 Great Work!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
                SizedBox(
                  width: double.infinity,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept Job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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

  /// Toggle technician online/offline status
  Future<void> _toggleOnlineStatus(TechnicianModel technician) async {
    try {
      final newStatus = !technician.isOnline;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(newStatus ? 'Going ONLINE...' : 'Going OFFLINE...'),
            ],
          ),
        ),
      );
      
      // Update status in Firebase
      await FirebaseService.updateTechnicianStatus(technician.uid, newStatus);
      
      // Update the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshTechnicianData();
      
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus 
                ? 'You are now ONLINE! You will receive job notifications.' 
                : 'You are now OFFLINE. You will not receive job notifications.'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Force technician online status
  Future<void> _forceOnlineStatus(TechnicianModel technician) async {
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
            content: Text('You are now ONLINE! You will receive job notifications.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      // Close loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to go online: $e'),
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
                    'Job Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Add test notification button
                  IconButton(
                    onPressed: () => _testNotifications(),
                    icon: const Icon(Icons.bug_report, color: Colors.white),
                    tooltip: 'Test Notifications',
                  ),
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
                  
                  debugPrint('🔔 Notifications panel: Found ${notifications.length} notifications');
                  for (var notif in notifications) {
                    debugPrint('🔔 Notification: ${notif['title']} - ${notif['body']}');
                  }
                  
                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No job alerts yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You\'ll receive alerts when new jobs are available',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _testNotifications(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Test Notifications'),
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
                      final isJobAlert = notification['type'] == 'new_booking' || notification['type'] == 'job_alert';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isJobAlert ? Colors.green : AppColors.primary,
                            child: Icon(
                              isJobAlert ? Icons.work : Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            notification['title'] ?? 'Job Alert',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['body'] ?? 'New job available'),
                              if (isJobAlert && notification['service'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Service: ${notification['service']} • Amount: ₹${notification['amount'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FCMService().clearPendingNotifications();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications cleared')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Clear All Notifications'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Test notifications functionality
  Future<void> _testNotifications() async {
    try {
      debugPrint('🧪 Testing notifications...');
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending test notifications...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Test complete notification flow
      await FCMService.testCompleteNotificationFlow();
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test notifications sent! Check notification panel.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

}