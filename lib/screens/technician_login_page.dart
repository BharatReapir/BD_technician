import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'technician_otp_page.dart';

class TechnicianLoginPage extends StatefulWidget {
  const TechnicianLoginPage({Key? key}) : super(key: key);

  @override
  State<TechnicianLoginPage> createState() => _TechnicianLoginPageState();
}

class _TechnicianLoginPageState extends State<TechnicianLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ SET USER TYPE BEFORE SENDING OTP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userType', 'technician');
      debugPrint('🔧 User type set to: technician');

      // ✅ Use AuthProvider to send OTP and WAIT for it to complete
      final authProvider = context.read<AuthProvider>();
      debugPrint('📱 Sending OTP to: ${_phoneController.text}');
      
      await authProvider.sendOTP(_phoneController.text);
      debugPrint('✅ OTP sent successfully');

      // ✅ Only navigate AFTER OTP is sent successfully
      if (mounted) {
        debugPrint('🔄 Navigating to OTP page');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianOTPPage(
              phoneNumber: _phoneController.text,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
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
                        Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: const TextStyle(
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
                      child: Icon(_isLogin ? Icons.login : Icons.person_add, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TECHNICIAN APP BHARATAPP',
                      style: TextStyle(
                        color: Color(0xFFFF6D00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your mobile number to continue',
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
                    'Mobile Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E286D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E286D),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              setState(() {}); // to update button state
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter mobile number',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _phoneController.text.length == 10 && !_isLoading ? _sendOTP : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _phoneController.text.length == 10 ? const Color(0xFF1E286D) : Colors.grey.shade300,
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
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.send, size: 20),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          if (!_isLogin) {
                              _phoneFocusNode.requestFocus();
                          }
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                          children: [
                            TextSpan(
                              text: _isLogin ? 'Sign Up' : 'Login',
                              style: const TextStyle(
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