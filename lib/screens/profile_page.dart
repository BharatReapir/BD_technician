import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../screens/landing_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Guest User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard('12', 'Bookings', Icons.calendar_today),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('₹1,250', 'Wallet', Icons.account_balance_wallet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('5', 'Rewards', Icons.card_giftcard),
                  ),
                ],
              ),
            ),

            // Menu Items
            const SizedBox(height: 8),
            _buildMenuItem(
              Icons.person_outline,
              'Personal Information',
              'Update your details',
              () {},
            ),
            _buildMenuItem(
              Icons.location_on_outlined,
              'Saved Addresses',
              'Manage your addresses',
              () {},
            ),
            _buildMenuItem(
              Icons.receipt_outlined,
              'Order History',
              'View past bookings',
              () {},
            ),
            _buildMenuItem(
              Icons.credit_card,
              'Payment Methods',
              'Manage payment options',
              () {},
            ),
            _buildMenuItem(
              Icons.local_offer_outlined,
              'Offers & Coupons',
              'View available offers',
              () {},
            ),
            _buildMenuItem(
              Icons.people_outline,
              'Refer & Earn',
              'Invite friends and earn',
              () {},
            ),
            _buildMenuItem(
              Icons.settings_outlined,
              'Settings',
              'App preferences',
              () {},
            ),
            _buildMenuItem(
              Icons.help_outline,
              'Help & Support',
              'FAQs and contact us',
              () {},
            ),
            _buildMenuItem(
              Icons.info_outline,
              'About Us',
              'Know more about Bharat Doorstep',
              () {},
            ),
            _buildMenuItem(
              Icons.star_outline,
              'Rate Us',
              'Share your experience',
              () {},
            ),
            _buildMenuItem(
              Icons.logout,
              'Logout',
              'Sign out of your account',
              () async {
                await authProvider.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              },
              isLogout: true,
            ),
            const SizedBox(height: 20),
            
            // App Version
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.serviceBg1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.bgMedium, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLogout 
                    ? Colors.red.withOpacity(0.1) 
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLogout ? Colors.red : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }
}