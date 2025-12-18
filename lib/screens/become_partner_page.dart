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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bharat\nDoorstep',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
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
      child: Row(
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
                    _buildStatCard('500+', 'Active Partners'),
                    const SizedBox(width: 30),
                    _buildStatCard('₹1,600+', 'Avg. Daily Earning'),
                    const SizedBox(width: 30),
                    _buildStatCard('4.8★', 'Partner Rating'),
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

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Partner Benefits',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBenefitCard(
                Icons.payments,
                'High Earnings',
                'Earn 80% commission on\nevery service',
                const Color(0xFFE0F2E9),
              ),
              const SizedBox(width: 40),
              _buildBenefitCard(
                Icons.schedule,
                'Flexible Hours',
                'Work when you want,\nwhere you want',
                const Color(0xFFE3F2FD),
              ),
              const SizedBox(width: 40),
              _buildBenefitCard(
                Icons.school,
                'Free Training',
                'Learn new skills and get\ncertified',
                const Color(0xFFFFF3E0),
              ),
              const SizedBox(width: 40),
              _buildBenefitCard(
                Icons.support_agent,
                '24/7 Support',
                'Dedicated support team\nalways available',
                const Color(0xFFF3E5F5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String description, Color bgColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 50, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(40),
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
                const Text(
                  'Apply Now',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
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
                const SizedBox(height: 40),
                
                // Name & Email Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('Enter your full name'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email Address *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration('Enter your email'),
                            validator: (v) => v!.isEmpty || !v.contains('@') ? 'Valid email required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Phone & City Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            decoration: _inputDecoration('Enter your phone'),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty || v.length < 10 ? 'Valid phone required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('City *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cityController,
                            decoration: _inputDecoration('Enter your city'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Service & Experience Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Service Expertise *', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Years of Experience *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _experienceController,
                            decoration: _inputDecoration('Enter years'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Checkboxes
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
                
                // Submit Button
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Earnings Calculator',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEarningCard('₹500', 'Average Service Price'),
              const Icon(Icons.close, size: 40, color: Colors.grey),
              _buildEarningCard('80%', 'Your Commission'),
              const Icon(Icons.close, size: 40, color: Colors.grey),
              _buildEarningCard('4-6', 'Jobs Per Day'),
              const Icon(Icons.arrow_forward, size: 40, color: AppColors.primary),
              _buildEarningCard('₹1,600-2,400', 'Daily Earnings', highlight: true),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  'Monthly Potential: ₹48,000 - ₹72,000',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 10),
                Text(
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

  Widget _buildEarningCard(String value, String label, {bool highlight = false}) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24),
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
              fontSize: 28,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          const Text(
            'Requirements',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: [
              _buildRequirementCard(Icons.verified_user, 'Valid ID Proof', 'Aadhaar, PAN, or\nDriving License'),
              _buildRequirementCard(Icons.phone_android, 'Smartphone', 'Android 6.0+\nor iOS 11+'),
              _buildRequirementCard(Icons.build, 'Basic Tools', 'Tools for your\nservice category'),
              _buildRequirementCard(Icons.school, 'Experience', 'Minimum 2 years\nin your field'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementCard(IconData icon, String title, String description) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(30),
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
          Icon(icon, size: 50, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 60),
          _buildFAQItem('How do I get paid?', 'Payments are transferred directly to your bank account every week.'),
          _buildFAQItem('What documents do I need?', 'Valid ID proof, address proof, and bank account details.'),
          _buildFAQItem('Can I choose my working hours?', 'Yes, you have complete flexibility to set your own schedule.'),
          _buildFAQItem('Is there any joining fee?', 'No, joining our platform is completely free.'),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            answer,
            style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: const Color(0xFF1A1F2E),
      child: const Center(
        child: Text(
          '© 2024 Bharat Doorstep. All rights reserved.',
          style: TextStyle(color: Color(0xFF666666)),
        ),
      ),
    );
  }
}