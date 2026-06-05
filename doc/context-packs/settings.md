# Context Pack — Kalis: Settings Page

## Overview

Single-purpose screen for managing authentication. The app starts with an **anonymous Firebase account** (created in `main.dart` if no current user). Settings lets the user upgrade that anonymous account to a Google account, enabling multi-device sync.

---

## Component Tree

```
SettingsScreen
└── ListView
    ├── _SectionHeader  ("Compte")
    └── _SettingsTile   (conditional on isLinkedToGoogleProvider)
        ├── not linked  → "Lier avec Google"  (tappable → _linkGoogle())
        └── linked      → "Connecté avec Google" + email  (non-tappable)
```

No sub-dialogs except the inline confirmation dialog for the `credential-already-in-use` case.

---

## Authentication Flows

**Normal link** (`linkWithCredential`):
1. `googleSignIn.signIn()` → get `accessToken` + `idToken`.
2. Build `GoogleAuthProvider.credential(accessToken, idToken)`.
3. `FirebaseAuth.instance.currentUser.linkWithCredential(credential)`.
4. `currentUser.reload()` then `ref.invalidate(isLinkedToGoogleProvider)`.
5. Show success SnackBar. UI updates: tile switches to "Connecté" state.

`reload()` + `invalidate()` are both required: linking adds Google to `providerData` without emitting a new `authStateChanges()` event, so the provider won't update on its own.

**`credential-already-in-use`** (Google account already tied to another Firebase user):
- Show confirmation dialog warning that current data will **not** be migrated.
- Cancel → no change.
- Confirm → `FirebaseAuth.instance.signInWithCredential(credential)` — this **switches userId**. All Firestore data (scoped to the old userId) becomes inaccessible.

**User cancels Google sign-in** (`googleUser == null`) → early return, no error shown.

**Other `FirebaseAuthException`** → SnackBar with generic error message.

---

## Critical Behaviour: userId & Data

| Action | userId after | Data |
|---|---|---|
| `linkWithCredential` succeeds | Same as before | ✅ Preserved |
| `signInWithCredential` (account switch) | New (Google account's UID) | ⚠️ Previous data orphaned |

All Firestore collections are scoped to userId, so an account switch silently severs access to all existing data.

---

## Providers Used

| Provider | Role |
|---|---|
| `isLinkedToGoogleProvider` | `Provider<bool>` — checks `currentUser.providerData` for `'google.com'`; must be invalidated after `linkWithCredential` |
| `authStateProvider` | `StreamProvider<User?>` — used to read `user.email` for the subtitle |
| `googleSignInProvider` | `Provider<GoogleSignIn>` — read-only, single instance |

---

## Context Safety

All SnackBars and dialogs shown after async calls are guarded with `if (context.mounted)` to prevent crashes if the user navigates away during the flow.