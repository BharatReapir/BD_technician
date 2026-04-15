import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../models/technician_model.dart';
import '../services/fcm_service.dart'; // 🔔 NEW: FCM Service
import 'technician_home_page.dart';

class TechnicianRegistrationPage extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const TechnicianRegistrationPage({
    Key? key,
    required this.uid,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<TechnicianRegistrationPage> createState() =>
      _TechnicianRegistrationPageState();
}

class _TechnicianRegistrationPageState
    extends State<TechnicianRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController(); // 🔑 NEW: Pincode field

  List<String> _selectedSpecializations = [];
  final List<String> _availableSpecializations = [
    'Plumber',
    'Electrician',
    'Carpenter',
    'AC Repair',
    'Painter',
    'Appliance Repair',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _cityController.addListener(_updateButtonState);
    _pincodeController.addListener(_updateButtonState); // 🔑 NEW: Pincode listener
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
           _emailController.text.trim().isNotEmpty &&
           _cityController.text.trim().isNotEmpty &&
           _pincodeController.text.trim().length == 6 && // 🔑 NEW: Pincode validation
           _selectedSpecializations.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _emailController.removeListener(_updateButtonState);
    _cityController.removeListener(_updateButtonState);
    _pincodeController.removeListener(_updateButtonState); // 🔑 NEW: Pincode dispose
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _pincodeController.dispose(); // 🔑 NEW: Pincode dispose
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one specialization')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 🔔 Initialize FCM service if not already done
      await FCMService.initialize();
      
      // 🔑 STEP 2: Create technician with pincode mapping
      final technician = TechnicianModel(
        uid: FirebaseAuth.instance.currentUser!.uid,
        name: _nameController.text.trim(),
        mobile: widget.phoneNumber, // 🔑 Use phone number from widget
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        primaryPincode: _pincodeController.text.trim(), // 🔑 NEW: Primary pincode
        fcmToken: await FCMService.getCurrentToken(), // 🔔 NEW: Get FCM token
        specializations: _selectedSpecializations,
        isOnline: true,
        totalJobs: 0,
        rating: 0.0,
        walletBalance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      debugPrint('🔧 Registering technician: ${technician.name}');
      debugPrint('📍 Pincode: ${technician.primaryPincode}');
      debugPrint('🔔 FCM Token: ${technician.fcmToken?.substring(0, 20)}...');
      
      await authProvider.saveTechnician(technician);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TechnicianHomePage()),
          (_) => false,
        );
      }

    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          // Top Navy Section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1E286D),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6D00),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Create Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your details to get started',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable Form Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('Full Name'),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Enter your name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildInputLabel('Email Address'),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildInputLabel('City'),
                          _buildTextField(
                            controller: _cityController,
                            hint: 'Enter your city',
                            icon: Icons.location_city_outlined,
                          ),
                          const SizedBox(height: 20),
                          
                          _buildInputLabel('Primary Pincode'),
                          _buildTextField(
                            controller: _pincodeController,
                            hint: 'Enter 6-digit pincode',
                            icon: Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Select Your Services',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E286D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableSpecializations.map((spec) {
                              final isSelected = _selectedSpecializations.contains(spec);
                              return FilterChip(
                                label: Text(spec),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSpecializations.add(spec);
                                    } else {
                                      _selectedSpecializations.remove(spec);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFF1E286D).withOpacity(0.2),
                                checkmarkColor: const Color(0xFF1E286D),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF1E286D) : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF1E286D) : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isFormValid ? _completeRegistration : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFormValid ? const Color(0xFF1E286D) : Colors.grey.shade300,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Complete Registration',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E286D),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          prefixIcon: Icon(icon, color: const Color(0xFF1E286D), size: 22),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
      ),
    );
  }
}