import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'admin_bookings_page.dart';
import 'admin_customers_page.dart';
import 'admin_pricing_page.dart';
import 'admin_settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard'},
    {'icon': Icons.calendar_today, 'title': 'Bookings'},
    {'icon': Icons.people, 'title': 'Customers'},
    {'icon': Icons.build, 'title': 'Technicians'},
    {'icon': Icons.home_repair_service, 'title': 'Services'},
    {'icon': Icons.attach_money, 'title': 'Pricing'},
    {'icon': Icons.account_balance_wallet, 'title': 'Payouts'},
    {'icon': Icons.local_offer, 'title': 'Coupons'},
    {'icon': Icons.report_problem, 'title': 'Complaints'},
    {'icon': Icons.bar_chart, 'title': 'Reports'},
    {'icon': Icons.settings, 'title': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarExpanded ? 250 : 80,
            color: const Color(0xFF0D47A1),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (_isSidebarExpanded)
                        const Expanded(
                          child: Text(
                            'BD Admin',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarExpanded = !_isSidebarExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Menu Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return _buildMenuItem(
                        icon: _menuItems[index]['icon'],
                        title: _menuItems[index]['title'],
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const AdminBookingsPage();
      case 2:
        return const AdminCustomersPage();
      case 4:
        return const AdminPricingPage();
      case 10:
        return const AdminSettingsPage();
      default:
        return _buildPlaceholder();
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: _isSidebarExpanded
            ? Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              )
            : null,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _isSidebarExpanded ? 16 : 28,
          vertical: 8,
        ),
      ),
    );
  }

  Widget _buildDashboard() {
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
                'Dashboard',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Welcome back, Admin!',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  title: 'Total Bookings',
                  value: '1,234',
                  percentage: '+12%',
                  isPositive: true,
                  color: const Color(0xFFE8F5E9),
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  title: 'Revenue',
                  value: '₹3.2L',
                  percentage: '+18%',
                  isPositive: true,
                  color: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.build,
                  title: 'Active Technicians',
                  value: '342',
                  percentage: '+5%',
                  isPositive: true,
                  color: const Color(0xFFE8F5E9),
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Pending Settlements',
                  value: '₹45K',
                  percentage: '-3%',
                  isPositive: false,
                  color: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Trends
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                        'Booking Trends',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _buildBarChart(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Category Performance
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                        'Category Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCategoryItem('AC Repair', 35, AppColors.primary),
                      const SizedBox(height: 16),
                      _buildCategoryItem('TV Repair', 25, const Color(0xFF1976D2)),
                      const SizedBox(height: 16),
                      _buildCategoryItem('Electrical', 20, AppColors.primary),
                      const SizedBox(height: 16),
                      _buildCategoryItem('Plumbing', 15, const Color(0xFF1976D2)),
                      const SizedBox(height: 16),
                      _buildCategoryItem('Others', 5, AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Recent Bookings Table
          Container(
            padding: const EdgeInsets.all(24),
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
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String percentage,
    required bool isPositive,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? AppColors.primary : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.primary : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final List<double> data = [0.5, 0.7, 0.6, 0.8, 0.75, 0.85, 0.9];
    final List<String> labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate bar width based on available space
        final totalMargins = 7 * 8.0; // 7 bars with 4px margin on each side
        final availableWidth = constraints.maxWidth - totalMargins;
        final barWidth = (availableWidth / 7).clamp(30.0, 60.0);
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    width: barWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    height: 300 * data[index],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildCategoryItem(String name, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.5),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Booking ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Customer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Service',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Technician',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
        // Data Rows
        _buildTableRow('#BD1234', 'Priya Sharma', 'AC Repair', 'Rajesh Kumar', '₹549', 'Completed', AppColors.primary),
        _buildTableRow('#BD1235', 'Amit Patel', 'Plumbing', 'Suresh Singh', '₹399', 'In Progress', Colors.orange),
        _buildTableRow('#BD1236', 'Neha Gupta', 'Electrical', 'Ramesh Yadav', '₹299', 'Pending', Colors.grey),
        _buildTableRow('#BD1237', 'Rohit Verma', 'TV Repair', 'Dinesh Kumar', '₹699', 'Completed', AppColors.primary),
        _buildTableRow('#BD1238', 'Kavita Singh', 'Washing Machine', 'Mukesh Jain', '₹499', 'In Progress', Colors.orange),
      ],
    );
  }

  TableRow _buildTableRow(
    String id,
    String customer,
    String service,
    String technician,
    String amount,
    String status,
    Color statusColor,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            id,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            customer,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            service,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            technician,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}