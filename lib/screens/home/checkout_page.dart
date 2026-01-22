// screens/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../services/coin_service.dart';
import '../../models/coin_model.dart';
import 'payment_page.dart';

class CheckoutPage extends StatefulWidget {
  final String serviceName;
  final String price;
  final double basePrice;
  final String date;
  final String timeSlot;
  final Map<String, String> address;

  const CheckoutPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.basePrice,
    required this.date,
    required this.timeSlot,
    required this.address,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController coinController = TextEditingController();
  
  bool _useCoins = false;
  int _coinsToRedeem = 0;
  CoinBalance? _coinBalance;
  bool _loadingCoins = true;
  
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadCoinBalance();
  }

  Future<void> _loadCoinBalance() async {
    if (userId.isEmpty) {
      setState(() => _loadingCoins = false);
      return;
    }
    
    try {
      final balance = await CoinService.getCoinBalance(userId);
      setState(() {
        _coinBalance = balance;
        _loadingCoins = false;
      });
    } catch (e) {
      print('Error loading coins: $e');
      setState(() => _loadingCoins = false);
    }
  }

  void _showCoinInputDialog() {
    if (_coinBalance == null || _coinBalance!.totalCoins == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have any coins yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final maxCoins = _coinBalance!.totalCoins;
    coinController.text = _coinsToRedeem > 0 ? _coinsToRedeem.toString() : '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use Your Coins'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Coins',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray,
                          ),
                        ),
                        Text(
                          '$maxCoins coins',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Worth ₹${(maxCoins / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: coinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Coins to Use',
                hintText: 'Enter coins (max $maxCoins)',
                border: const OutlineInputBorder(),
                suffixText: 'coins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discount: ₹${((int.tryParse(coinController.text) ?? 0) / 100).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100 coins = ₹1 discount',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final coins = int.tryParse(coinController.text) ?? 0;
              if (coins > 0 && coins <= maxCoins) {
                setState(() {
                  _coinsToRedeem = coins;
                  _useCoins = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied $coins coins (₹${(coins / 100).toStringAsFixed(2)} discount)'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter valid coins (1 - $maxCoins)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Apply Coins'),
          ),
        ],
      ),
    );
  }

  void _removeCoins() {
    setState(() {
      _useCoins = false;
      _coinsToRedeem = 0;
      coinController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coins removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  double getCoinDiscount() {
    return _useCoins ? _coinsToRedeem / 100.0 : 0.0;
  }

  double getDiscountedPrice() {
    return widget.basePrice - getCoinDiscount();
  }

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
          'Checkout',
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
                  // Service Details Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Service', widget.serviceName),
                        _buildDetailRow('Date & Time', '${widget.date} • ${widget.timeSlot.split(' - ')[0]}'),
                        _buildDetailRow('Address', '${widget.address['type']} - ${widget.address['city']} ${widget.address['pincode']}'),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Coins Section
                  if (!_loadingCoins && _coinBalance != null && _coinBalance!.totalCoins > 0)
                    _buildCoinsSection(),
                  
                  const Divider(height: 1),
                  
                  // Price Breakdown Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Price Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildPriceRow('Service Charge', '₹${widget.basePrice.toStringAsFixed(0)}'),
                              if (_useCoins && _coinsToRedeem > 0) ...[
                                const SizedBox(height: 8),
                                _buildPriceRow(
                                  'Coin Discount ($_coinsToRedeem coins)',
                                  '-₹${getCoinDiscount().toStringAsFixed(2)}',
                                  isDiscount: true,
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              _buildPriceRow(
                                'Subtotal',
                                '₹${getDiscountedPrice().toStringAsFixed(2)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Additional Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Visiting charge, GST & any additional costs will be added in next step. Coin discount is applied before GST calculation.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        serviceName: widget.serviceName,
                        serviceCharge: getDiscountedPrice(),
                        date: widget.date,
                        timeSlot: widget.timeSlot,
                        address: widget.address,
                        coinsUsed: _coinsToRedeem,
                        coinDiscount: getCoinDiscount(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _useCoins && _coinsToRedeem > 0
                      ? 'Proceed (Save ₹${getCoinDiscount().toStringAsFixed(2)})'
                      : 'Proceed to Payment',
                  style: const TextStyle(
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

  Widget _buildCoinsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.monetization_on, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Use Coins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_useCoins && _coinsToRedeem > 0) ...[
            // Applied Coins Display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_coinsToRedeem Coins Applied',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'You\'re saving ₹${getCoinDiscount().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeCoins,
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    tooltip: 'Remove coins',
                  ),
                ],
              ),
            ),
          ] else ...[
            // Coin Selection Card
            GestureDetector(
              onTap: _showCoinInputDialog,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bgMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.monetization_on, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Coins',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_coinBalance!.totalCoins} coins',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Worth ₹${_coinBalance!.discountValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'USE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 14),
                  ],
                ),
              ),
            ),
          ],
          
          // Expiring Coins Warning
          if (_coinBalance!.expiringCoins > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_coinBalance!.expiringCoins} coins expiring in ${_coinBalance!.daysUntilExpiry} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDiscount ? Colors.green : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    coinController.dispose();
    super.dispose();
  }
}