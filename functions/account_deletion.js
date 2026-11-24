async function deleteUserAccount(uid, { firestore, auth }) {
  const userDocument = firestore.collection("users").doc(uid);
  await firestore.recursiveDelete(userDocument);

  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
  }
}

function hasRecentSignIn(authContext, now = Date.now()) {
  if (authContext.token?.firebase?.sign_in_provider === "anonymous") {
    return true;
  }

  const authTime = Number(authContext.token?.auth_time);
  const age = now - authTime * 1000;
  return Number.isFinite(authTime) && age >= 0 && age <= 5 * 60 * 1000;
}

module.exports = { deleteUserAccount, hasRecentSignIn };