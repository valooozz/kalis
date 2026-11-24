const assert = require("node:assert/strict");
const test = require("node:test");
const { deleteUserAccount, hasRecentSignIn } = require("../account_deletion");

test("recursively deletes only the caller's data before deleting Auth", async () => {
  const operations = [];
  const userDocument = { path: "users/test-uid" };
  const firestore = {
    collection(name) {
      assert.equal(name, "users");
      return {
        doc(uid) {
          assert.equal(uid, "test-uid");
          return userDocument;
        },
      };
    },
    async recursiveDelete(document) {
      operations.push(["recursiveDelete", document]);
    },
  };
  const auth = {
    async deleteUser(uid) {
      operations.push(["deleteUser", uid]);
    },
  };

  await deleteUserAccount("test-uid", { firestore, auth });

  assert.deepEqual(operations, [
    ["recursiveDelete", userDocument],
    ["deleteUser", "test-uid"],
  ]);
});

test("is safe to retry when the Auth user is already gone", async () => {
  const auth = {
    async deleteUser() {
      const error = new Error("User not found");
      error.code = "auth/user-not-found";
      throw error;
    },
  };
  const firestore = {
    collection() {
      return { doc: (uid) => ({ uid }) };
    },
    async recursiveDelete() {},
  };

  await assert.doesNotReject(
    deleteUserAccount("test-uid", { firestore, auth }),
  );
});

test("requires a recent sign-in for linked accounts", () => {
  const now = 1_800_000_000_000;
  assert.equal(
    hasRecentSignIn({ token: { auth_time: now / 1000 - 60 } }, now),
    true,
  );
  assert.equal(
    hasRecentSignIn({ token: { auth_time: now / 1000 - 6 * 60 } }, now),
    false,
  );
});

test("allows the current anonymous session to delete its own account", () => {
  assert.equal(
    hasRecentSignIn(
      { token: { firebase: { sign_in_provider: "anonymous" } } },
    ),
    true,
  );
});