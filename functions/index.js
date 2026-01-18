
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');

admin.initializeApp();

// 🔐 Razorpay Credentials (NEVER expose these on frontend)
const razorpay = new Razorpay({
  key_id: 'rzp_test_S4yQ9pfJFZGHEV',
  key_secret: 'EsC4rFfueWpQPCIadNlR7kKR', // ⚠️ KEEP THIS SECRET!
});

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

// ==================== VERIFY PAYMENT ====================
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

// ==================== GET PAYMENT DETAILS (Optional) ====================
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