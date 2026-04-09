import '../constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/wallet_service.dart';
import '../services/tech_payment_service.dart';
import '../models/wallet_transaction_model.dart';
import '../models/billing_model.dart';
import 'package:intl/intl.dart';

class TechWalletPage extends StatefulWidget {
  final String technicianId;

  const TechWalletPage({Key? key, required this.technicianId}) : super(key: key);

  @override
  State<TechWalletPage> createState() => _TechWalletPageState();
}

class _TechWalletPageState extends State<TechWalletPage> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  late Razorpay _razorpay;
  bool _isLoading = false;

  // ⚠️ REPLACE WITH YOUR ACTUAL RAZORPAY KEY
  static const String RAZORPAY_KEY = 'rzp_test_S4yQ9pfJFZGHEV';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Debug: Print technician ID
    debugPrint('🔍 Technician ID: ${widget.technicianId}');
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment Success');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Signature: ${response.signature}');

    setState(() {
      _isLoading = true;
    });

    try {
      await TechPaymentService.verifyWalletPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        technicianId: widget.technicianId,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Wallet recharged successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Verification failed: $e'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment Failed');
    debugPrint('Code: ${response.code}');
    debugPrint('Message: ${response.message}');

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet: ${response.walletName}')),
      );
    }
  }

  Future<void> _initiatePayment() async {
    final amountText = _amountController.text.trim();
    
    debugPrint('🔍 Initiating payment...');
    debugPrint('Amount text: "$amountText"');
    
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    double? amount = double.tryParse(amountText);
    
    if (amount == null) {
      _showError('Invalid amount entered');
      return;
    }

    if (amount < 100) {
      _showError('Minimum recharge amount is ₹100');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('📤 Creating order for ₹$amount');
      debugPrint('📤 Technician ID: ${widget.technicianId}');
      
      // Calculate GST-compliant wallet recharge
      final rechargeCalculation = PricingCalculator.calculateWalletRecharge(amount);
      final totalAmount = rechargeCalculation['totalAmount']!;
      final gstAmount = rechargeCalculation['gstAmount']!;
      
      debugPrint('💰 Recharge Amount: ₹$amount');
      debugPrint('💰 GST Amount: ₹$gstAmount');
      debugPrint('💰 Total Amount: ₹$totalAmount');
      
      // Create order on backend
      final orderData = await TechPaymentService.createWalletRechargeOrder(
        technicianId: widget.technicianId,
        amount: totalAmount, // Send total amount including GST
      );

      debugPrint('📥 Order data received: $orderData');

      // Check if orderId exists
      if (!orderData.containsKey('orderId') || orderData['orderId'] == null) {
        throw Exception('Order ID not received from server');
      }

      var options = {
        'key': RAZORPAY_KEY,
        'amount': (totalAmount * 100).toInt(), // Amount in paise (including GST)
        'order_id': orderData['orderId'],
        'name': 'Wallet Recharge',
        'description': 'Recharge your technician wallet (₹$amount + GST ₹${gstAmount.toStringAsFixed(2)})',
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#EB4D4B',
        },
        'notes': {
          'recharge_amount': amount.toString(),
          'gst_amount': gstAmount.toString(),
          'total_amount': totalAmount.toString(),
        },
      };

      if (mounted) {
        Navigator.pop(context); // Close dialog first
      }

      debugPrint('🚀 Opening Razorpay with options: $options');
      _razorpay.open(options);
      _amountController.clear();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error in _initiatePayment: $e');
      
      setState(() {
        _isLoading = false;
      });

      _showError('Failed to create order: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showRechargeDialog() {
    _amountController.clear(); // Clear before showing
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recharge Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Recharge Amount',
                prefixText: '₹',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter amount',
                helperText: 'GST @18% will be added',
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to update GST calculation
              },
            ),
            const SizedBox(height: 16),
            
            // GST Breakdown Display
            if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recharge Amount:'),
                        Text('₹${_amountController.text}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GST @18%:'),
                        Text('₹${(double.parse(_amountController.text) * 0.18).toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Payable:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${(double.parse(_amountController.text) * 1.18).toStringAsFixed(2)}', 
                             style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAmountButton(500),
                _buildQuickAmountButton(1000),
                _buildQuickAmountButton(2000),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum: ₹100 • GST @18% applicable',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _amountController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _initiatePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(int amount) {
    return OutlinedButton(
      onPressed: () {
        _amountController.text = amount.toString();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text('₹$amount'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'My Wallet',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Wallet Balance Card
            StreamBuilder<double>(
              stream: Stream.periodic(const Duration(seconds: 1)).asyncMap(
                  (_) => _walletService.getWalletBalance(widget.technicianId)),
              builder: (context, snapshot) {
                double balance = snapshot.data ?? 0.0;
                double minReserve = 1000.0;
                double withdrawable = (balance - minReserve).clamp(0, double.infinity);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Wallet Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${balance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Minimum Reserve',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '₹${minReserve.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Locked',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
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
                                  'Withdrawable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '₹${withdrawable.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement withdraw
                      },
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showRechargeDialog,
                      icon: const Icon(Icons.trending_up, size: 20),
                      label: const Text('Recharge'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Transaction History
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<WalletTransaction>>(
                        stream: _walletService
                            .getTransactionHistory(widget.technicianId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No transactions yet'),
                            );
                          }

                          List<WalletTransaction> transactions =
                              snapshot.data!;

                          return ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              WalletTransaction transaction =
                                  transactions[index];
                              bool isCredit = transaction.type == 'credit';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCredit
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isCredit
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isCredit
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction.description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a')
                                                .format(transaction.timestamp),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isCredit
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bal: ₹${transaction.balanceAfter.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}