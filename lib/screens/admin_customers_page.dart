import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({Key? key}) : super(key: key);

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage customer accounts',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Customers', '2,847', Icons.people, const Color(0xFFE8F5E9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Active This Month', '1,234', Icons.trending_up, const Color(0xFFE3F2FD)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('New This Week', '87', Icons.person_add, const Color(0xFFFFF3E0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Avg Rating', '4.6★', Icons.star, const Color(0xFFF3E5F5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Search Bar
          SizedBox(
            width: double.infinity,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Customers Table
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
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
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 96,
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(180),
                        1: FixedColumnWidth(200),
                        2: FixedColumnWidth(140),
                        3: FixedColumnWidth(90),
                        4: FixedColumnWidth(130),
                        5: FixedColumnWidth(100),
                        6: FixedColumnWidth(70),
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
                              padding: EdgeInsets.all(12),
                              child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Last Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                        // Data rows
                        _buildCustomerRow('Priya Sharma', 'priya.sharma@email.com', '+91 98765 43210', '12', '20 Dec 2024', true),
                        _buildCustomerRow('Amit Patel', 'amit.patel@email.com', '+91 98765 43211', '8', '19 Dec 2024', true),
                        _buildCustomerRow('Neha Gupta', 'neha.gupta@email.com', '+91 98765 43212', '15', '20 Dec 2024', true),
                        _buildCustomerRow('Rohit Verma', 'rohit.verma@email.com', '+91 98765 43213', '5', '18 Dec 2024', true),
                        _buildCustomerRow('Kavita Singh', 'kavita.singh@email.com', '+91 98765 43214', '20', '21 Dec 2024', true),
                        _buildCustomerRow('Raj Malhotra', 'raj.malhotra@email.com', '+91 98765 43215', '3', '15 Dec 2024', false),
                        _buildCustomerRow('Sonia Kapoor', 'sonia.kapoor@email.com', '+91 98765 43216', '18', '20 Dec 2024', true),
                        _buildCustomerRow('Arjun Reddy', 'arjun.reddy@email.com', '+91 98765 43217', '7', '17 Dec 2024', true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
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

  TableRow _buildCustomerRow(
    String name,
    String email,
    String phone,
    String bookings,
    String lastBooking,
    bool isActive,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name, 
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            email, 
            style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(phone, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(bookings, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(lastBooking, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Profile')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'block', child: Text('Block')),
            ],
          ),
        ),
      ],
    );
  }
}