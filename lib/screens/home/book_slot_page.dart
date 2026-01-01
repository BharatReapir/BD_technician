import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'checkout_page.dart';

class BookSlotPage extends StatefulWidget {
  final String serviceName;
  final String price;

  const BookSlotPage({
    Key? key,
    required this.serviceName,
    required this.price,
  }) : super(key: key);

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  int selectedAddressIndex = 0;
  int selectedDateIndex = 0;
  int selectedTimeSlotIndex = -1;

  final List<Map<String, String>> addresses = [
    {
      'type': 'Home',
      'address': '123, MG Road, Sector 12',
      'city': 'Mumbai - 400001',
    },
    {
      'type': 'Office',
      'address': '456, Park Street, Block A',
      'city': 'Mumbai - 400002',
    },
  ];

  final List<Map<String, String>> dates = [
    {'day': 'Today', 'date': '12 Dec'},
    {'day': 'Tomorrow', 'date': '13 Dec'},
    {'day': 'Sat', 'date': '14 Dec'},
    {'day': 'Sun', 'date': '15 Dec'},
    {'day': 'Mon', 'date': '16 Dec'},
  ];

  final List<String> timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
  ];

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
        title: const Text(
          'Book Slot',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Address Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Select Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Address Cards
                  ...addresses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final address = entry.value;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAddressIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedAddressIndex == index
                                ? AppColors.primary
                                : AppColors.bgMedium,
                            width: selectedAddressIndex == index ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address['type']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address['address']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                  Text(
                                    address['city']!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedAddressIndex == index)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // Add New Address Button
                  GestureDetector(
                    onTap: () {
                      // Add new address functionality
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Add New Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Select Date Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Date Selector
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final isSelected = selectedDateIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDateIndex = index;
                            });
                          },
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.bgMedium,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date['day']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date['date']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isSelected ? Colors.white : AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Select Time Slot Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Icon(Icons.access_time, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Select Time Slot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time Slots
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedTimeSlotIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTimeSlotIndex = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.bgMedium,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              timeSlots[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedTimeSlotIndex == -1
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(
                              serviceName: widget.serviceName,
                              price: widget.price,
                              date: dates[selectedDateIndex]['date']!,
                              timeSlot: timeSlots[selectedTimeSlotIndex],
                              address: addresses[selectedAddressIndex],
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.bgMedium,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}