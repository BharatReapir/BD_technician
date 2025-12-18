import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingBookings(),
          _buildCompletedBookings(),
          _buildCancelledBookings(),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          'AC Repair',
          'Deep Cleaning & Gas Refill',
          '20 Dec 2024, 10:00 AM',
          'Technician: Rajesh Kumar',
          '₹1,299',
          AppColors.primary,
          true,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          'Washing Machine',
          'Drum Replacement',
          '22 Dec 2024, 2:00 PM',
          'Technician: Amit Shah',
          '₹899',
          AppColors.primary,
          true,
        ),
      ],
    );
  }

  Widget _buildCompletedBookings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          'TV Repair',
          'Screen Replacement',
          '15 Dec 2024, 11:00 AM',
          'Technician: Suresh Verma',
          '₹2,499',
          AppColors.textLight,
          false,
        ),
        const SizedBox(height: 12),
        _buildBookingCard(
          'Plumber',
          'Pipe Leak Fixing',
          '10 Dec 2024, 3:00 PM',
          'Technician: Dinesh Yadav',
          '₹599',
          AppColors.textLight,
          false,
        ),
      ],
    );
  }

  Widget _buildCancelledBookings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          'Electrician',
          'Wiring Repair',
          '5 Dec 2024, 9:00 AM',
          'Cancelled by user',
          '₹799',
          Colors.red,
          false,
        ),
      ],
    );
  }

  Widget _buildBookingCard(
    String service,
    String description,
    String datetime,
    String technicianInfo,
    String price,
    Color statusColor,
    bool showActions,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgMedium),
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
              Text(
                service,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                datetime,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              Text(
                technicianInfo,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Track',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}