import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/quick_access_button.dart';
import '../../widgets/service_card.dart';
import '../bookings_page.dart';
import '../wallet_page.dart';
import '../support_page.dart';
import '../profile_page.dart';
import 'service_category_page.dart';
import '../refrigerator/refrigerator_type_page.dart';
import '../washing_machine/washing_machine_type_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _selectedIndex == 0 ? const HomeContent() : 
             _selectedIndex == 1 ? const BookingsPage() :
             _selectedIndex == 2 ? const WalletPage(technicianId: '',) :
             _selectedIndex == 3 ? const SupportPage() :
             const ProfilePage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGray,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones_outlined),
              activeIcon: Icon(Icons.headphones),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  void _navigateToService(BuildContext context, String serviceType, IconData icon) {
    // AC Repair - Goes to full flow
    if (serviceType == 'AC Repair') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceCategoryPage(
            serviceType: serviceType,
            icon: icon,
          ),
        ),
      );
    } 
    // Refrigerator - Direct to type selection
    else if (serviceType == 'Refrigerator') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RefrigeratorTypePage(),
        ),
      );
    } 
    // Washing Machine - Direct to type selection
    else if (serviceType == 'Washing Machine') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WashingMachineTypePage(),
        ),
      );
    } 
    // Others - Coming soon
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bharat Doorstep',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your Trusted Service Partner',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                            onPressed: () {},
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Mumbai',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            
            // Offers Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    OfferCard(
                      title: 'First Time Users',
                      offer: '40% OFF',
                      code: 'Code: FIRST40',
                      startColor: AppColors.primary,
                      endColor: AppColors.tertiary,
                    ),
                    SizedBox(width: 12),
                    OfferCard(
                      title: 'AC Service Special',
                      offer: '₹299 Only',
                      code: 'Code: AC299',
                      startColor: AppColors.primary,
                      endColor: AppColors.tertiary,
                    ),
                    SizedBox(width: 12),
                    OfferCard(
                      title: 'Weekend Deal',
                      offer: 'Flat ₹200 OFF',
                      code: 'Code: WEEKEND200',
                      startColor: AppColors.primary,
                      endColor: AppColors.tertiary,
                    ),
                  ],
                ),
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for services...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                  filled: true,
                  fillColor: AppColors.bgMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            // Quick Access
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  QuickAccessButton(icon: Icons.calendar_today, label: 'Bookings'),
                  QuickAccessButton(icon: Icons.account_balance_wallet, label: 'Wallet'),
                  QuickAccessButton(icon: Icons.headphones, label: 'Support'),
                  QuickAccessButton(icon: Icons.person, label: 'Profile'),
                ],
              ),
            ),
            
            
            // All Services
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'All Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            
            // Services Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // AC Repair - Full flow
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'AC Repair', Icons.ac_unit),
                    child: const ServiceCard(
                      icon: Icons.ac_unit,
                      title: 'AC Repair',
                      bgColor: AppColors.serviceBg1,
                    ),
                  ),
                  
                  // Refrigerator - Direct flow
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'Refrigerator', Icons.kitchen),
                    child: const ServiceCard(
                      icon: Icons.kitchen,
                      title: 'Refrigerator',
                      bgColor: AppColors.serviceBg2,
                    ),
                  ),
                  
                  // Washing Machine - Direct flow
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'Washing Machine', Icons.local_laundry_service),
                    child: const ServiceCard(
                      icon: Icons.local_laundry_service,
                      title: 'Washing Machine',
                      bgColor: AppColors.serviceBg3,
                    ),
                  ),
                  
                  // TV Repair - Coming soon
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'TV Repair', Icons.tv),
                    child: const ServiceCard(
                      icon: Icons.tv,
                      title: 'TV Repair',
                      bgColor: AppColors.serviceBg1,
                    ),
                  ),
                  
                  // Electrician - Coming soon
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'Electrician', Icons.bolt),
                    child: const ServiceCard(
                      icon: Icons.bolt,
                      title: 'Electrician',
                      bgColor: AppColors.serviceBg2,
                    ),
                  ),
                  
                  // Plumber - Coming soon
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'Plumber', Icons.build),
                    child: const ServiceCard(
                      icon: Icons.build,
                      title: 'Plumber',
                      bgColor: AppColors.serviceBg3,
                    ),
                  ),
                  
                  // Cleaning - Coming soon
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'Cleaning', Icons.cleaning_services),
                    child: const ServiceCard(
                      icon: Icons.cleaning_services,
                      title: 'Cleaning',
                      bgColor: AppColors.serviceBg1,
                    ),
                  ),
                  
                  // More - Coming soon
                  GestureDetector(
                    onTap: () => _navigateToService(context, 'More', Icons.more_horiz),
                    child: const ServiceCard(
                      icon: Icons.more_horiz,
                      title: 'More',
                      bgColor: AppColors.serviceBg2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}