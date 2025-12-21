import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'website_login_page.dart';
import 'become_partner_page.dart';

class WebsitePage extends StatefulWidget {
  const WebsitePage({Key? key}) : super(key: key);

  @override
  State<WebsitePage> createState() => _WebsitePageState();
}

class _WebsitePageState extends State<WebsitePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _whyChooseKey = GlobalKey();
  final GlobalKey _technicianKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WebsiteLoginPage()),
    );
  }

  void _navigateToPartner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BecomePartnerPage()),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Book Service'),
          content: const Text('Please login to book a service'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildNavBar(),
            _buildHeroSection(),
            _buildServicesSection(),
            _buildHowItWorksSection(),
            _buildWhyChooseUsSection(),
            _buildTechnicianSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Bharat\nDoorstep',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _navigateToLogin,
              color: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.build),
              onPressed: _showBookingDialog,
              color: AppColors.primary,
            ),
          ],
        ),
      );
    }

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
          _buildNavLink('Home', () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut)),
          const SizedBox(width: 40),
          _buildNavLink('Services', () => _scrollToSection(_servicesKey)),
          const SizedBox(width: 40),
          _buildNavLink('How It Works', () => _scrollToSection(_howItWorksKey)),
          const SizedBox(width: 40),
          _buildNavLink('Partner With Us', _navigateToPartner),
          const SizedBox(width: 40),
          _buildNavLink('Why Choose Us', () => _scrollToSection(_whyChooseKey)),
          const SizedBox(width: 40),
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Login',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: _showBookingDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Book Service',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 16,
        ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0F2E9),
            Color(0xFFC7EBE0),
            Color(0xFFA8DFD5),
          ],
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fast, Trusted\nDoorstep Repairs',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Professional technicians at your doorstep. Quality service guaranteed. Book now and get instant quotes!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF555555),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _showBookingDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Book Service Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _scrollToSection(_servicesKey),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Explore Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 30,
                  runSpacing: 20,
                  children: [
                    _buildStat('10,000+', 'Happy Customers', isMobile),
                    _buildStat('500+', 'Expert Technicians', isMobile),
                    _buildStat('4.8★', 'Average Rating', isMobile),
                  ],
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
                        'Fast, Trusted\nDoorstep Repairs',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Professional technicians at your doorstep.\nQuality service guaranteed. Book now and\nget instant quotes!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF555555),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _showBookingDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Book Service Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          OutlinedButton(
                            onPressed: () => _scrollToSection(_servicesKey),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              side: const BorderSide(color: AppColors.primary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Explore Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Row(
                        children: [
                          _buildStat('10,000+', 'Happy\nCustomers', false),
                          const SizedBox(width: 80),
                          _buildStat('500+', 'Expert\nTechnicians', false),
                          const SizedBox(width: 80),
                          _buildStat('4.8★', 'Average\nRating', false),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Icon(
                      Icons.build_circle,
                      size: 300,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String value, String label, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: const Color(0xFF555555),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      key: _servicesKey,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Our Services',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Expert solutions for all your home repair needs',
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: const Color(0xFF666666),
            ),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          Wrap(
            spacing: isMobile ? 20 : 40,
            runSpacing: isMobile ? 20 : 40,
            alignment: WrapAlignment.center,
            children: [
              _buildServiceCard(Icons.ac_unit, 'AC Repair', isMobile),
              _buildServiceCard(Icons.tv, 'TV Repair', isMobile),
              _buildServiceCard(Icons.kitchen, 'Refrigerator', isMobile),
              _buildServiceCard(Icons.local_laundry_service, 'Washing Machine', isMobile),
              _buildServiceCard(Icons.electrical_services, 'Electrical', isMobile),
              _buildServiceCard(Icons.plumbing, 'Plumbing', isMobile),
              _buildServiceCard(Icons.format_paint, 'Painting', isMobile),
              _buildServiceCard(Icons.weekend, 'Furniture', isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title, bool isMobile) {
    return SizedBox(
      width: isMobile ? 150 : 200,
      child: Column(
        children: [
          Container(
            width: isMobile ? 80 : 100,
            height: isMobile ? 80 : 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: isMobile ? 40 : 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      key: _howItWorksKey,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Text(
            'How It Works',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Get your service done in 3 simple steps',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: const Color(0xFF666666),
            ),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          isMobile
              ? Column(
                  children: [
                    _buildStep('1', 'Book Your Service',
                        'Choose your service and select a convenient time slot', isMobile),
                    const SizedBox(height: 40),
                    _buildStep('2', 'Expert Arrives',
                        'Verified technician reaches your doorstep on time', isMobile),
                    const SizedBox(height: 40),
                    _buildStep('3', 'Job Done!',
                        'Quality service completed, pay after satisfaction', isMobile),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStep('1', 'Book Your Service',
                        'Choose your service and select a\nconvenient time slot', isMobile),
                    const SizedBox(width: 80),
                    _buildStep('2', 'Expert Arrives',
                        'Verified technician reaches your\ndoorstep on time', isMobile),
                    const SizedBox(width: 80),
                    _buildStep('3', 'Job Done!',
                        'Quality service completed, pay after\nsatisfaction', isMobile),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description, bool isMobile) {
    return Column(
      children: [
        Container(
          width: isMobile ? 100 : 120,
          height: isMobile ? 100 : 120,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              number == '1'
                  ? Icons.phone_android
                  : number == '2'
                      ? Icons.local_shipping
                      : Icons.check_circle,
              size: isMobile ? 50 : 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Step $number',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: const Color(0xFF666666),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWhyChooseUsSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      key: _whyChooseKey,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Why Choose Us',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your trust is our priority',
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: const Color(0xFF666666),
            ),
          ),
          SizedBox(height: isMobile ? 30 : 60),
          isMobile
              ? Column(
                  children: [
                    _buildFeature(Icons.verified, 'Verified Technicians',
                        'Background verified professionals', const Color(0xFFE0F2E9), isMobile),
                    const SizedBox(height: 30),
                    _buildFeature(Icons.star, 'Quality Service', '4.8 star average rating',
                        const Color(0xFFE3F2FD), isMobile),
                    const SizedBox(height: 30),
                    _buildFeature(Icons.schedule, 'On-Time Service', '99% on-time arrival rate',
                        const Color(0xFFE0F2E9), isMobile),
                    const SizedBox(height: 30),
                    _buildFeature(Icons.workspace_premium, 'Money-Back Guarantee',
                        '100% satisfaction guaranteed', const Color(0xFFE3F2FD), isMobile),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeature(Icons.verified, 'Verified Technicians',
                        'Background verified\nprofessionals', const Color(0xFFE0F2E9), isMobile),
                    const SizedBox(width: 60),
                    _buildFeature(Icons.star, 'Quality Service', '4.8 star average rating',
                        const Color(0xFFE3F2FD), isMobile),
                    const SizedBox(width: 60),
                    _buildFeature(Icons.schedule, 'On-Time Service', '99% on-time arrival\nrate',
                        const Color(0xFFE0F2E9), isMobile),
                    const SizedBox(width: 60),
                    _buildFeature(Icons.workspace_premium, 'Money-Back\nGuarantee',
                        '100% satisfaction\nguaranteed', const Color(0xFFE3F2FD), isMobile),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildFeature(
      IconData icon, String title, String description, Color bgColor, bool isMobile) {
    return Column(
      children: [
        Container(
          width: isMobile ? 70 : 80,
          height: isMobile ? 70 : 80,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: isMobile ? 35 : 40,
            color: icon == Icons.star || icon == Icons.workspace_premium
                ? Colors.blue[700]
                : AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: const Color(0xFF666666),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianSection() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      key: _technicianKey,
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
                const Text(
                  'Join as a Technician',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Earn up to ₹50,000/month with flexible working hours',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                _buildBenefit('Earn 80% of service charges', isMobile),
                const SizedBox(height: 12),
                _buildBenefit('Weekly settlement cycle', isMobile),
                const SizedBox(height: 12),
                _buildBenefit('Work on your own schedule', isMobile),
                const SizedBox(height: 12),
                _buildBenefit('Get jobs near your location', isMobile),
                const SizedBox(height: 12),
                _buildBenefit('Training & support provided', isMobile),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A7B8E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earnings Model',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildEarningRow('Average Service Price', '₹500', false, isMobile),
                      const Divider(color: Colors.white24, height: 30),
                      _buildEarningRow('Your Share (80%)', '₹400', true, isMobile),
                      const Divider(color: Colors.white24, height: 30),
                      _buildEarningRow('Jobs per Day', '4-6', false, isMobile),
                      const Divider(color: Colors.white24, height: 30),
                      _buildEarningRow('Daily Earnings', '₹1,600+', true, isMobile),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToPartner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D4A5A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Become A Partner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        'Join as a Technician',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Earn up to ₹50,000/month with flexible\nworking hours',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildBenefit('Earn 80% of service charges', false),
                      const SizedBox(height: 16),
                      _buildBenefit('Weekly settlement cycle', false),
                      const SizedBox(height: 16),
                      _buildBenefit('Work on your own schedule', false),
                      const SizedBox(height: 16),
                      _buildBenefit('Get jobs near your location', false),
                      const SizedBox(height: 16),
                      _buildBenefit('Training & support provided', false),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _navigateToPartner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D4A5A),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Become A Partner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A7B8E).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Earnings Model',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildEarningRow('Average Service Price', '₹500', false, false),
                        const Divider(color: Colors.white24, height: 40),
                        _buildEarningRow('Your Share (80%)', '₹400', true, false),
                        const Divider(color: Colors.white24, height: 40),
                        _buildEarningRow('Jobs per Day', '4-6', false, false),
                        const Divider(color: Colors.white24, height: 40),
                        _buildEarningRow('Daily Earnings', '₹1,600+', true, false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBenefit(String text, bool isMobile) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.white, size: isMobile ? 20 : 24),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningRow(String label, String value, bool isHighlight, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? (isMobile ? 24 : 28) : (isMobile ? 18 : 20),
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? const Color(0xFF4ADE80) : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 60,
      ),
      color: const Color(0xFF1A1F2E),
      child: Column(
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Bharat Doorstep',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fast. Trusted. Doorstep Repairs.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFAAAAAA),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.telegram),
                        const SizedBox(width: 16),
                        _buildSocialIcon(Icons.camera_alt),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Company',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('About Us'),
                    _buildFooterLink('Careers'),
                    _buildFooterLink('Blog'),
                    _buildFooterLink('Press'),
                    const SizedBox(height: 30),
                    const Text(
                      'Legal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Privacy Policy'),
                    _buildFooterLink('Terms of Service'),
                    _buildFooterLink('Refund Policy'),
                    _buildFooterLink('Cancellation'),
                    const SizedBox(height: 30),
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '+91 9999222200',
                          style: TextStyle(
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'support@bharatdoorstep.com',
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mumbai, Maharashtra, India',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Bharat Doorstep',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Fast. Trusted. Doorstep\nRepairs.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFAAAAAA),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              _buildSocialIcon(Icons.facebook),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.telegram),
                              const SizedBox(width: 16),
                              _buildSocialIcon(Icons.camera_alt),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Company',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFooterLink('About Us'),
                          _buildFooterLink('Careers'),
                          _buildFooterLink('Blog'),
                          _buildFooterLink('Press'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Legal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFooterLink('Privacy Policy'),
                          _buildFooterLink('Terms of Service'),
                          _buildFooterLink('Refund Policy'),
                          _buildFooterLink('Cancellation'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Icon(Icons.phone, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '+91 9999222200',
                                style: TextStyle(
                                  color: Color(0xFFAAAAAA),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'support@bharatdoorstep.com',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mumbai, Maharashtra,\nIndia',
                                  style: TextStyle(
                                    color: Color(0xFFAAAAAA),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 40 : 60),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 20),
          Text(
            '© 2025 Bharat Doorstep. All rights reserved.',
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
      ),
    );
  }
}