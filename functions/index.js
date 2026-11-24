const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { deleteUserAccount, hasRecentSignIn } = require("./account_deletion");

initializeApp();

exports.deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  if (!hasRecentSignIn(request.auth)) {
    throw new HttpsError(
      "failed-precondition",
      "Sign in again before deleting this account.",
    );
  }

  try {
    await deleteUserAccount(uid, {
      firestore: getFirestore(),
      auth: getAuth(),
    });
    return { success: true };
  } catch (error) {
    console.error("Account deletion failed", { uid, error });
    throw new HttpsError("internal", "Account deletion failed.");
  }
});