# Suppression de compte

La callable Function `deleteAccount` utilise le UID authentifié de l'appelant, supprime récursivement `users/{uid}` et ses sous-collections, puis supprime le compte Firebase Auth. Les comptes liés à Google doivent avoir été réauthentifiés dans les cinq dernières minutes; un compte anonyme peut supprimer uniquement son UID courant. L'ordre permet de garder les règles de sécurité applicables côté client hors du nettoyage Admin; un nouvel essai est possible si la suppression Auth échoue après le nettoyage Firestore.

## Essai local

Prérequis : Firebase CLI et Node.js 22.

```powershell
npm install --prefix functions
npm test --prefix functions
firebase emulators:start --only auth,firestore,functions --project kalis-f86cf
```

Dans un second terminal, lancer l'app en debug avec les émulateurs activés :

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Sur l'émulateur Android, utiliser son adresse hôte spéciale :

```powershell
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Le branchement aux émulateurs est désactivé dans les builds release. Les essais locaux doivent créer leur utilisateur et leurs documents dans les émulateurs; ils ne modifient pas les données du projet Firebase distant.

## Déploiement

Après validation locale, déployer la callable Function dans le projet Firebase configuré :

```powershell
firebase deploy --only functions:deleteAccount --project <projet-firebase>
```