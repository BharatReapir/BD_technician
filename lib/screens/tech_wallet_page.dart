import '../constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../services/tech_payment_service.dart';
import '../providers/auth_provider.dart';
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
  late Stream<double> _balanceStream;

  // REPLACE WITH YOUR ACTUAL RAZORPAY KEY
  static const String RAZORPAY_KEY = 'rzp_test_S4yQ9pfJFZGHEV';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Refresh every 5 seconds avoids rebuilding stream on every frame
    _balanceStream = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => _walletService.getWalletBalance(widget.technicianId));

    debugPrint('Technician ID: ${widget.technicianId}');
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  // Payment Handlers 

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Signature: ${response.signature}');

    setState(() => _isLoading = true);

    try {
      await TechPaymentService.verifyWalletPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        technicianId: widget.technicianId,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet recharged successfully!'),
            backgroundColor: Color(0xFF1E286D),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Failed: ${response.code} - ${response.message}');
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: Colors.red,
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

  // ─── Payment Flow ────────────────────────────────────────────────────────────

  Future<void> _initiatePayment(StateSetter? setDialogState) async {
    final amountText = _amountController.text.trim();

    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      _showError('Invalid amount entered');
      return;
    }

    if (amount < 100) {
      _showError('Minimum recharge amount is ₹100');
      return;
    }

    setState(() => _isLoading = true);
    if (setDialogState != null) {
        setDialogState(() => _isLoading = true);
    }

    try {
      final rechargeCalculation = PricingCalculator.calculateWalletRecharge(amount);
      final totalAmount = rechargeCalculation['totalAmount']!;
      final gstAmount = rechargeCalculation['gstAmount']!;

      debugPrint('Amount: Rs $amount | GST: Rs $gstAmount | Total: Rs $totalAmount');

      final orderData = await TechPaymentService.createWalletRechargeOrder(
        technicianId: widget.technicianId,
        amount: totalAmount,
      );

      debugPrint('Order data: $orderData');

      if (!orderData.containsKey('orderId') || orderData['orderId'] == null) {
        throw Exception('Order ID not received from server');
      }

      final tech = context.read<AuthProvider>().technician;

      final options = {
        'key': RAZORPAY_KEY,
        'amount': (totalAmount * 100).toInt(),
        'order_id': orderData['orderId'],
        'name': 'Wallet Recharge',
        'description': 'Recharge ₹$amount + GST ₹${gstAmount.toStringAsFixed(2)}',
        'prefill': {
          'contact': tech?.mobile ?? '',
          'email': tech?.email ?? '',
        },
        'theme': {'color': '#1E286D'},
        'notes': {
          'recharge_amount': amount.toString(),
          'gst_amount': gstAmount.toString(),
          'total_amount': totalAmount.toString(),
        },
      };

      if (mounted && setDialogState != null) {
        Navigator.pop(context); // close dialog
      }

      _razorpay.open(options);
      _amountController.clear();
      setState(() => _isLoading = false);
      if (setDialogState != null) {
          setDialogState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error in _initiatePayment: $e');
      setState(() => _isLoading = false);
      if (setDialogState != null) {
          setDialogState(() => _isLoading = false);
      }
      _showError('Failed to create order: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF1E286D),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ─── Recharge Dialog ─────────────────────────────────────────────────────────

  void _showRechargeDialog() {
    _amountController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final text = _amountController.text;
          final parsedAmount = double.tryParse(text);
          final hasValidAmount = text.isNotEmpty && parsedAmount != null;

          return AlertDialog(
            title: const Text(
              'Recharge Wallet',
              style: TextStyle(color: Color(0xFF1E286D), fontWeight: FontWeight.bold),
            ),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Enter amount',
                    helperText: 'GST @18% will be added',
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 16),

                // GST Breakdown
                if (hasValidAmount)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _breakdownRow('Amount:', '₹$text'),
                        const SizedBox(height: 4),
                        _breakdownRow(
                          'GST (18%):',
                          '₹${(parsedAmount! * 0.18).toStringAsFixed(2)}',
                        ),
                        const Divider(height: 16),
                        _breakdownRow(
                          'Total Payable:',
                          '₹${(parsedAmount * 1.18).toStringAsFixed(2)}',
                          bold: true,
                          valueColor: const Color(0xFFFF6D00),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickBtn(500, setDialogState),
                    _quickBtn(1000, setDialogState),
                    _quickBtn(2000, setDialogState),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Min: ₹100 • GST @18%',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _initiatePayment(setDialogState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _breakdownRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _quickBtn(int amount, StateSetter setDialogState) {
    return OutlinedButton(
      onPressed: () => setDialogState(() {
        _amountController.text = amount.toString();
      }),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: Color(0xFF1E286D)),
        foregroundColor: const Color(0xFF1E286D),
      ),
      child: Text('₹$amount'),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1E286D), size: 20),
                  ),
                  const Text(
                    'My Wallet',
                    style: TextStyle(
                      color: Color(0xFF1E286D),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Balance Card
            StreamBuilder<double>(
              stream: _balanceStream,
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                const minReserve = 1000.0;
                final withdrawable = (balance - minReserve).clamp(0.0, double.infinity);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E286D), Color(0xFF2D3B8D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E286D).withOpacity(0.3),
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
                        style: TextStyle(fontSize: 14, color: Colors.white70),
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
                            child: _balanceInfoColumn(
                              label: 'Minimum Reserve',
                              value: '₹${minReserve.toStringAsFixed(0)}',
                              badge: 'Locked',
                              badgeColor: const Color(0xFFFF6D00).withOpacity(0.35),
                            ),
                          ),
                          Expanded(
                            child: _balanceInfoColumn(
                              label: 'Withdrawable',
                              value: '₹${withdrawable.toStringAsFixed(0)}',
                              badge: 'Available',
                              badgeColor: Colors.green.withOpacity(0.35),
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
                        backgroundColor: const Color(0xFF1E286D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        foregroundColor: const Color(0xFFFF6D00),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Earnings Summary Removed

            const SizedBox(height: 20),

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
                      padding: EdgeInsets.all(20),
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
                        stream: _walletService.getTransactionHistory(widget.technicianId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No transactions yet'));
                          }

                          final transactions = snapshot.data!;

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              final isCredit = tx.type == 'credit';

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
                                        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isCredit ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isCredit ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Bal: ₹${tx.balanceAfter.toStringAsFixed(0)}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _balanceInfoColumn({
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}