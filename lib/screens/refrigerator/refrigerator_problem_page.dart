import 'package:bharatapp/screens/home/book_slot_page.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class RefrigeratorProblemPage extends StatefulWidget {
  final String refrigeratorType;

  const RefrigeratorProblemPage({
    Key? key,
    required this.refrigeratorType,
  }) : super(key: key);

  @override
  State<RefrigeratorProblemPage> createState() => _RefrigeratorProblemPageState();
}

class _RefrigeratorProblemPageState extends State<RefrigeratorProblemPage> {
  String? selectedProblem;

  final List<Map<String, dynamic>> problems = [
    {'name': 'Gas Refill', 'icon': Icons.local_gas_station, 'color': Color(0xFFFF9800)},
    {'name': 'Not Cooling', 'icon': Icons.ac_unit, 'color': Color(0xFF2196F3)},
    {'name': 'Slow Working', 'icon': Icons.speed, 'color': Color(0xFFFFC107)},
    {'name': 'Over Cooling', 'icon': Icons.thermostat, 'color': Color(0xFFF44336)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.refrigeratorType,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Issue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Only one problem allowed',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: problems.length,
              itemBuilder: (context, index) {
                final problem = problems[index];
                final isSelected = selectedProblem == problem['name'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedProblem = problem['name'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? problem['color'].withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? problem['color'] : Color(0xFFF5F5F5),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: problem['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            problem['icon'],
                            color: problem['color'],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            problem['name'],
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? problem['color'] : AppColors.textDark,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: problem['color'],
                            size: 28,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Book Button
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                // Price Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Visit Charge',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '₹299',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '✔ Inspection + Diagnosis Included',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Final repair cost technician inspection ke baad bataya jayega',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selectedProblem == null ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookSlotPage(
                            serviceName: '${widget.refrigeratorType} - $selectedProblem',
                            price: '₹299',
                            basePrice: 299.0,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE53935),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Book Technician',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}