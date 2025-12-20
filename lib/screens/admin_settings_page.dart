import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _autoAssignment = true;
  bool _maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage application settings and preferences',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Settings Sections
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // Two column layout for wide screens
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildGeneralSettings(),
                          const SizedBox(height: 24),
                          _buildNotificationSettings(),
                          const SizedBox(height: 24),
                          _buildSystemSettings(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Right Column
                    Expanded(
                      child: Column(
                        children: [
                          _buildCompanyInfo(),
                          const SizedBox(height: 24),
                          _buildPaymentSettings(),
                          const SizedBox(height: 24),
                          _buildDangerZone(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Single column layout for narrow screens
                return Column(
                  children: [
                    _buildGeneralSettings(),
                    const SizedBox(height: 24),
                    _buildCompanyInfo(),
                    const SizedBox(height: 24),
                    _buildNotificationSettings(),
                    const SizedBox(height: 24),
                    _buildPaymentSettings(),
                    const SizedBox(height: 24),
                    _buildSystemSettings(),
                    const SizedBox(height: 24),
                    _buildDangerZone(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'General Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField('Application Name', 'Bharat Doorstep'),
          const SizedBox(height: 14),
          _buildTextField('Support Email', 'support@bharatdoorstep.com'),
          const SizedBox(height: 14),
          _buildTextField('Support Phone', '+91 1800 123 4567'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved successfully'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            'Email Notifications',
            'Receive email notifications',
            _emailNotifications,
            (value) => setState(() => _emailNotifications = value),
          ),
          const Divider(height: 28),
          _buildSwitchTile(
            'SMS Notifications',
            'Send SMS alerts',
            _smsNotifications,
            (value) => setState(() => _smsNotifications = value),
          ),
          const Divider(height: 28),
          _buildSwitchTile(
            'Push Notifications',
            'Enable push notifications',
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'System Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            'Auto-Assign Technicians',
            'Automatically assign bookings',
            _autoAssignment,
            (value) => setState(() => _autoAssignment = value),
          ),
          const Divider(height: 28),
          _buildSwitchTile(
            'Maintenance Mode',
            'Put app in maintenance mode',
            _maintenanceMode,
            (value) => setState(() => _maintenanceMode = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Company Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField('Company Name', 'Bharat Doorstep Pvt Ltd'),
          const SizedBox(height: 14),
          _buildTextField('GST Number', '29AAAAA0000A1Z5'),
          const SizedBox(height: 14),
          _buildTextField('Address', 'Mumbai, Maharashtra, India', maxLines: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Information'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Payment Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Razorpay Key', '••••••••••••5678'),
          const Divider(height: 20),
          _buildInfoRow('UPI ID', 'bharat@upi'),
          const Divider(height: 20),
          _buildInfoRow('Bank Account', 'XXXX XXXX 1234'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Payment Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 22),
              SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'These actions are irreversible. Please be careful.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear All Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, {int maxLines = 1}) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}