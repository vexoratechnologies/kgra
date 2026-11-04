const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

let db = null;
let rtdb = null;

try {
  const serviceAccountPath = path.resolve(__dirname, '../../serviceAccountKey.json');
  const databaseURL = process.env.FIREBASE_DATABASE_URL || 'https://kgra-ba502-default-rtdb.firebaseio.com';
  const projectId = process.env.PROJECT_ID || process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || 'kgra-ba502';

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
      databaseURL,
    });
    console.log('✅ [Firebase Admin] Initialized with serviceAccountKey.json');
  } else {
    admin.initializeApp({
      projectId,
      databaseURL,
    });
    console.log(`ℹ️ [Firebase Admin] Initialized with Project ID: ${projectId}, RTDB: ${databaseURL}`);
  }
  db = admin.firestore();
  try {
    rtdb = admin.database();
    console.log('✅ [Firebase Realtime Database] Initialized successfully');
  } catch (rtdbErr) {
    console.warn('⚠️ [Firebase Realtime Database] Initialization notice:', rtdbErr.message);
  }
} catch (error) {
  console.warn('⚠️ [Firebase Admin] Initialization notice (Firestore writes from server may be mocked/deferred):', error.message);
}

module.exports = {
  admin,
  db,
  rtdb,
};
