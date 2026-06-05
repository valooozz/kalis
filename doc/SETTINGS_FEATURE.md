# 📚 Documentation - Page Settings

## Vue d'ensemble

La page **Settings** (Paramètres) est l'interface de gestion des paramètres utilisateur et de l'authentification. C'est ici que l'utilisateur peut **lier son compte anonyme à un compte Google** pour synchroniser ses données sur tous ses appareils et sécuriser son compte.

### Objectifs principaux

- 🔐 **Afficher** le statut de connexion au compte Google
- 🔗 **Lier** un compte anonyme à un compte Google
- 📧 **Afficher** l'email du compte Google connecté
- ⚠️ **Gérer** le cas où le compte Google est déjà utilisé par un autre compte
- 🔄 **Synchroniser** l'état d'authentification après la liaison

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Composants de l'interface](#composants-de-linterface)
3. [Écrans et dialogues](#écrans-et-dialogues)
4. [Flux d'authentification](#flux-dauthentification)
5. [Gestion des erreurs](#gestion-des-erreurs)
6. [Providers et gestion d'état](#providers-et-gestion-détat)
7. [Intégration Firebase et Google Sign-In](#intégration-firebase-et-google-sign-in)

---

## Architecture générale

### Vue hiérarchique des composants

```
SettingsScreen (écran principal)
├── AppBar
│   └── Titre: "Paramètres"
│
└── ListView
    ├── _SectionHeader
    │   └── Titre section: "Compte"
    │
    └── _SettingsTile (conditionnel)
        ├── Version 1: Pas lié à Google
        │   ├── Icon: account_circle
        │   ├── Title: "Lier avec Google"
        │   ├── Subtitle: "Synchronisez vos données sur tous vos appareils"
        │   └── onTap: _linkGoogle()
        │
        └── Version 2: Lié à Google
            ├── Icon: check_circle (vert)
            ├── Title: "Connecté avec Google"
            ├── Subtitle: Email du compte
            └── onTap: null (pas d'action)
```

---

## Composants de l'interface

### SettingsScreen (Widget principal)

**Type** : `ConsumerWidget`

**Responsabilités** :
- Afficher l'interface des paramètres
- Surveiller le statut de liaison avec Google via `isLinkedToGoogleProvider`
- Afficher le compte Google lié via `authStateProvider`
- Gérer les actions de liaison et les dialogues

**Propriétés** :
- Aucune propriété (widget stateless)

**Structure du build** :
```dart
Scaffold(
  appBar: AppBar avec titre localisé
  body: ListView avec sections
)
```

---

### _SectionHeader (composant interne)

**Type** : `StatelessWidget`

**Responsabilités** :
- Afficher un en-tête de section avec styling distinctif

**Propriétés** :
- `label` (String) : Texte de l'en-tête

**Styling** :
- Padding : 16 gauche/droite, 24 haut, 8 bas
- Couleur : Couleur primaire du thème
- Police : `labelLarge` avec `fontWeight.bold`

---

### _SettingsTile (composant interne)

**Type** : `StatelessWidget`

**Responsabilités** :
- Afficher une tuile de paramètre avec icône, titre et sous-titre
- Gérer les interactions via `onTap`
- Afficher une flèche de navigation si interactive

**Propriétés** :
- `icon` (IconData) : Icône affichée
- `title` (String) : Titre principal
- `subtitle` (String) : Sous-titre
- `onTap` (VoidCallback?) : Callback au tap (null = non-interactif)
- `iconColor` (Color?) : Couleur de l'icône (défaut: couleur primaire)

**Rendering** :
- `ListTile` de Flutter avec leading icon et trailing chevron
- Le chevron de droite n'apparaît que si `onTap != null`

---

## Écrans et dialogues

### État : Non lié à Google

**Condition** : `isLinkedToGoogle == false`

**Affichage** :
- Tuile avec icône `account_circle` (couleur primaire)
- Titre : "Lier avec Google"
- Sous-titre : "Synchronisez vos données sur tous vos appareils"
- Chevron de navigation visible
- Interactive (appui possible)

**Action au tap** : Appel de `_linkGoogle()`

---

### État : Lié à Google

**Condition** : `isLinkedToGoogle == true`

**Affichage** :
- Tuile avec icône `check_circle` (couleur verte)
- Titre : "Connecté avec Google"
- Sous-titre : Email du compte Google (extrait de `authStateProvider`)
- Pas de chevron de navigation
- Non-interactive (pas d'action au tap)

---

### Dialogue : Compte Google déjà utilisé

**Titre** : "Compte déjà utilisé"

**Contenu** : 
> "Ce compte Google est déjà lié à un autre compte Kalis. Veux-tu te connecter à ce compte ? Tes données actuelles ne seront pas migrées."

**Actions** :
1. Bouton "Annuler" (TextButton) → Ferme le dialogue, retourne `false`
2. Bouton "Confirmer" (FilledButton) → Connecte avec le compte Google existant, retourne `true`

**Déclenchement** : Levée d'exception `FirebaseAuthException` avec code `'credential-already-in-use'`

---

## Flux d'authentification

### Flux 1 : Liaison à un compte Google neuf

```
Utilisateur tape sur la tuile
         ↓
    _linkGoogle() appelée
         ↓
   GoogleSignIn.signIn()
         ↓
   Utilisateur se connecte via le navigateur Google
         ↓
Récupération des tokens d'authentification
  (accessToken + idToken)
         ↓
Création de GoogleAuthProvider.credential()
         ↓
 linkWithCredential() sur le compte Firebase actuel
    (liaison du compte anonyme)
         ↓
Rechargement du user courant
  FirebaseAuth.instance.currentUser.reload()
         ↓
Invalidation du provider isLinkedToGoogleProvider
  (force la rewatch)
         ↓
SnackBar de succès affiché
         ↓
L'interface se met à jour : la tuile passe en mode "Connecté"
```

**Points clés** :
- Le compte Firebase de base est **anonyme** (créé dans `main.dart`)
- La liaison le relie à un compte Google **sans changer d'utilisateur**
- L'userId reste le même avant et après
- L'email devient disponible après la liaison

---

### Flux 2 : Compte Google déjà utilisé par un autre compte

```
Utilisateur tape sur la tuile
         ↓
    _linkGoogle() appelée
         ↓
   GoogleSignIn.signIn()
         ↓
   Authentification Google réussie
         ↓
Création du credential Google
         ↓
 linkWithCredential() lève une exception
 FirebaseAuthException(code='credential-already-in-use')
         ↓
Interception de l'exception
         ↓
 _showAlreadyLinkedDialog() appelée
         ↓
   Utilisateur voit le dialogue
         ↓
   Utilisateur tape "Annuler" → Dialogue ferme, pas de changement
         OU
   Utilisateur tape "Confirmer" → Connexion avec le compte existant
         ↓
FirebaseAuth.instance.signInWithCredential(credential)
         ↓
L'utilisateur change : userId et données basculent vers le compte Google
(⚠️ Les données du compte anonyme ne sont PAS migrées)
```

**⚠️ Comportement critique** :
- Si l'utilisateur confirme, il **change de compte** et ses données actuelles **ne suivront pas**
- C'est un risque de perte de données qu'on communique à l'utilisateur

---

### Flux 3 : Annulation de la connexion Google

```
Utilisateur initie la liaison Google
         ↓
GoogleSignIn.signIn() → Utilisateur ferme le navigateur
         ↓
googleUser == null
         ↓
Retour anticipé (early return)
         ↓
Rien n'est fait, pas d'erreur affichée
```

---

## Gestion des erreurs

### Erreur : credential-already-in-use

**Cause** : Le compte Google sélectionné est déjà lié à un autre compte Firebase

**Handling** :
1. Interception via `catch (FirebaseAuthException e)`
2. Vérification du code d'erreur : `e.code == 'credential-already-in-use'`
3. Appel de `_showAlreadyLinkedDialog()` avec le credential récupéré
4. L'utilisateur choisit s'il veut changer de compte

---

### Erreur : Autres FirebaseAuthException

**Cause** : Erreur générique (problème de connexion, permissions manquantes, etc.)

**Handling** :
1. Interception via `catch (FirebaseAuthException e)`
2. Affichage d'un SnackBar d'erreur : "Erreur lors de la liaison au compte Google"
3. Pas de dialogue secondaire

---

### Vérification du contexte (context.mounted)

**Objectif** : Éviter les crashes si le widget est désmonté pendant une opération asynchrone

**Implémentation** :
```dart
if (context.mounted) {
  // Afficher un SnackBar ou un dialogue
}
```

---

## Providers et gestion d'état

### isLinkedToGoogleProvider

**Type** : `Provider<bool>`

**Description** : Fournit un booléen indiquant si l'utilisateur est lié à un compte Google

**Implémentation** :
```dart
final isLinkedToGoogleProvider = Provider<bool>((ref) {
  // Force la relecture à chaque changement d'auth
  ref.watch(authStateProvider);
  
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  // Vérifie si Google est dans la liste des providers du user
  return user.providerData.any((p) => p.providerId == 'google.com');
});
```

**Logique** :
1. Observe les changements d'authentification via `authStateProvider`
2. Récupère l'utilisateur Firebase courant
3. Vérifie si `providerData` contient un provider avec `providerId == 'google.com'`
4. Retourne `true` si lié, `false` sinon

**Utilisation dans l'écran** :
```dart
final isLinkedToGoogle = ref.watch(isLinkedToGoogleProvider);
// Condition d'affichage :
if (!isLinkedToGoogle) {
  // Afficher: "Lier avec Google"
} else {
  // Afficher: "Connecté avec Google"
}
```

---

### authStateProvider

**Type** : `StreamProvider<User?>`

**Description** : Stream de l'état d'authentification Firebase courant

**Source** : `FirebaseAuth.instance.authStateChanges()`

**Utilisation dans l'écran** :
```dart
ref.watch(authStateProvider).valueOrNull?.email ?? ''
// Récupère l'email du user courant (null si pas d'email)
```

---

### googleSignInProvider

**Type** : `Provider<GoogleSignIn>`

**Description** : Instance unique de GoogleSignIn pour gérer la connexion Google

**Utilisation** :
```dart
final googleSignIn = ref.read(googleSignInProvider);
final googleUser = await googleSignIn.signIn();
```

**Scope** : Lecture simple (pas de watch), une seule instance persistante

---

## Intégration Firebase et Google Sign-In

### Architecture d'authentification

```
┌─────────────────────────────────┐
│   Application Kalis             │
│  (SettingsScreen)               │
└────────────┬────────────────────┘
             │
             ├──→ FirebaseAuth (via firebaseAuthProvider)
             │       ├── currentUser (User actuel)
             │       ├── authStateChanges() (stream d'état)
             │       └── linkWithCredential() (liaison)
             │
             ├──→ GoogleSignIn (via googleSignInProvider)
             │       └── signIn() (ouvre navigateur)
             │
             └──→ FirebaseAuth (liaison au account Google)
                     └── signInWithCredential() (basculer vers Google)
```

---

### Étapes de la liaison

#### Étape 1 : Obtenir les tokens Google

```dart
final googleUser = await googleSignIn.signIn();
final googleAuth = await googleUser.authentication;
// googleAuth.accessToken : token d'accès
// googleAuth.idToken : token d'identité (JWT)
```

**Responsables** : GoogleSignIn SDK

---

#### Étape 2 : Créer un credential Firebase

```dart
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
```

**Responsable** : Firebase Auth SDK

---

#### Étape 3 : Lier au compte anonyme

```dart
final user = FirebaseAuth.instance.currentUser;
await user?.linkWithCredential(credential);
```

**Résultat** :
- L'utilisateur Firebase reste le même (userId inchangé)
- Google est ajouté à sa liste de `providerData`
- Email du compte Google devient disponible

---

#### Étape 4 : Rafraîchir et invalider

```dart
await FirebaseAuth.instance.currentUser?.reload();
ref.invalidate(isLinkedToGoogleProvider);
```

**Raisons** :
- `reload()` : Synchronise les données du user depuis le serveur Firebase
- `invalidate()` : Force Riverpod à recalculer le provider la prochaine fois

---

### Cas spécial : Compte déjà utilisé

**Situation** :
- L'utilisateur A a un compte anonyme
- Le compte Google qu'il essaie de lier existe déjà et est lié à l'utilisateur B

**Erreur levée** :
```
FirebaseAuthException(code: 'credential-already-in-use')
```

**Options disponibles** :
1. **Annuler** → Rester sur le compte A, pas de changement
2. **Confirmer** → Basculer vers le compte B via `signInWithCredential()`
   - Déconnecte du compte A
   - Connecte au compte B
   - Les données du compte A restent orphelines (non accessibles par la suite)

---

## Intégrations et dépendances

### Imports directs

| Import | Provenance | Usage |
|--------|-----------|-------|
| `firebase_auth` | Package Firebase | Authentification, liaison de credentials |
| `flutter/material.dart` | Flutter | UI (Scaffold, AppBar, ListView, etc.) |
| `flutter_riverpod` | Package Riverpod | Gestion d'état (ref.watch, ref.read, etc.) |
| `app_localizations` | Localisations du projet | Clés i18n (settingsTitle, etc.) |
| `core_providers` | Fournisseur du projet | Accès à googleSignInProvider, authStateProvider, etc. |

---

### Fichiers du projet utilisés

| Fichier | Usage |
|---------|-------|
| [lib/providers/core_providers.dart](../../lib/providers/core_providers.dart) | Fournit googleSignInProvider, authStateProvider, isLinkedToGoogleProvider |
| [lib/l10n/app_localizations.dart](../../lib/l10n/app_localizations.dart) | Clés i18n pour tous les textes |
| [lib/main.dart](../../lib/main.dart) | Initialisation anonyme au démarrage |
| [lib/core/router/app_router.dart](../../lib/core/router/app_router.dart) | Enregistrement de la route /settings |

---

## Points techniques importants

### Connexion anonyme initiale

L'application démarre avec un utilisateur **anonyme** (cf. `main.dart`) :
```dart
if (FirebaseAuth.instance.currentUser == null) {
  await FirebaseAuth.instance.signInAnonymously();
}
```

**Conséquence** : La page Settings permet de passer d'un compte anonyme à un compte Google.

---

### userId et persistance des données

- **Avant liaison** : userId = ID anonyme généré par Firebase
- **Après liaison via linkWithCredential()** : userId = même (pas de changement)
- **Après changement de compte via signInWithCredential()** : userId = nouveau (basculement)

Les données Firestore sont **toutes filtrées par userId**, donc :
- Liaison réussie → Données conservées (même userId)
- Changement de compte → Données orphelines (userId différent)

---

### Invalidation et rewatch des providers

```dart
ref.invalidate(isLinkedToGoogleProvider);
```

Cela force le provider à être recalculé à la prochaine utilisation. C'est nécessaire car la liaison modifie l'état interne de FirebaseAuth (ajout de provider à `providerData`) sans émettre un nouvel événement `authStateChanges()`.

---

### Gestion du contexte monté

```dart
if (context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

Protocole pour éviter les crashes si :
- Une opération asynchrone dure longtemps
- L'utilisateur quitte l'écran avant la fin
- On essaie d'afficher une UI sur un widget désmonté

---

## Flux d'interaction complets

### Scénario 1 : Utilisateur lie son compte Google pour la première fois

1. Utilisateur voit la tuile "Lier avec Google"
2. Tape sur la tuile → `_linkGoogle()` déclenchée
3. Navigateur Google s'ouvre, utilisateur se connecte
4. Tokens échangés
5. `linkWithCredential()` réussit
6. Provider invalidé → Écran se met à jour
7. Tuile passe en "Connecté avec Google" avec l'email visible
8. SnackBar de succès affichée
9. Données synchronisées entre les appareils (même userId)

---

### Scénario 2 : Compte Google déjà utilisé

1. Utilisateur voit la tuile "Lier avec Google"
2. Tape sur la tuile → `_linkGoogle()` déclenchée
3. Navigateur Google s'ouvre, utilisateur se connecte avec un compte existant
4. Tokens échangés
5. `linkWithCredential()` lève `credential-already-in-use`
6. Dialogue s'affiche
7. **Option A** : Utilisateur tape "Annuler" → Dialogue ferme, pas de changement
8. **Option B** : Utilisateur tape "Confirmer"
   - `signInWithCredential()` déconnecte du compte A et connecte au B
   - Écran reste sur Settings (l'app garde la même UI)
   - Données de l'utilisateur basculent vers le compte B
   - Les données du compte A ne sont plus accessibles

---

### Scénario 3 : Annulation lors de la connexion Google

1. Utilisateur voit la tuile "Lier avec Google"
2. Tape sur la tuile → `_linkGoogle()` déclenchée
3. Navigateur Google s'ouvre
4. Utilisateur ferme le navigateur sans se connecter
5. `googleUser == null` → Retour anticipé
6. Rien ne se passe, pas d'erreur affichée
7. Écran reste dans le même état

---

## Conclusion

La page **Settings** est un point d'entrée critique pour la **gestion de l'authentification**. Elle transforme un compte **anonyme** (créé au démarrage) en compte **Google** pour permettre la **synchronisation multiplateforme** et la **sécurisation des données**.

L'implémentation est robuste avec :
- ✅ Gestion d'erreurs complète (credentials déjà utilisés, annulations)
- ✅ Validation du contexte monté pour éviter les crashes
- ✅ Invalidation intelligente des providers pour forcer la réactualisation
- ✅ Messages clairs et multilingues pour guider l'utilisateur
- ✅ Feedback immédiat via SnackBars et dialogues

---

*Dernière mise à jour : Juin 2026*
