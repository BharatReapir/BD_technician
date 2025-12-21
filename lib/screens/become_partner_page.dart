import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BecomePartnerPage extends StatefulWidget {
  const BecomePartnerPage({Key? key}) : super(key: key);

  @override
  State<BecomePartnerPage> createState() => _BecomePartnerPageState();
}

class _BecomePartnerPageState extends State<BecomePartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedService = 'AC Repair';
  bool _hasTools = false;
  bool _hasVehicle = false;
  bool _acceptTerms = false;

  final List<String> _services = [
    'AC Repair',
    'TV Repair',
    'Refrigerator',
    'Washing Machine',
    'Electrical',
    'Plumbing',
    'Painting',
    'Furniture',
    'Carpentry',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildHeroSection(),
            _buildBenefitsSection(),
            _buildApplicationForm(),
            _buildEarningsSection(),
            _buildRequirementsSection(),
            _buildFAQSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 32 : 40,
                height: isMobile ? 32 : 40,
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield, color: Colors.white, size: isMobile ? 20 : 24),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Bharat\nDoorstep',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: isMobile ? 24 : 28),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0D4A5A),
            Color(0xFF1A7B8E),
          ],
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a Partner\nTechnician',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Join India\'s fastest growing home services platform and earn up to ₹50,000/month with flexible hours',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard('500+', 'Active Partners', true),
                    _buildStatCard('₹1,600+', 'Avg. Daily Earning', true),
                    _buildStatCard('4.8★', 'Partner Rating', true),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why Partner With Us?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildBenefit('Earn 80% of every service charge'),
                      const SizedBox(height: 12),
                      _buildBenefit('Weekly direct bank settlements'),
                      const SizedBox(height: 12),
                      _buildBenefit('Work on your own schedule'),
                      const SizedBox(height: 12),
                      _buildBenefit('Jobs near your location'),
                      const SizedBox(height: 12),
                      _buildBenefit('Free training & certification'),
                      const SizedBox(height: 12),
                      _buildBenefit('Insurance coverage provided'),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Become a Partner\nTechnician',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Join India\'s fastest growing home services platform\nand earn up to ₹50,000/month with flexible hours',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          _buildStatCard('500+', 'Active Partners', false),
                          const SizedBox(width: 30),
                          _buildStatCard('₹1,600+', 'Avg. Daily Earning', false),
                          const SizedBox(width: 30),
                          _buildStatCard('4.8★', 'Partner Rating', false),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Why Partner With Us?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildBenefit('Earn 80% of every service charge'),
                        const SizedBox(height: 16),
                        _buildBenefit('Weekly direct bank settlements'),
                        const SizedBox(height: 16),
                        _buildBenefit('Work on your own schedule'),
                        const SizedBox(height: 16),
                        _buildBenefit('Jobs near your location'),
                        const SizedBox(height: 16),
                        _buildBenefit('Free training & certification'),
                        const SizedBox(height: 16),
                        _buildBenefit('Insurance coverage provided'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String value, String label, bool isMobile) {
    return Container(
      width: isMobile ? 110 : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Partner Benefits',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          isMobile
              ? Column(
                  children: [
                    _buildBenefitCard(
                      Icons.payments,
                      'High Earnings',
                      'Earn 80% commission on\nevery service',
                      const Color(0xFFE0F2E9),
                      isMobile,
                    ),
                    const SizedBox(height: 20),
                    _buildBenefitCard(
                      Icons.schedule,
                      'Flexible Hours',
                      'Work when you want,\nwhere you want',
                      const Color(0xFFE3F2FD),
                      isMobile,
                    ),
                    const SizedBox(height: 20),
                    _buildBenefitCard(
                      Icons.school,
                      'Free Training',
                      'Learn new skills and get\ncertified',
                      const Color(0xFFFFF3E0),
                      isMobile,
                    ),
                    const SizedBox(height: 20),
                    _buildBenefitCard(
                      Icons.support_agent,
                      '24/7 Support',
                      'Dedicated support team\nalways available',
                      const Color(0xFFF3E5F5),
                      isMobile,
                    ),
                  ],
                )
              : Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBenefitCard(
                      Icons.payments,
                      'High Earnings',
                      'Earn 80% commission on\nevery service',
                      const Color(0xFFE0F2E9),
                      isMobile,
                    ),
                    _buildBenefitCard(
                      Icons.schedule,
                      'Flexible Hours',
                      'Work when you want,\nwhere you want',
                      const Color(0xFFE3F2FD),
                      isMobile,
                    ),
                    _buildBenefitCard(
                      Icons.school,
                      'Free Training',
                      'Learn new skills and get\ncertified',
                      const Color(0xFFFFF3E0),
                      isMobile,
                    ),
                    _buildBenefitCard(
                      Icons.support_agent,
                      '24/7 Support',
                      'Dedicated support team\nalways available',
                      const Color(0xFFF3E5F5),
                      isMobile,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String description, Color bgColor, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 220,
      padding: EdgeInsets.all(isMobile ? 24 : 30),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: isMobile ? 40 : 50, color: AppColors.primary),
          SizedBox(height: isMobile ? 16 : 20),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 800),
          padding: EdgeInsets.all(isMobile ? 24 : 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply Now',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fill out the form below and we\'ll get back to you within 24 hours',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 30),
                
                if (isMobile) ...[
                  _buildFormField('Full Name *', _nameController, 'Enter your full name'),
                  const SizedBox(height: 20),
                  _buildFormField('Email Address *', _emailController, 'Enter your email', TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _buildFormField('Phone Number *', _phoneController, 'Enter your phone', TextInputType.phone),
                  const SizedBox(height: 20),
                  _buildFormField('City *', _cityController, 'Enter your city'),
                  const SizedBox(height: 20),
                  _buildDropdownField('Service Expertise *'),
                  const SizedBox(height: 20),
                  _buildFormField('Years of Experience *', _experienceController, 'Enter years', TextInputType.number),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildFormField('Full Name *', _nameController, 'Enter your full name')),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFormField('Email Address *', _emailController, 'Enter your email', TextInputType.emailAddress)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildFormField('Phone Number *', _phoneController, 'Enter your phone', TextInputType.phone)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFormField('City *', _cityController, 'Enter your city')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField('Service Expertise *')),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFormField('Years of Experience *', _experienceController, 'Enter years', TextInputType.number)),
                    ],
                  ),
                ],
                
                const SizedBox(height: 30),
                
                CheckboxListTile(
                  title: const Text('I have my own tools and equipment'),
                  value: _hasTools,
                  onChanged: (v) => setState(() => _hasTools = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('I have my own vehicle for transportation'),
                  value: _hasVehicle,
                  onChanged: (v) => setState(() => _hasVehicle = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('I agree to the Terms & Conditions and Privacy Policy'),
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v!),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (!_acceptTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please accept terms and conditions')),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Application submitted successfully!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Application', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, String hint, [TextInputType? keyboardType]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          keyboardType: keyboardType,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedService,
          decoration: _inputDecoration('Select service'),
          items: _services.map((service) {
            return DropdownMenuItem(value: service, child: Text(service));
          }).toList(),
          onChanged: (value) => setState(() => _selectedService = value!),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
    );
  }

  Widget _buildEarningsSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Earnings Calculator',
            style: TextStyle(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          isMobile
              ? Column(
                  children: [
                    _buildEarningCard('₹500', 'Average Service Price', false, isMobile),
                    const SizedBox(height: 16),
                    _buildEarningCard('80%', 'Your Commission', false, isMobile),
                    const SizedBox(height: 16),
                    _buildEarningCard('4-6', 'Jobs Per Day', false, isMobile),
                    const SizedBox(height: 16),
                    _buildEarningCard('₹1,600-2,400', 'Daily Earnings', true, isMobile),
                  ],
                )
              : Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildEarningCard('₹500', 'Average Service Price', false, isMobile),
                    const Icon(Icons.close, size: 40, color: Colors.grey),
                    _buildEarningCard('80%', 'Your Commission', false, isMobile),
                    const Icon(Icons.close, size: 40, color: Colors.grey),
                    _buildEarningCard('4-6', 'Jobs Per Day', false, isMobile),
                    const Icon(Icons.arrow_forward, size: 40, color: AppColors.primary),
                    _buildEarningCard('₹1,600-2,400', 'Daily Earnings', true, isMobile),
                  ],
                ),
          SizedBox(height: isMobile ? 30 : 40),
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 30),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Monthly Potential: ₹48,000 - ₹72,000',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Based on 25 working days per month',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(String value, String label, bool highlight, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 180,
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? AppColors.primary : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: highlight ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Text(
            'Requirements',
            style: TextStyle(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          isMobile
              ? Column(
                  children: [
                    _buildRequirementCard(Icons.verified_user, 'Valid ID Proof', 'Aadhaar, PAN, or\nDriving License', isMobile),
                    const SizedBox(height: 20),
                    _buildRequirementCard(Icons.phone_android, 'Smartphone', 'Android 6.0+\nor iOS 11+', isMobile),
                    const SizedBox(height: 20),
                    _buildRequirementCard(Icons.build, 'Basic Tools', 'Tools for your\nservice category', isMobile),
                    const SizedBox(height: 20),
                    _buildRequirementCard(Icons.school, 'Experience', 'Minimum 2 years\nin your field', isMobile),
                  ],
                )
              : Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildRequirementCard(Icons.verified_user, 'Valid ID Proof', 'Aadhaar, PAN, or\nDriving License', isMobile),
                    _buildRequirementCard(Icons.phone_android, 'Smartphone', 'Android 6.0+\nor iOS 11+', isMobile),
                    _buildRequirementCard(Icons.build, 'Basic Tools', 'Tools for your\nservice category', isMobile),
                    _buildRequirementCard(Icons.school, 'Experience', 'Minimum 2 years\nin your field', isMobile),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildRequirementCard(IconData icon, String title, String description, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 240,
      padding: EdgeInsets.all(isMobile ? 24 : 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: isMobile ? 40 : 50, color: AppColors.primary),
          SizedBox(height: isMobile ? 16 : 20),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          _buildFAQItem('How do I get paid?', 'Payments are transferred directly to your bank account every week.', isMobile),
          _buildFAQItem('What documents do I need?', 'Valid ID proof, address proof, and bank account details.', isMobile),
          _buildFAQItem('Can I choose my working hours?', 'Yes, you have complete flexibility to set your own schedule.', isMobile),
          _buildFAQItem('Is there any joining fee?', 'No, joining our platform is completely free.', isMobile),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            answer,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.all(isMobile ? 30 : 40),
      color: const Color(0xFF1A1F2E),
      child: Center(
        child: Text(
          '© 2025 Bharat Doorstep. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );
  }
}