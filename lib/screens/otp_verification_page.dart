import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'home/home_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String name;
  final String mobileNumber;
  final String email;
  final String city;
  final String? referralCode;
  
  const OTPVerificationPage({
    Key? key,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.city,
    this.referralCode,
  }) : super(key: key);

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _loginMobileController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendTimer = 59;
  bool _isVerifying = false;
  bool _isLoading = false;
  bool _showOTPScreen = false;
  String _currentMobileNumber = '';

  bool get _isLoginMode => widget.name.isEmpty && widget.mobileNumber.isEmpty;

  @override
  void initState() {
    super.initState();
    if (!_isLoginMode) {
      _showOTPScreen = true;
      _currentMobileNumber = widget.mobileNumber;
      _startTimer();
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_resendTimer > 0 && mounted) {
        setState(() {
          _resendTimer--;
        });
        _startTimer();
      }
    });
  }

  Future<void> _sendOTP() async {
    if (_loginMobileController.text.isEmpty || _loginMobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Add actual OTP sending API call here
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _showOTPScreen = true;
      _currentMobileNumber = _loginMobileController.text;
      _resendTimer = 59;
    });
    
    _startTimer();
  }

  Future<void> _verifyOTP() async {
    String otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // TODO: Add actual OTP verification API call here
    await Future.delayed(const Duration(seconds: 1));

    // Create user model
    final user = UserModel(
      name: _isLoginMode ? 'User' : widget.name,
      phone: _isLoginMode ? _currentMobileNumber : widget.mobileNumber,
      email: _isLoginMode ? '' : widget.email,
      city: _isLoginMode ? '' : widget.city,
      referralCode: _isLoginMode ? null : widget.referralCode,
    );

    // Save user using provider
    await Provider.of<AuthProvider>(context, listen: false).saveUser(user);

    setState(() => _isVerifying = false);

    // Navigate to home
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoginMode ? (_showOTPScreen ? 'OTP Verification' : 'Login') : 'OTP Verification',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoginMode && !_showOTPScreen ? _buildLoginScreen() : _buildOTPScreen(),
    );
  }

  Widget _buildLoginScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your mobile number to continue',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 40),
          
          const Text(
            'Mobile Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _loginMobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              hintText: 'Enter 10-digit mobile number',
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textGray),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              counterText: '',
            ),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const Spacer(),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Don\'t have an account? ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOTPScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a 6-digit OTP to $_currentMobileNumber',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 40),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 50,
                height: 60,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.bgMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          
          Center(
            child: _resendTimer > 0
                ? Text(
                    'Resend OTP in ${_resendTimer}s',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  )
                : TextButton(
                    onPressed: () {
                      setState(() => _resendTimer = 59);
                      _startTimer();
                    },
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Verify & Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: TextButton(
              onPressed: () {
                if (_isLoginMode && _showOTPScreen) {
                  setState(() {
                    _showOTPScreen = false;
                    for (var controller in _otpControllers) {
                      controller.clear();
                    }
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Change Number',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loginMobileController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}