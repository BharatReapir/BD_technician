const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');

admin.initializeApp();

// 🔐 Razorpay Credentials
const razorpay = new Razorpay({
  key_id: 'rzp_test_S4yQ9pfJFZGHEV',
  key_secret: 'EsC4rFfueWpQPCIadNlR7kKR',
});

// ==================== USER BOOKING PAYMENT ====================
exports.createRazorpayOrder = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { bookingId, serviceCharge, area, userId } = req.body;

    if (!bookingId || !serviceCharge || !area || !userId) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    const VISITING_CHARGES = {
      standard: 299,
      premium: 399,
    };

    const GST_RATE = 0.18;

    const visitingCharge = VISITING_CHARGES[area] || 299;
    const taxableAmount = serviceCharge + visitingCharge;
    const gstAmount = parseFloat((taxableAmount * GST_RATE).toFixed(2));
    const totalAmount = parseFloat((taxableAmount + gstAmount).toFixed(2));
    const amountInPaise = Math.round(totalAmount * 100);

    console.log('💰 Payment Calculation:');
    console.log(`Service Charge: ₹${serviceCharge}`);
    console.log(`Visiting Charge: ₹${visitingCharge}`);
    console.log(`Taxable Amount: ₹${taxableAmount}`);
    console.log(`GST @18%: ₹${gstAmount}`);
    console.log(`Total Amount: ₹${totalAmount}`);

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

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      res.status(400).json({ error: 'Missing payment details' });
      return;
    }

    const generatedSignature = crypto
      .createHmac('sha256', razorpay.key_secret)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    console.log('🔐 Signature Verification:');
    console.log(`Expected: ${generatedSignature}`);
    console.log(`Received: ${razorpay_signature}`);

    if (generatedSignature !== razorpay_signature) {
      console.error('❌ Signature mismatch!');
      res.status(400).json({
        error: 'Invalid signature',
        verified: false,
      });
      return;
    }

    console.log('✅ Payment signature verified successfully');

    const payment = await razorpay.payments.fetch(razorpay_payment_id);

    console.log('💳 Payment Details:', {
      id: payment.id,
      amount: payment.amount,
      status: payment.status,
      method: payment.method,
    });

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
      amount: payment.amount / 100,
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
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { technicianId, amount } = req.body;
const amountNumber = Number(amount);

if (!technicianId || isNaN(amountNumber) || amountNumber < 100) {
  res.status(400).json({ error: 'Invalid technicianId or amount' });
  return;
}


    console.log('📥 Creating wallet recharge order:', {technicianId, amount});

    if (!technicianId || !amount) {
      res.status(400).json({error: 'Missing required fields'});
      return;
    }

    if (amount < 100) {
      res.status(400).json({error: 'Minimum recharge amount is ₹100'});
      return;
    }

    const options = {
  amount: Math.round(amountNumber * 100),
  currency: 'INR',
  payment_capture: 1,
  receipt: `w_${technicianId.slice(0, 10)}_${Date.now().toString().slice(-6)}`,
  notes: {
    technicianId,
    type: 'wallet_recharge',
  },
};


    let order;
try {
  order = await razorpay.orders.create(options);
} catch (err) {
  console.error('❌ Razorpay wallet order failed:', err);
  res.status(500).json({
    error: 'Razorpay order creation failed',
    details: err.message || err,
  });
  return;
}


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

    const payment = await razorpay.payments.fetch(razorpay_payment_id);

    if (payment.status !== 'captured') {
      res.status(400).json({error: 'Payment not captured'});
      return;
    }

    const amount = payment.amount / 100;

    const techRef = admin.database()
        .ref(`technicians/${technicianId}`);
    const snapshot = await techRef.child('walletBalance').get();

    const currentBalance = snapshot.exists() ? snapshot.val() : 0;
    const newBalance = currentBalance + amount;

    await techRef.update({
      walletBalance: newBalance,
      updatedAt: Date.now(),
    });

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

// ==================== ✅ NEW: COIN SYSTEM ====================

// 🪙 Credit coins when booking is completed
exports.onBookingCompleted = functions.database
  .ref('/bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    const bookingId = context.params.bookingId;

    // Check if status changed to 'completed'
    if (before.status !== 'completed' && after.status === 'completed') {
      console.log(`🪙 Booking completed: ${bookingId}`);
      
      const userId = after.userId;

      try {
        // Get user's total completed bookings
        const bookingsSnapshot = await admin.database()
          .ref('bookings')
          .orderByChild('userId')
          .equalTo(userId)
          .once('value');

        const bookings = bookingsSnapshot.val() || {};
        const completedBookings = Object.values(bookings)
          .filter(b => b.status === 'completed');
        
        const bookingNumber = completedBookings.length;

        console.log(`📊 User ${userId} has ${bookingNumber} completed bookings`);

        // Determine coins to award
        let coins = 0;
        if (bookingNumber <= 5) {
          // Welcome bonus
          const welcomeCoins = {1: 1000, 2: 1500, 3: 2000, 4: 2500, 5: 3000};
          coins = welcomeCoins[bookingNumber] || 0;
        } else {
          // Regular coins (you can customize based on service value)
          // For now, default to 50 coins
          coins = 50;
        }

        if (coins > 0) {
          await creditCoins(userId, bookingId, coins, bookingNumber);
        }
      } catch (error) {
        console.error(`❌ Error processing coin credit for booking ${bookingId}:`, error);
      }
    }
  });

// 🔄 Reverse coins when booking cancelled before visit
exports.onBookingCancelled = functions.database
  .ref('/bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    const bookingId = context.params.bookingId;

    // Check if booking was cancelled before visit
    if ((after.status === 'cancelled' || after.status === 'cancelled_before_visit') &&
        before.status !== 'cancelled' && before.status !== 'cancelled_before_visit') {
      
      console.log(`🔄 Booking cancelled: ${bookingId}`);
      
      const userId = after.userId;
      
      try {
        await reverseCoins(userId, bookingId);
      } catch (error) {
        console.error(`❌ Error reversing coins for booking ${bookingId}:`, error);
      }
    }
  });

// Helper function: Credit coins
async function creditCoins(userId, bookingId, coins, bookingNumber) {
  const db = admin.database();
  
  // Check if already credited
  const existingTxn = await db.ref(`coins/${userId}/transactions`)
    .orderByChild('bookingId')
    .equalTo(bookingId)
    .once('value');
  
  if (existingTxn.exists()) {
    console.log(`⚠️ Coins already credited for booking ${bookingId}`);
    return;
  }
  
  // Set expiry date (180 days)
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + 180);
  
  // Create transaction
  const transactionRef = db.ref(`coins/${userId}/transactions`).push();
  await transactionRef.set({
    type: 'earned',
    coins: coins,
    value: coins / 100.0,
    description: bookingNumber <= 5 
      ? `Welcome bonus - ${getOrdinal(bookingNumber)} booking`
      : 'Booking completed - earned coins',
    timestamp: new Date().toISOString(),
    bookingId: bookingId,
    isCredit: true,
    expiryDate: expiryDate.toISOString(),
    isExpired: false
  });
  
  // Update balance
  const balanceRef = db.ref(`coins/${userId}/balance`);
  const balanceSnapshot = await balanceRef.once('value');
  const currentCoins = balanceSnapshot.exists() 
    ? balanceSnapshot.val().totalCoins 
    : 0;
  const newBalance = currentCoins + coins;
  
  await balanceRef.set({
    totalCoins: newBalance,
    discountValue: newBalance / 100.0,
    lastUpdated: new Date().toISOString()
  });
  
  console.log(`✅ Credited ${coins} coins to user ${userId}. New balance: ${newBalance}`);
}

// Helper function: Reverse coins
async function reverseCoins(userId, bookingId) {
  const db = admin.database();
  
  // Find the earned transaction
  const txnSnapshot = await db.ref(`coins/${userId}/transactions`)
    .orderByChild('bookingId')
    .equalTo(bookingId)
    .once('value');
  
  if (!txnSnapshot.exists()) {
    console.log(`⚠️ No coins found for booking ${bookingId}`);
    return;
  }
  
  const transactions = txnSnapshot.val();
  const earnedTxnKey = Object.keys(transactions).find(key => 
    transactions[key].type === 'earned' && 
    transactions[key].isCredit === true
  );
  
  if (!earnedTxnKey) {
    console.log(`⚠️ No earned transaction found for booking ${bookingId}`);
    return;
  }
  
  const earnedTxn = transactions[earnedTxnKey];
  const coins = earnedTxn.coins;
  
  // Mark as expired
  await db.ref(`coins/${userId}/transactions/${earnedTxnKey}`).update({
    isExpired: true,
    coins: 0
  });
  
  // Create reversal transaction
  const reversalRef = db.ref(`coins/${userId}/transactions`).push();
  await reversalRef.set({
    type: 'reversed',
    coins: coins,
    value: coins / 100.0,
    description: 'Booking cancelled - coins reversed',
    timestamp: new Date().toISOString(),
    bookingId: bookingId,
    isCredit: false
  });
  
  // Update balance
  const balanceRef = db.ref(`coins/${userId}/balance`);
  const balanceSnapshot = await balanceRef.once('value');
  const currentCoins = balanceSnapshot.val().totalCoins;
  const newBalance = currentCoins - coins;
  
  await balanceRef.set({
    totalCoins: newBalance,
    discountValue: newBalance / 100.0,
    lastUpdated: new Date().toISOString()
  });
  
  console.log(`✅ Reversed ${coins} coins for user ${userId}. New balance: ${newBalance}`);
}

// Helper function: Get ordinal
function getOrdinal(n) {
  if (n >= 11 && n <= 13) return n + 'th';
  switch (n % 10) {
    case 1: return n + 'st';
    case 2: return n + 'nd';
    case 3: return n + 'rd';
    default: return n + 'th';
  }
}

// 🕐 Daily expiry job (run at midnight IST)
exports.expireCoinsDaily = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    console.log('🕐 Running daily coin expiry job...');
    
    const db = admin.database();
    const today = new Date();
    
    // Get all users
    const usersSnapshot = await db.ref('users').once('value');
    const users = usersSnapshot.val() || {};
    
    let totalExpired = 0;
    
    for (const userId of Object.keys(users)) {
      try {
        const expired = await expireUserCoins(userId, today);
        totalExpired += expired;
      } catch (error) {
        console.error(`❌ Error expiring coins for user ${userId}:`, error);
      }
    }
    
    console.log(`✅ Coin expiry job completed. Total coins expired: ${totalExpired}`);
  });

// Helper function: Expire coins for a user
async function expireUserCoins(userId, today) {
  const db = admin.database();
  
  const txnSnapshot = await db.ref(`coins/${userId}/transactions`)
    .orderByChild('isExpired')
    .equalTo(false)
    .once('value');
  
  if (!txnSnapshot.exists()) return 0;
  
  const transactions = txnSnapshot.val();
  let totalExpired = 0;
  
  for (const [txnId, txn] of Object.entries(transactions)) {
    if (txn.isCredit && txn.expiryDate) {
      const expiryDate = new Date(txn.expiryDate);
      
      if (expiryDate <= today && txn.coins > 0) {
        // Mark as expired
        await db.ref(`coins/${userId}/transactions/${txnId}`).update({
          isExpired: true,
          coins: 0
        });
        
        // Create expiry transaction
        const expiryRef = db.ref(`coins/${userId}/transactions`).push();
        await expiryRef.set({
          type: 'expired',
          coins: txn.coins,
          value: txn.coins / 100.0,
          description: 'Coins expired after 180 days',
          timestamp: new Date().toISOString(),
          isCredit: false
        });
        
        totalExpired += txn.coins;
      }
    }
  }
  
  if (totalExpired > 0) {
    // Update balance
    const balanceRef = db.ref(`coins/${userId}/balance`);
    const balanceSnapshot = await balanceRef.once('value');
    const currentCoins = balanceSnapshot.val().totalCoins;
    const newBalance = currentCoins - totalExpired;
    
    await balanceRef.set({
      totalCoins: newBalance,
      discountValue: newBalance / 100.0,
      lastUpdated: new Date().toISOString()
    });
    
    console.log(`✅ Expired ${totalExpired} coins for user ${userId}`);
  }
  
  return totalExpired;
}