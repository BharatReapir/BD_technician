// screens/coin_info_page.dart
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CoinInfoPage extends StatelessWidget {
  const CoinInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'How Coins Work',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'What are Coins?',
              description:
                  'Coins are loyalty points you earn with every completed booking. They are not cash or wallet money, but a discount tool for your next service.',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.calculate,
              title: 'Coin Value',
              description: '100 Coins = ₹1\n\nExample: 1000 Coins = ₹10 discount',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Welcome Bonus'),
            _buildWelcomeBonusTable(),
            const SizedBox(height: 24),
            _buildSectionTitle('Regular Booking Coins'),
            const SizedBox(height: 8),
            _buildInfoCard(
              icon: Icons.redeem,
              title: 'Earn Coins',
              description:
                  'Earn 10, 20, 30, 40, 50, 60, 70, 80, or 90 coins per completed booking (Maximum 90 coins).\n\nCoins are credited only after successful service completion.',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Using Your Coins'),
            const SizedBox(height: 8),
            _buildInfoCard(
              icon: Icons.discount,
              title: 'Redeem for Discounts',
              description:
                  'Use coins to get discounts on:\n• Service charges\n• Visiting charges\n• Wallet recharge\n• Commission payments',
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('GST Calculation Example'),
            const SizedBox(height: 8),
            _buildBillingExample(),
            const SizedBox(height: 24),
            _buildSectionTitle('Important Rules'),
            const SizedBox(height: 8),
            _buildRuleItem(
              '✓ Coins are applied BEFORE GST calculation',
            ),
            _buildRuleItem(
              '✓ All coins expire after 180 days',
            ),
            _buildRuleItem(
              '✓ Cancelled bookings (before visit) will reverse earned coins',
            ),
            _buildRuleItem(
              '✓ Cancelled bookings (after visit) will not reverse coins',
            ),
            _buildRuleItem(
              '✓ Coins cannot be transferred or withdrawn',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildWelcomeBonusTable() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.bgMedium),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTableRow('1st Booking', '1000 Coins', '₹10', isHeader: true),
          _buildTableRow('2nd Booking', '1500 Coins', '₹15'),
          _buildTableRow('3rd Booking', '2000 Coins', '₹20'),
          _buildTableRow('4th Booking', '2500 Coins', '₹25'),
          _buildTableRow('5th Booking', '3000 Coins', '₹30'),
        ],
      ),
    );
  }

  Widget _buildTableRow(String booking, String coins, String value,
      {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.primary.withOpacity(0.1) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.bgMedium,
            width: isHeader ? 0 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              booking,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              coins,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bgMedium),
      ),
      child: Column(
        children: [
          _buildBillingRow('Service Charges', '₹1,000'),
          _buildBillingRow('Visiting Charges', '₹299'),
          _buildBillingRow('Coin Discount (1000 Coins)', '- ₹10',
              isDiscount: true),
          const Divider(height: 24),
          _buildBillingRow('Taxable Value', '₹1,289', isBold: true),
          _buildBillingRow('GST @18%', '₹232.02'),
          const Divider(height: 24),
          _buildBillingRow('Total Payable', '₹1,521.02', isBold: true, isTotal: true),
          const SizedBox(height: 8),
          const Text(
            'Note: Coin discount is applied before GST calculation',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(String label, String value,
      {bool isDiscount = false, bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDiscount
                  ? Colors.green
                  : isTotal
                      ? AppColors.primary
                      : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}