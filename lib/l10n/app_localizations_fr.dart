// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Kalis';

  @override
  String get tabFigures => 'Figures';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabPlanning => 'Planification';

  @override
  String get figuresScreenTitle => 'Figures';

  @override
  String get todayScreenTitle => 'Séance du jour';

  @override
  String get planningScreenTitle => 'Planification';

  @override
  String get stateLearned => 'Maîtrisées';

  @override
  String get stateLearning => 'En apprentissage';

  @override
  String get stateToLearn => 'À apprendre';

  @override
  String get noFiguresToday => 'Aujourd\'hui on recharge les batteries';

  @override
  String get noFiguresTodaySubtitle => 'Ton corps a besoin de se reposer !';

  @override
  String get noFigures => 'Aucune figure pour le moment';

  @override
  String get noFiguresAction => 'Ajouter une figure';

  @override
  String get noJournalEntry => 'Aucune entrée de journal';

  @override
  String get noFigureAvailable => 'Aucune figure disponible';

  @override
  String get addFigure => 'Ajouter une figure';

  @override
  String get editFigure => 'Modifier la figure';

  @override
  String get newFigure => 'Nouvelle figure';

  @override
  String get deleteFigure => 'Supprimer la figure';

  @override
  String deleteFigureConfirm(String name) {
    return 'Supprimer \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldNameHint => 'Ex: Muscle-up';

  @override
  String get fieldColor => 'Couleur';

  @override
  String get fieldStartDate => 'Date de début';

  @override
  String get fieldMasteryDate => 'Date de maîtrise';

  @override
  String get fieldStartedOn => 'Débutée le';

  @override
  String get fieldMasteredOn => 'Maîtrisée le';

  @override
  String get changeStatus => 'Changer le statut';

  @override
  String get journal => 'Journal';

  @override
  String get newJournalEntry => 'Nouvelle entrée';

  @override
  String get editJournalEntry => 'Modifier l\'entrée';

  @override
  String get addJournalEntry => 'Ajouter une entrée';

  @override
  String get journalHint => 'Écris ta note ici...';

  @override
  String get trainingHint => 'Comment s\'est passé l\'entraînement ?';

  @override
  String get trainingNote => 'Note de séance';

  @override
  String get addFigureToDay => 'Ajouter une figure';

  @override
  String get showLearnedFigures => 'Afficher les figures maîtrisées';

  @override
  String get lastTraining => 'Dernier';

  @override
  String get nextTraining => 'Prochain';

  @override
  String get buttonCancel => 'Annuler';

  @override
  String get buttonClose => 'Fermer';

  @override
  String get buttonSave => 'Enregistrer';

  @override
  String get buttonAdd => 'Ajouter';

  @override
  String get buttonEdit => 'Modifier';

  @override
  String get buttonDelete => 'Supprimer';

  @override
  String get buttonValidate => 'Valider';

  @override
  String daysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String daysBefore(int days) {
    return '$days jours plus tôt';
  }

  @override
  String inDays(int days) {
    return 'Dans $days jours';
  }

  @override
  String daysAfter(int days) {
    return '$days jours plus tard';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get dayAfter => 'Le lendemain';

  @override
  String get yesterday => 'Hier';

  @override
  String get dayBefore => 'La veille';

  @override
  String get beginLearning => 'Je vais apprendre cette figure';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAccountSection => 'Compte';

  @override
  String get settingsLinkGoogle => 'Lier à un compte Google';

  @override
  String get settingsLinkGoogleSubtitle =>
      'Synchronisez vos données sur tous vos appareils';

  @override
  String get settingsLinkedGoogle => 'Connecté avec Google';

  @override
  String get settingsLinkGoogleSuccess => 'Compte Google lié avec succès';

  @override
  String get settingsLinkGoogleError =>
      'Erreur lors de la liaison au compte Google';

  @override
  String get settingsAlreadyLinkedTitle => 'Compte déjà utilisé';

  @override
  String get settingsAlreadyLinkedContent =>
      'Ce compte Google est déjà lié à un autre compte Kalis. Veux-tu te connecter à ce compte ? Tes données actuelles ne seront pas migrées.';

  @override
  String get buttonConfirm => 'Confirmer';

  @override
  String get record => 'Record';

  @override
  String get recordDialogTitle => 'Modifier le record';

  @override
  String get recordValue => 'Valeur';

  @override
  String get recordUnit => 'Unité';

  @override
  String get recordUnitReps => 'Répétitions';

  @override
  String get recordUnitSeconds => 'Secondes';

  @override
  String get noRecord => 'Aucun record';

  @override
  String get markAsLearned => 'Marquer comme maîtrisée';

  @override
  String get markAsLearnedTitle => 'Marquer comme maîtrisée';

  @override
  String markAsLearnedConfirm(String name) {
    return 'Passer \"$name\" au statut Maîtrisée ?';
  }

  @override
  String get allFiguresDone => 'Toutes les figures ont été travaillées !';

  @override
  String get previousTraining => 'Précédent';

  @override
  String get followingTraining => 'Suivant';

  @override
  String get calendarLegendDone => 'Effectué';

  @override
  String get calendarLegendPlanned => 'Planifié';

  @override
  String get recordsTitle => 'Records';

  @override
  String calendarMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entraînements ce mois-ci',
      one: '1 entraînement ce mois-ci',
      zero: 'Aucun entraînement ce mois-ci',
    );
    return '$_temp0';
  }

  @override
  String get globalCalendarTitle => 'Calendrier global';

  @override
  String get filterByColor => 'Filtrer par couleur';

  @override
  String get pausedFigure => 'Figure en pause';

  @override
  String get pauseFigureTitle => 'Mettre en pause';

  @override
  String pauseFigureConfirm(String name) {
    return 'Mettre en pause la figure \"$name\" ?';
  }

  @override
  String get buttonPause => 'Mettre en pause';
}
