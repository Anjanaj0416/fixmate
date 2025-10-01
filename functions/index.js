// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to create a worker account server-side
 * This doesn't affect the customer's authentication state
 */
exports.createWorkerAccount = functions.https.onCall(async (data, context) => {
  // 1. Verify customer is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Customer must be authenticated",
    );
  }

  const {email, password, workerData, userData} = data;

  // 2. Validate input
  if (!email || !password || !workerData || !userData) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields",
    );
  }

  try {
    console.log(`📝 Creating worker account for: ${email}`);

    // 3. Check if worker already exists
    let userRecord;
    let alreadyExists = false;

    try {
      userRecord = await admin.auth().getUserByEmail(email);
      console.log(`✅ Worker already exists: ${userRecord.uid}`);
      alreadyExists = true;

      // Check if worker document exists
      const existingWorker = await admin
          .firestore()
          .collection("workers")
          .doc(userRecord.uid)
          .get();

      if (existingWorker.exists) {
        const data = existingWorker.data();
        return {
          success: true,
          workerUid: userRecord.uid,
          workerId: data.worker_id,
          message: "Worker already exists",
          alreadyExists: true,
        };
      }
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
      // User doesn't exist, continue with creation
    }

    // 4. Create Firebase Auth account (if doesn't exist)
    if (!userRecord) {
      userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        emailVerified: false,
        disabled: false,
      });
      console.log(`✅ Auth account created: ${userRecord.uid}`);
    }

    const workerUid = userRecord.uid;

    // 5. Generate worker_id
    const workerId = await generateWorkerId();
    console.log(`🆔 Generated worker_id: ${workerId}`);

    // 6. Use Firestore batch to write both documents atomically
    const batch = admin.firestore().batch();

    // Add worker_id to workerData
    const completeWorkerData = {
      ...workerData,
      worker_id: workerId,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      last_active: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Add worker_id to userData
    const completeUserData = {
      ...userData,
      uid: workerUid,
      worker_id: workerId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Create worker document
    const workerRef = admin.firestore().collection("workers").doc(workerUid);
    batch.set(workerRef, completeWorkerData);

    // Create user document
    const userRef = admin.firestore().collection("users").doc(workerUid);
    batch.set(userRef, completeUserData);

    // Commit both writes
    await batch.commit();
    console.log("✅ Worker and User documents created");

    return {
      success: true,
      workerUid: workerUid,
      workerId: workerId,
      message: alreadyExists ?
        "Worker account already exists" :
        "Worker account created successfully",
      alreadyExists: alreadyExists,
    };
  } catch (error) {
    console.error("❌ Error creating worker:", error);

    if (error.code === "auth/email-already-exists") {
      throw new functions.https.HttpsError(
          "already-exists",
          "Worker with this email already exists",
      );
    }

    throw new functions.https.HttpsError(
        "internal",
        `Failed to create worker: ${error.message}`,
    );
  }
});

/**
 * Helper function to generate sequential worker IDs (HM_0001, HM_0002, etc.)
 */
async function generateWorkerId() {
  try {
    const workersRef = admin.firestore().collection("workers");
    const snapshot = await workersRef
        .orderBy("worker_id", "desc")
        .limit(1)
        .get();

    let nextNumber = 1;

    if (!snapshot.empty) {
      const lastWorkerId = snapshot.docs[0].data().worker_id;
      const numberPart = lastWorkerId.replace("HM_", "");
      const lastNumber = parseInt(numberPart) || 0;
      nextNumber = lastNumber + 1;
    }

    // Format: HM_0001, HM_0002, etc.
    const formattedId = `HM_${nextNumber.toString().padStart(4, "0")}`;
    return formattedId;
  } catch (error) {
    console.error("Error generating worker ID:", error);
    // Fallback to timestamp-based ID
    return `HM_${Date.now()}`;
  }
}
