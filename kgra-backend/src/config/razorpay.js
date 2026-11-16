const Razorpay = require('razorpay');
require('dotenv').config();
const { rtdb } = require('./firebase');

// Default / fallback configuration
const defaultConfig = {
  keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_TfREKwuczLH0HV',
  keySecret: process.env.RAZORPAY_KEY_SECRET || '6PRLktauO7P5CC0eO9q7EYlH',
  amount: 1500.0,
  purpose: 'ANNUAL_MEMBERSHIP_FEE',
  title: 'Annual Membership',
  description: 'Standard annual association subscription for 12 months.',
};

let activeConfig = { ...defaultConfig };
let activeRazorpayInstance = new Razorpay({
  key_id: activeConfig.keyId,
  key_secret: activeConfig.keySecret,
});

function applyRtdbData(data) {
  if (!data || typeof data !== 'object') return;
  const source = (data['0'] && typeof data['0'] === 'object') ? data['0'] : data;
  const target = (source.payment_config && typeof source.payment_config === 'object')
    ? source.payment_config
    : (data.payment_config && typeof data.payment_config === 'object')
      ? data.payment_config
      : source;

  const newKeyId = target.RAZORPAY_KEY_ID ||
    target.razorpay_key_id ||
    target.razorpayKeyId ||
    source.RAZORPAY_KEY_ID ||
    data.RAZORPAY_KEY_ID ||
    activeConfig.keyId;

  const newKeySecret = target.RAZORPAY_KEY_SECRET ||
    target.razorpay_key_secret ||
    target.razorpayKeySecret ||
    source.RAZORPAY_KEY_SECRET ||
    data.RAZORPAY_KEY_SECRET ||
    activeConfig.keySecret;

  const rawAmount = target.ANNUAL_MEMBERSHIP_AMOUNT ??
    target.annual_membership_amount ??
    target.annualMembershipAmount ??
    target.MEMBERSHIP_AMOUNT ??
    target.membership_amount ??
    target.MEMBERSHIP_FEE ??
    target.membership_fee ??
    target.AMOUNT ??
    target.amount ??
    target.ANNUAL_MEMBERSHIP_FEE ??
    source.ANNUAL_MEMBERSHIP_AMOUNT ??
    data.ANNUAL_MEMBERSHIP_AMOUNT ??
    data.amount;

  const parsedAmount = rawAmount !== undefined && rawAmount !== null && !isNaN(Number(rawAmount))
    ? Number(rawAmount)
    : activeConfig.amount;

  const newTitle = target.MEMBERSHIP_TITLE ||
    target.membership_title ||
    target.title ||
    source.MEMBERSHIP_TITLE ||
    data.MEMBERSHIP_TITLE ||
    activeConfig.title;

  const newDescription = target.MEMBERSHIP_DESCRIPTION ||
    target.membership_description ||
    target.description ||
    source.MEMBERSHIP_DESCRIPTION ||
    data.MEMBERSHIP_DESCRIPTION ||
    activeConfig.description;

  const newPurpose = target.MEMBERSHIP_PURPOSE ||
    target.membership_purpose ||
    target.purpose ||
    source.MEMBERSHIP_PURPOSE ||
    data.MEMBERSHIP_PURPOSE ||
    activeConfig.purpose;

  const keysChanged = newKeyId !== activeConfig.keyId || newKeySecret !== activeConfig.keySecret;

  activeConfig = {
    keyId: newKeyId,
    keySecret: newKeySecret,
    amount: parsedAmount,
    title: newTitle,
    description: newDescription,
    purpose: newPurpose,
  };

  if (keysChanged) {
    console.log(`💳 [Razorpay] Keys updated dynamically from RTDB. Key ID: ${newKeyId.substring(0, 10)}...`);
    activeRazorpayInstance = new Razorpay({
      key_id: activeConfig.keyId,
      key_secret: activeConfig.keySecret,
    });
  }
}

// Subscribe to Realtime Database (supporting both root and node '0')
if (rtdb) {
  try {
    const configRef = rtdb.ref();

    // Real-time listener
    configRef.on('value', (snapshot) => {
      if (snapshot.exists()) {
        applyRtdbData(snapshot.val());
      }
    }, (err) => {
      console.warn('⚠️ [Realtime DB] Listener error for Razorpay config:', err.message);
    });

    // Seed default keys if missing in node '0'
    configRef.once('value').then((snapshot) => {
      const data = snapshot.exists() ? snapshot.val() : {};
      const updates = {};
      if (!data.RAZORPAY_KEY_ID && !data.razorpay_key_id) {
        updates.RAZORPAY_KEY_ID = activeConfig.keyId;
      }
      if (!data.RAZORPAY_KEY_SECRET && !data.razorpay_key_secret) {
        updates.RAZORPAY_KEY_SECRET = activeConfig.keySecret;
      }
      if (!data.MEMBERSHIP_TITLE && !data.title) {
        updates.MEMBERSHIP_TITLE = activeConfig.title;
      }
      if (!data.MEMBERSHIP_DESCRIPTION && !data.description) {
        updates.MEMBERSHIP_DESCRIPTION = activeConfig.description;
      }
      if (!data.MEMBERSHIP_PURPOSE && !data.purpose) {
        updates.MEMBERSHIP_PURPOSE = activeConfig.purpose;
      }

      if (Object.keys(updates).length > 0) {
        configRef.update(updates).then(() => {
          console.log('✅ [Realtime DB] Verified and synced Razorpay keys & membership amount to node "0"');
        }).catch((upErr) => {
          console.warn('ℹ️ [Realtime DB] Update notice:', upErr.message);
        });
      }
    }).catch((e) => {
      console.warn('ℹ️ [Realtime DB] Read notice:', e.message);
    });
  } catch (err) {
    console.warn('⚠️ [Realtime DB] Initialization notice:', err.message);
  }
}

/**
 * Returns the current active configuration, refreshing from Realtime Database if possible.
 * Uses a safe timeout so requests are never blocked if network/RTDB is slow.
 */
async function getRazorpayConfig(timeoutMs = 2000) {
  if (rtdb) {
    try {
      const fetchPromise = rtdb.ref().once('value').then((snap) => {
        if (snap.exists()) {
          applyRtdbData(snap.val());
        }
      });
      const timeoutPromise = new Promise((resolve) => setTimeout(resolve, timeoutMs));
      await Promise.race([fetchPromise, timeoutPromise]);
    } catch (_) {}
  }
  return activeConfig;
}

function getRazorpayInstance() {
  return activeRazorpayInstance;
}

module.exports = {
  get razorpayInstance() {
    return activeRazorpayInstance;
  },
  get keyId() {
    return activeConfig.keyId;
  },
  get keySecret() {
    return activeConfig.keySecret;
  },
  getRazorpayConfig,
  getRazorpayInstance,
};
