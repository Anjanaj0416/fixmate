// functions/index.js
// Firebase Cloud Functions for FixMate

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to create a worker account
 * This uses Firebase Admin SDK which doesn't affect the client's auth state
 *
 * @param {object} data - Contains email, password, workerData, userData
 * @param {object} context - Firebase auth context
 * @return {object} Success response with worker details
 */
exports.createWorkerAccount = functions.https.onCall(async (data, context) => {
  // Verify the request is from an authenticated user (customer)
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to create worker accounts",
    );
  }

  const {email, password, workerData, userData} = data;

  // Validate input
  if (!email || !password) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and password are required",
    );
  }

  if (!workerData || !userData) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Worker data and user data are required",
    );
  }

  try {
    console.log("Creating worker account for:", email);

    // Check if user already exists
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
      console.log("Worker account already exists:", userRecord.uid);

      // Return existing worker info
      const existingWorkerDoc = await admin
          .firestore()
          .collection("workers")
          .doc(userRecord.uid)
          .get();

      if (existingWorkerDoc.exists) {
        const existingData = existingWorkerDoc.data();
        return {
          success: true,
          workerUid: userRecord.uid,
          workerId: existingData.worker_id,
          message: "Worker account already exists",
          alreadyExists: true,
        };
      }
    } catch (error) {
      // User doesn't exist, continue with creation
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
    }

    // Create new Firebase Auth user if doesn't exist
    if (!userRecord) {
      userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        emailVerified: false,
        disabled: false,
      });
      console.log("✅ Worker Auth account created:", userRecord.uid);
    }

    // Store worker data in Firestore
    const batch = admin.firestore().batch();

    // Add to workers collection
    const workerRef = admin
        .firestore()
        .collection("workers")
        .doc(userRecord.uid);
    batch.set(workerRef, {
      ...workerData,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      last_active: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Add to users collection
    const userRef = admin
        .firestore()
        .collection("users")
        .doc(userRecord.uid);
    batch.set(userRef, {
      ...userData,
      uid: userRecord.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();

    console.log("✅ Worker documents created in Firestore");

    return {
      success: true,
      workerUid: userRecord.uid,
      workerId: workerData.worker_id,
      message: "Worker account created successfully",
      alreadyExists: false,
    };
  } catch (error) {
    console.error("❌ Error creating worker:", error);

    // Handle specific Firebase Auth errors
    if (error.code === "auth/email-already-exists") {
      throw new functions.https.HttpsError(
          "already-exists",
          "A worker account with this email already exists",
      );
    }

    throw new functions.https.HttpsError(
        "internal",
        "Failed to create worker account: " + error.message,
    );
  }
});
