import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({Key? key}) : super(key: key);

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled'];

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
                      'Bookings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage all service bookings',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
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
          const SizedBox(height: 32),
          
          // Filters and Search
          Row(
            children: [
              // Filters
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : const Color(0xFF666666),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Search
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            ],
          ),
          const SizedBox(height: 24),
          
          // Bookings Table
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
                        0: FixedColumnWidth(100),
                        1: FixedColumnWidth(140),
                        2: FixedColumnWidth(130),
                        3: FixedColumnWidth(130),
                        4: FixedColumnWidth(140),
                        5: FixedColumnWidth(90),
                        6: FixedColumnWidth(110),
                        7: FixedColumnWidth(70),
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
                              child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                        _buildBookingRow('#BD1234', 'Priya Sharma', 'AC Repair', 'Rajesh Kumar', '20 Dec, 10:00 AM', '₹549', 'Completed', AppColors.primary),
                        _buildBookingRow('#BD1235', 'Amit Patel', 'Plumbing', 'Suresh Singh', '20 Dec, 12:00 PM', '₹399', 'In Progress', Colors.orange),
                        _buildBookingRow('#BD1236', 'Neha Gupta', 'Electrical', 'Ramesh Yadav', '20 Dec, 02:00 PM', '₹299', 'Pending', Colors.grey),
                        _buildBookingRow('#BD1237', 'Rohit Verma', 'TV Repair', 'Dinesh Kumar', '20 Dec, 04:00 PM', '₹699', 'Completed', AppColors.primary),
                        _buildBookingRow('#BD1238', 'Kavita Singh', 'Washing Machine', 'Mukesh Jain', '21 Dec, 09:00 AM', '₹499', 'In Progress', Colors.orange),
                        _buildBookingRow('#BD1239', 'Raj Malhotra', 'Refrigerator', 'Anil Sharma', '21 Dec, 11:00 AM', '₹599', 'Pending', Colors.grey),
                        _buildBookingRow('#BD1240', 'Sonia Kapoor', 'Painting', 'Vijay Kumar', '21 Dec, 03:00 PM', '₹1299', 'Completed', AppColors.primary),
                        _buildBookingRow('#BD1241', 'Arjun Reddy', 'Carpentry', 'Ravi Verma', '22 Dec, 10:00 AM', '₹799', 'Cancelled', Colors.red),
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

  TableRow _buildBookingRow(
    String id,
    String customer,
    String service,
    String technician,
    String dateTime,
    String amount,
    String status,
    Color statusColor,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(id, style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(customer, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(service, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(technician, style: const TextStyle(color: Color(0xFF666666), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(dateTime, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: PopupMenuButton(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Details')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
            ],
          ),
        ),
      ],
    );
  }
}