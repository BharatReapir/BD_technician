const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');

admin.initializeApp();

// 🔐 Razorpay Credentials (NEVER expose these on frontend)
const razorpay = new Razorpay({
  key_id: 'rzp_test_S4yQ9pfJFZGHEV',
  key_secret: 'EsC4rFfueWpQPCIadNlR7kKR',
});

// ==================== USER BOOKING PAYMENT ====================
exports.createRazorpayOrder = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { bookingId, serviceCharge, area, userId } = req.body;

    // Validation
    if (!bookingId || !serviceCharge || !area || !userId) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    // ✅ BUSINESS RULES (LOCKED - DO NOT MODIFY)
    const VISITING_CHARGES = {
      standard: 299,
      premium: 399,
    };

    const GST_RATE = 0.18; // 18%

    // Calculate amounts
    const visitingCharge = VISITING_CHARGES[area] || 299;
    const taxableAmount = serviceCharge + visitingCharge;
    const gstAmount = parseFloat((taxableAmount * GST_RATE).toFixed(2));
    const totalAmount = parseFloat((taxableAmount + gstAmount).toFixed(2));
    const amountInPaise = Math.round(totalAmount * 100); // Convert to paise

    console.log('💰 Payment Calculation:');
    console.log(`Service Charge: ₹${serviceCharge}`);
    console.log(`Visiting Charge: ₹${visitingCharge}`);
    console.log(`Taxable Amount: ₹${taxableAmount}`);
    console.log(`GST @18%: ₹${gstAmount}`);
    console.log(`Total Amount: ₹${totalAmount}`);
    console.log(`Amount in Paise: ${amountInPaise}`);

    // Create Razorpay Order
    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: 'INR',
      receipt: bookingId,
      notes: {
        bookingId,
        userId,
        serviceCharge,
        visitingCharge,
        gstAmount,
      },
    });

    console.log('✅ Razorpay order created:', order.id);

    // Response
    res.status(200).json({
      orderId: order.id,
      amount: amountInPaise,
      currency: 'INR',
      bookingId,
      breakdown: {
        serviceCharge,
        visitingCharge,
        taxableAmount,
        gstAmount,
        totalAmount,
      },
    });
  } catch (error) {
    console.error('❌ Error creating order:', error);
    res.status(500).json({
      error: 'Failed to create order',
      details: error.message,
    });
  }
});

exports.verifyPayment = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      bookingId,
    } = req.body;

    // Validation
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      res.status(400).json({ error: 'Missing payment details' });
      return;
    }

    // 🔐 CRITICAL SECURITY CHECK: Verify signature
    const generatedSignature = crypto
      .createHmac('sha256', razorpay.key_secret)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    console.log('🔐 Signature Verification:');
    console.log(`Expected: ${generatedSignature}`);
    console.log(`Received: ${razorpay_signature}`);

    if (generatedSignature !== razorpay_signature) {
      console.error('❌ Signature mismatch! Possible fraud attempt.');
      res.status(400).json({
        error: 'Invalid signature',
        verified: false,
      });
      return;
    }

    console.log('✅ Payment signature verified successfully');

    // Fetch payment details from Razorpay
    const payment = await razorpay.payments.fetch(razorpay_payment_id);

    console.log('💳 Payment Details:', {
      id: payment.id,
      amount: payment.amount,
      status: payment.status,
      method: payment.method,
    });

    // Update booking in Firebase
    if (bookingId) {
      await admin.database().ref(`bookings/${bookingId}`).update({
        paymentId: razorpay_payment_id,
        razorpayOrderId: razorpay_order_id,
        paymentStatus: 'completed',
        status: 'paid',
        updatedAt: new Date().toISOString(),
      });
      console.log(`✅ Booking ${bookingId} updated with payment details`);
    }

    res.status(200).json({
      verified: true,
      paymentId: razorpay_payment_id,
      orderId: razorpay_order_id,
      amount: payment.amount / 100, // Convert paise to rupees
      status: payment.status,
      method: payment.method,
    });
  } catch (error) {
    console.error('❌ Error verifying payment:', error);
    res.status(500).json({
      error: 'Payment verification failed',
      details: error.message,
      verified: false,
    });
  }
});

exports.getPaymentDetails = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');

  try {
    const { paymentId } = req.query;

    if (!paymentId) {
      res.status(400).json({ error: 'Payment ID required' });
      return;
    }

    const payment = await razorpay.payments.fetch(paymentId);

    res.status(200).json({
      id: payment.id,
      amount: payment.amount / 100,
      currency: payment.currency,
      status: payment.status,
      method: payment.method,
      email: payment.email,
      contact: payment.contact,
      createdAt: new Date(payment.created_at * 1000).toISOString(),
    });
  } catch (error) {
    console.error('❌ Error fetching payment:', error);
    res.status(500).json({
      error: 'Failed to fetch payment details',
      details: error.message,
    });
  }
});

// ==================== TECHNICIAN WALLET RECHARGE ====================
exports.createWalletRechargeOrder = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {technicianId, amount} = req.body;

    console.log('📥 Creating wallet recharge order:', {technicianId, amount});

    if (!technicianId || !amount) {
      res.status(400).json({error: 'Missing required fields'});
      return;
    }

    if (amount < 100) {
      res.status(400).json({error: 'Minimum recharge amount is ₹100'});
      return;
    }

    // Create Razorpay order
    const options = {
      amount: Math.round(amount * 100), // Amount in paise
      currency: 'INR',
      receipt: `wallet_${technicianId}_${Date.now()}`,
      notes: {
        technicianId: technicianId,
        type: 'wallet_recharge',
      },
    };

    const order = await razorpay.orders.create(options);

    console.log('✅ Razorpay wallet order created:', order.id);

    res.status(200).json({
      orderId: order.id,
      amount: amount,
      currency: 'INR',
      technicianId: technicianId,
    });
  } catch (error) {
    console.error('❌ Error creating wallet order:', error);
    res.status(500).json({error: error.message});
  }
});

exports.verifyWalletPayment = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      technicianId,
    } = req.body;

    console.log('🔐 Verifying wallet payment:', {
      razorpay_order_id,
      razorpay_payment_id,
      technicianId,
    });

    if (!razorpay_order_id || !razorpay_payment_id || 
        !razorpay_signature || !technicianId) {
      res.status(400).json({error: 'Missing required fields'});
      return;
    }

    // 🔒 CRITICAL: Verify signature
    const generatedSignature = crypto
        .createHmac('sha256', razorpay.key_secret)
        .update(`${razorpay_order_id}|${razorpay_payment_id}`)
        .digest('hex');

    if (generatedSignature !== razorpay_signature) {
      console.error('❌ Invalid wallet payment signature');
      res.status(400).json({error: 'Invalid payment signature'});
      return;
    }

    console.log('✅ Wallet payment signature verified');

    // Fetch payment details from Razorpay
    const payment = await razorpay.payments.fetch(razorpay_payment_id);

    if (payment.status !== 'captured') {
      res.status(400).json({error: 'Payment not captured'});
      return;
    }

    const amount = payment.amount / 100; // Convert paise to rupees

    // Get current balance
    const techRef = admin.database()
        .ref(`technicians/${technicianId}`);
    const snapshot = await techRef.child('walletBalance').get();

    const currentBalance = snapshot.exists() ? snapshot.val() : 0;
    const newBalance = currentBalance + amount;

    // Update wallet balance
    await techRef.update({
      walletBalance: newBalance,
      updatedAt: Date.now(),
    });

    // Save transaction
    await admin.database().ref('wallet_transactions').push({
      technicianId: technicianId,
      amount: amount,
      type: 'credit',
      description: 'Wallet recharge via Razorpay',
      balanceAfter: newBalance,
      timestamp: Date.now(),
      paymentId: razorpay_payment_id,
      orderId: razorpay_order_id,
    });

    console.log(`✅ Wallet updated: ${currentBalance} → ${newBalance}`);

    res.status(200).json({
      success: true,
      message: 'Payment verified and wallet updated',
      newBalance: newBalance,
      amountAdded: amount,
    });
  } catch (error) {
    console.error('❌ Error verifying wallet payment:', error);
    res.status(500).json({error: error.message});
  }
});