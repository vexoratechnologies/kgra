const express = require('express');
const cors = require('cors');
const functions = require('firebase-functions');
require('dotenv').config();

const paymentRoutes = require('./routes/payment.routes');

const app = express();
const PORT = process.env.PORT || 5001;

// Middlewares
app.use(cors({ origin: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check
const healthHandler = (req, res) => {
  res.status(200).json({
    status: 'OK',
    service: 'KGRA Payment API',
    timestamp: new Date().toISOString(),
  });
};
app.get('/health', healthHandler);
app.get('/api/health', healthHandler);

// Mount payment routes under both /api/payment and /payment
app.use('/api/payment', paymentRoutes);
app.use('/payment', paymentRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'API route not found',
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: err.message,
  });
});

// Start local listener only if run directly (e.g. node src/server.js)
if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 [KGRA Payment Backend] Running on http://localhost:${PORT} (0.0.0.0)`);
    console.log(`💳 [Razorpay Integration] Key ID: ${process.env.RAZORPAY_KEY_ID ? 'Loaded' : 'Missing'}`);
  });
}

// Export for Firebase Cloud Functions
exports.api = functions.https.onRequest(app);
