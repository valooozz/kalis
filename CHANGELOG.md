# Version 1

### v1.12.0

- Message d'erreur quand on tente de retirer une figure planifiée aujourd'hui qui a été travaillée
- Headers de l'onglet Figures ne se chevauchent plus
- Pastille de couleur transparente sur les figures en pause
- Bords arrondis sur l'effet splash de la case à cocher
- Uniformisation tutoiement

### v1.11.1

- Pastille de couleur sur tous les Dialog concernant une figure
- Changement design de FigureCard pour les figures en pause
- Modification du style du bandeau de fin de séance

### v1.11.0

- Possibilité de placer l'apprentissage de figures en pause
- Filtre sur la couleur dans l'onglet Figures
- Icônes sur FigureSquareCard pour indiquer le statut de la figure
- Possibilité de swiper entre les onglets
- Fix : Insertion de l'entrée de journal dans le champ de texte pour les entrées dans le passé

### v1.10.3

- Fix : Retrait de l'espace vide dans RecordsScreen quand il y a une figure sans record
- Quand on passe une figure à l'état suivant ou précédent, elle apparaît respectivement en bas ou en haut de la liste
- Élargissement de certains Dialog, et légère modification du style du journal

### v1.10.2

- Retrait de l'icône de calendrier pour les figures à apprendre
- Modification de l'icône de validation de l'entraînement du jour
- Fermeture de FigureDetailDialog lors de l'ouverture du calendrier d'une figure
- Forçage du mode portrait, rotation désactivée
- Retrait de l'effet Splash sur les FigureCard de AddFigureToDayDialog

### v1.10.1

- Fix : Retrait des figures sans record dans RecordsScreen
- Retrait des doubleTap pour plus de fluidité, accès à ce qu'ils ouvraient par d'autres moyens

### v1.10.0

- Page de records
- Affichage du nombre d'entraînement pour chaque mois du calendrier d'une figure
- Calendrier global montrant les séances de chaque jour
- Retrait grisage sur les labels des jours du weekend dans FigureCalendarDialog

### v1.9.0

- Un tap sur une figure dans Planification montre les dates des entraînements précédent et suivant
- Un double tap sur une figure dans Figures ou Planification montre le calendrier complet de ses entraînements passés et futurs

### v1.8.1

- Fix du flicker lors du reorder

### v1.8.0

- Possibilité de changer l'ordre des figures au sein d'une catégorie

### v1.7.0

- Bouton pour passer une figure à Maîtrisée dans la séance du jour
- Suppression du record quand on quitte l'état Maîtrisée
- Bandeau de séance du jour terminée
- Gestion du singulier/pluriel sur les unités de record
- Changement de style du choix de l'unité de record

### v1.6.0

- Système de record pour les figures maîtrisées

### v1.5.0

- Différenciation des FigureSquareCard entre figures maîtrisées et en apprentissage
- Retrait du tri par état sur la liste des figures pour un jour

### v1.4.0

- Connexion au compte Google

### v1.3.0

- Label du dernier entraînement d'une figure en rouge s'il remonte trop
- Changement du nom de l'appli avec une majuscule : Kalis
- Double-tape sur les cartes de la séance du jour montre la dernière entrée de journal
- Retrait autofocus sur le nom d'une figure quand on la modifie

### v1.2.0

- Ajout logo et splashscreen
- Changement titre page Figure "Maîtrisée" en "Maîtrisées"

### v1.1.0

- Changement état "Apprise" en "Maîtrisée"
- Ajout bouton "Je vais apprendre cette figure"
- Amélioration de l'ordre d'apparition des figures dans AddFigureToDayDialog
- Affichage des dates relatives aux jours sélectionnés dans AddFigureToDayDialog

### v1.0.0

- Architecture Riverpod + Repository pattern propre et maintenable
- Synchronisation Firebase Firestore en temps réel avec authentification anonyme
- Trois onglets fonctionnels — Figures, Séance du jour, Planification
- Système de journal par figure
- Système de localisation FR avec fichiers .arb
- Thème clair/sombre suivant le système