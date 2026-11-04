const express = require('express');
const crypto = require('crypto');
const { razorpayInstance, keyId, keySecret, getRazorpayConfig, getRazorpayInstance } = require('../config/razorpay');
const { db, admin } = require('../config/firebase');

const router = express.Router();

// Collections in CAPITAL CASE as requested
const COLLECTION_ATTEMPTS = 'PAYMENT_ATTEMPTS';
const COLLECTION_PAYMENTS = 'PAYMENTS';
const COLLECTION_CONFIG = 'CONFIG';

/**
 * Helper to calculate current Financial Year (e.g., "2026-2027")
 */
function getFinancialYear() {
  const today = new Date();
  const year = today.getFullYear();
  const month = today.getMonth() + 1; // 1-12
  if (month >= 4) {
    return `${year}-${year + 1}`;
  } else {
    return `${year - 1}-${year}`;
  }
}

/**
 * Helper to generate official human-readable receipt number
 */
function generateReceiptNumber() {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = Math.floor(1000 + Math.random() * 9000);
  return `KGRA/REC/${dateStr}/${rand}`;
}

/**
 * GET /api/payment/config
 * Returns public Razorpay key and remote switch configuration
 */
router.get('/config', async (req, res) => {
  try {
    const razorConfig = await getRazorpayConfig();

    let paymentConfig = {
      isPaymentGloballyEnabled: true,
      isIosPaymentEnabled: false, // Default false on iOS during review bypass
      isAndroidPaymentEnabled: true,
      disabledIosVersions: ['1.0.5'],
      razorpayKeyId: razorConfig.keyId,
      amount: razorConfig.amount,
      annualMembershipAmount: razorConfig.amount,
      membershipFee: razorConfig.amount,
      membershipTitle: razorConfig.title,
      membershipDescription: razorConfig.description,
      membershipPurpose: razorConfig.purpose,
    };

    if (db) {
      try {
        const doc = await db.collection(COLLECTION_CONFIG).doc('PAYMENT_CONFIG').get();
        if (doc.exists) {
          paymentConfig = { ...paymentConfig, ...doc.data(), razorpayKeyId: razorConfig.keyId };
        }
      } catch (dbErr) {
        console.warn('ℹ️ [Firestore Admin] Default payment config fallback:', dbErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      data: paymentConfig,
    });
  } catch (error) {
    console.error('Error fetching config:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch payment configuration',
      error: error.message,
    });
  }
});

/**
 * POST /api/payment/create-order
 * Creates a Razorpay Order and logs a rich entry to the PAYMENT_ATTEMPTS collection
 */
router.post('/create-order', async (req, res) => {
  try {
    const razorConfig = await getRazorpayConfig();

    const {
      amount,
      currency = 'INR',
      userId,
      userName,
      userPhone,
      userEmail,
      membershipId,
      designation,
      institution,
      zone,
      purpose = razorConfig.purpose || 'ANNUAL_MEMBERSHIP_FEE',
      platform = 'ANDROID',
      notes = {},
    } = req.body;

    const finalAmount = (amount !== undefined && amount !== null && !isNaN(amount) && Number(amount) > 0)
      ? Number(amount)
      : razorConfig.amount;

    if (!finalAmount || isNaN(finalAmount) || Number(finalAmount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount. Amount must be a positive number.',
      });
    }

    // Razorpay requires amount in paise (1 INR = 100 paise)
    const amountInPaise = Math.round(Number(finalAmount) * 100);
    const receipt = `kgra_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    const options = {
      amount: amountInPaise,
      currency: currency.toUpperCase(),
      receipt: receipt,
      notes: {
        userId: userId || 'anonymous',
        userName: userName || '',
        userPhone: userPhone || '',
        membershipId: membershipId || '',
        purpose: purpose,
        platform: platform,
        ...notes,
      },
    };

    // Create Razorpay Order
    const instance = getRazorpayInstance();
    const order = await instance.orders.create(options);

    // Save initial record to PAYMENT_ATTEMPTS collection (CAPITAL CASE)
    if (db) {
      try {
        const attemptRef = db.collection(COLLECTION_ATTEMPTS).doc(order.id);
        await attemptRef.set({
          attemptId: order.id,
          orderId: order.id,
          receipt: receipt,
          userId: userId || null,
          userName: userName || null,
          userPhone: userPhone || null,
          userEmail: userEmail || null,
          membershipId: membershipId || null,
          designation: designation || null,
          institution: institution || null,
          zone: zone || null,
          amount: Number(finalAmount),
          amountInPaise: amountInPaise,
          currency: currency.toUpperCase(),
          status: 'INITIATED',
          purpose: purpose,
          financialYear: getFinancialYear(),
          platform: platform,
          createdAt: admin?.firestore?.FieldValue?.serverTimestamp() || new Date(),
          updatedAt: admin?.firestore?.FieldValue?.serverTimestamp() || new Date(),
        });
      } catch (dbErr) {
        console.warn('Could not write attempt to Firestore:', dbErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Razorpay order created successfully',
      data: {
        orderId: order.id,
        amount: Number(finalAmount),
        amountInPaise: amountInPaise,
        currency: order.currency,
        keyId: razorConfig.keyId,
        receipt: receipt,
        purpose: purpose,
      },
    });
  } catch (error) {
    console.error('Error creating Razorpay order:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create payment order',
      error: error.message,
    });
  }
});

/**
 * POST /api/payment/verify
 * Verifies Razorpay HMAC SHA-256 signature, enriches payment data from Razorpay API,
 * logs comprehensive record to PAYMENTS, and updates PAYMENT_ATTEMPTS
 */
router.post('/verify', async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      userId,
      userName,
      userPhone,
      userEmail,
      membershipId,
      designation,
      institution,
      zone,
      amount,
      purpose = 'ANNUAL_MEMBERSHIP_FEE',
      platform = 'ANDROID',
    } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        success: false,
        message: 'Missing required verification fields (order_id, payment_id, signature).',
      });
    }

    const razorConfig = await getRazorpayConfig();
    const activeKeySecret = razorConfig.keySecret || keySecret;

    // Generate expected signature
    const hmac = crypto.createHmac('sha256', activeKeySecret);
    hmac.update(`${razorpay_order_id}|${razorpay_payment_id}`);
    const generatedSignature = hmac.digest('hex');

    const isSignatureValid = generatedSignature === razorpay_signature;

    if (!isSignatureValid) {
      // Update attempt as FAILED
      if (db) {
        try {
          await db.collection(COLLECTION_ATTEMPTS).doc(razorpay_order_id).update({
            status: 'FAILED',
            failureReason: 'Signature mismatch',
            paymentId: razorpay_payment_id,
            updatedAt: admin?.firestore?.FieldValue?.serverTimestamp() || new Date(),
          });
        } catch (_) {}
      }

      return res.status(400).json({
        success: false,
        message: 'Payment verification failed: Invalid signature.',
      });
    }

    // Fetch authoritative payment details from Razorpay API
    let rzpPayment = null;
    try {
      rzpPayment = await razorpayInstance.payments.fetch(razorpay_payment_id);
    } catch (fetchErr) {
      console.warn('Could not fetch payment from Razorpay API:', fetchErr.message);
    }

    const now = new Date();
    const isLifeMembership = purpose === 'LIFE_MEMBERSHIP_FEE';
    const validUntil = isLifeMembership
      ? null
      : new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000); // 1 year from now

    const officialReceiptNumber = generateReceiptNumber();
    const financialYear = getFinancialYear();

    // Comprehensive record stored in PAYMENTS (CAPITAL CASE)
    const paymentRecord = {
      // 1. Transaction Identifiers
      paymentId: razorpay_payment_id,
      orderId: razorpay_order_id,
      receiptNumber: officialReceiptNumber,
      signature: razorpay_signature,

      // 2. Member & User Details
      userId: userId || null,
      userName: userName || rzpPayment?.notes?.userName || null,
      userPhone: userPhone || rzpPayment?.contact || null,
      userEmail: userEmail || rzpPayment?.email || null,
      membershipId: membershipId || rzpPayment?.notes?.membershipId || null,
      designation: designation || null,
      institution: institution || null,
      zone: zone || null,

      // 3. Financial Information
      amount: amount ? Number(amount) : (rzpPayment ? rzpPayment.amount / 100 : 0),
      amountInPaise: rzpPayment?.amount || (amount ? Math.round(Number(amount) * 100) : 0),
      currency: rzpPayment?.currency || 'INR',
      fee: rzpPayment?.fee ? rzpPayment.fee / 100 : 0,
      tax: rzpPayment?.tax ? rzpPayment.tax / 100 : 0,

      // 4. Payment Gateway & Method Details
      paymentMethod: rzpPayment?.method || 'ONLINE', // e.g. 'upi', 'card', 'netbanking'
      vpa: rzpPayment?.vpa || null, // UPI ID (e.g. name@okhdfcbank)
      bank: rzpPayment?.bank || null,
      wallet: rzpPayment?.wallet || null,
      cardDetails: rzpPayment?.card ? {
        last4: rzpPayment.card.last4,
        network: rzpPayment.card.network,
        type: rzpPayment.card.type,
        issuer: rzpPayment.card.issuer,
      } : null,

      // 5. Purpose & Association Metadata
      associationName: 'Kerala Govt Radiographers Association',
      purpose: purpose,
      purposeLabel: purpose === 'ANNUAL_MEMBERSHIP_FEE'
          ? 'Annual Membership Subscription'
          : purpose === 'LIFE_MEMBERSHIP_FEE'
          ? 'Life Membership Subscription'
          : 'KGRA Welfare Fund Contribution',
      financialYear: financialYear,
      membershipType: isLifeMembership ? 'LIFE' : 'ANNUAL',
      membershipValidFrom: now.toISOString(),
      membershipValidUntil: validUntil ? validUntil.toISOString() : 'LIFETIME',

      // 6. Platform & Audit Details
      platform: platform,
      status: 'SUCCESS',
      paidAt: admin?.firestore?.FieldValue?.serverTimestamp() || now,
      verifiedAt: admin?.firestore?.FieldValue?.serverTimestamp() || now,
      createdAt: admin?.firestore?.FieldValue?.serverTimestamp() || now,
    };

    if (db) {
      try {
        const batch = db.batch();

        // 1. Update PAYMENT_ATTEMPTS
        const attemptRef = db.collection(COLLECTION_ATTEMPTS).doc(razorpay_order_id);
        batch.update(attemptRef, {
          status: 'SUCCESS',
          paymentId: razorpay_payment_id,
          receiptNumber: officialReceiptNumber,
          signature: razorpay_signature,
          paymentMethod: paymentRecord.paymentMethod,
          updatedAt: admin?.firestore?.FieldValue?.serverTimestamp() || now,
        });

        // 2. Save detailed verified transaction to PAYMENTS (CAPITAL CASE)
        const paymentRef = db.collection(COLLECTION_PAYMENTS).doc(razorpay_payment_id);
        batch.set(paymentRef, paymentRecord);

        // 3. Update USERS collection if userId provided
        if (userId) {
          const userRef = db.collection('USERS').doc(userId);
          const userUpdates = {
            isMemberPaid: true,
            membershipType: isLifeMembership ? 'LIFE' : 'ANNUAL',
            membershipValidUntil: validUntil ? admin.firestore.Timestamp.fromDate(validUntil) : 'LIFETIME',
            lastPaymentId: razorpay_payment_id,
            lastReceiptNumber: officialReceiptNumber,
            lastPaymentAmount: paymentRecord.amount,
            lastPaymentDate: admin?.firestore?.FieldValue?.serverTimestamp() || now,
          };
          batch.set(userRef, userUpdates, { merge: true });
        }

        await batch.commit();
        console.log(`✅ [PAYMENTS] Saved rich transaction: ${razorpay_payment_id} for user: ${userId}`);
      } catch (dbErr) {
        console.warn('Firestore update error during verification:', dbErr.message);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Payment verified and recorded successfully with complete details.',
      data: paymentRecord,
    });
  } catch (error) {
    console.error('Error verifying payment:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error during payment verification',
      error: error.message,
    });
  }
});

/**
 * GET /api/payment/checkout-page/:orderId
 * Serves an HTML page with Razorpay Standard Web Checkout
 */
router.get('/checkout-page/:orderId', async (req, res) => {
  const { orderId } = req.params;
  const { amount = 500, name = 'KGRA Member', phone = '', email = '', purpose = 'Membership Fee' } = req.query;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>KGRA Payment Checkout</title>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #F8FAFC;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      padding: 16px;
    }
    .card {
      background: white;
      border-radius: 16px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.08);
      max-width: 420px;
      width: 100%;
      padding: 28px;
      text-align: center;
    }
    h2 { color: #7F0010; margin-top: 0; }
    .amount { font-size: 36px; font-weight: bold; color: #1E293B; margin: 16px 0; }
    .btn {
      background: #7F0010;
      color: white;
      border: none;
      padding: 14px 28px;
      font-size: 16px;
      font-weight: 600;
      border-radius: 10px;
      cursor: pointer;
      width: 100%;
    }
    .btn:hover { background: #5a000b; }
  </style>
</head>
<body>
  <div class="card">
    <h2>Kerala Govt Radiographers Association</h2>
    <p style="color: #64748B;">${purpose}</p>
    <div class="amount">₹${amount}</div>
    <button id="rzp-button" class="btn">Proceed to Pay with Razorpay</button>
  </div>

  <script>
    const options = {
      key: "${keyId}",
      amount: ${Number(amount) * 100},
      currency: "INR",
      name: "KGRA",
      description: "${purpose}",
      order_id: "${orderId}",
      prefill: {
        name: "${name}",
        email: "${email}",
        contact: "${phone}"
      },
      theme: {
        color: "#7F0010"
      },
      handler: function (response) {
        fetch('/api/payment/verify', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            razorpay_order_id: response.razorpay_order_id,
            razorpay_payment_id: response.razorpay_payment_id,
            razorpay_signature: response.razorpay_signature,
            amount: ${amount},
            purpose: "${purpose}"
          })
        }).then(res => res.json())
          .then(data => {
            alert('Payment Successful! Receipt: ' + (data.data?.receiptNumber || response.razorpay_payment_id));
            if (window.FlutterChannel) {
              window.FlutterChannel.postMessage(JSON.stringify(response));
            }
          }).catch(err => {
            alert('Verification error: ' + err.message);
          });
      }
    };

    const rzp = new Razorpay(options);
    document.getElementById('rzp-button').onclick = function(e){
      rzp.open();
      e.preventDefault();
    };

    window.onload = function() {
      rzp.open();
    };
  </script>
</body>
</html>
  `;

  res.send(html);
});

module.exports = router;
