import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../models/technician_model.dart';
import 'technician_registration_page.dart';
import 'technician_home_page.dart';

class TechnicianOTPPage extends StatefulWidget {
  final String phoneNumber;

  const TechnicianOTPPage({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<TechnicianOTPPage> createState() => _TechnicianOTPPageState();
}

class _TechnicianOTPPageState extends State<TechnicianOTPPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var controller in _otpControllers) {
      controller.addListener(_updateButtonState);
    }
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isOTPComplete {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.removeListener(_updateButtonState);
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getOTP() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOTP() async {
    String otp = _getOTP();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // 1. ✅ Verify OTP using AuthProvider
      debugPrint('🔐 Verifying OTP: $otp');
      debugPrint('📱 Phone number: ${widget.phoneNumber}');
      
      // Check user type before verification
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType') ?? 'user';
      debugPrint('👤 Current user type: $userType');
      
      final userCredential = await authProvider.verifyOTP(otp);
      final uid = userCredential.user!.uid;
      debugPrint('✅ OTP Verified for UID: $uid');

      // 2. ✅ CONFIRM USER TYPE
      await prefs.setString('userType', 'technician');
      debugPrint('🔧 User type confirmed: technician');

      // 3. ✅ Check if technician profile exists in Realtime Database
      debugPrint('🔍 Checking technician profile in Realtime DB...');
      TechnicianModel? technician = await authProvider.getTechnicianData(uid);

      if (technician != null) {
        // ✅ EXISTING TECHNICIAN - Profile found
        debugPrint('✅ Technician found: ${technician.name}');
        debugPrint('📧 Email: ${technician.email}');
        debugPrint('🏙️ City: ${technician.city}');
        debugPrint('📍 Pincode: ${technician.primaryPincode}');
        debugPrint('🔧 Specializations: ${technician.specializations}');
        debugPrint('💰 Wallet Balance: ₹${technician.walletBalance}');
        debugPrint('🟢 Online Status: ${technician.isOnline}');
        
        // Save technician data to AuthProvider
        await authProvider.saveTechnician(technician);
        debugPrint('💾 Technician saved to AuthProvider');
        
        // Navigate to technician home
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const TechnicianHomePage(),
            ),
            (route) => false,
          );
        }
      } else {
        // ⚠️ NEW TECHNICIAN - Profile not found, navigate to registration
        debugPrint('⚠️ New technician detected - no profile found in Realtime DB');
        debugPrint('📝 Redirecting to registration page...');
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TechnicianRegistrationPage(
                uid: uid,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ OTP Verification Error: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      
      String errorMessage = 'Verification failed';
      if (e.toString().contains('Please request OTP first')) {
        errorMessage = 'Session expired. Please request OTP again.';
        // Go back to login page
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (e.toString().contains('invalid-verification-code')) {
        errorMessage = 'Invalid OTP. Please check and try again.';
      } else if (e.toString().contains('session-expired')) {
        errorMessage = 'OTP expired. Please request a new one.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 Resending OTP to: ${widget.phoneNumber}');
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendOTP(widget.phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear existing OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
      }
    } catch (e) {
      debugPrint('❌ Error resending OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending OTP: $e'),
            backgroundColor: Colors.red,
          ),
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
      backgroundColor: const Color(0xFFF5F6FA), // Light background for the bottom part
      body: Column(
        children: [
          // Top Navy Section
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1E286D), // Navy Blue
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
                          'Verification',
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
                        color: const Color(0xFFFF6D00), // Orange
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.message, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the code sent to +91 ${widget.phoneNumber}',
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
          // Bottom Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'One Time Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E286D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => Container(
                        width: 45,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E286D),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.length == 1 && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isOTPComplete) ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOTPComplete ? const Color(0xFF1E286D) : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Verify OTP',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_circle_outline, size: 20),
                            ],
                          ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _resendOTP,
                      child: RichText(
                        text: const TextSpan(
                          text: "Didn't receive code? ",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                          children: [
                            TextSpan(
                              text: 'Resend',
                              style: TextStyle(
                                color: Color(0xFFFF6D00),
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}