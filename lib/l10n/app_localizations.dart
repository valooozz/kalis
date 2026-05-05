import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Kalis'**
  String get appName;

  /// No description provided for @tabFigures.
  ///
  /// In fr, this message translates to:
  /// **'Figures'**
  String get tabFigures;

  /// No description provided for @tabToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get tabToday;

  /// No description provided for @tabPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Planification'**
  String get tabPlanning;

  /// No description provided for @figuresScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Figures'**
  String get figuresScreenTitle;

  /// No description provided for @todayScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Séance du jour'**
  String get todayScreenTitle;

  /// No description provided for @planningScreenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planification'**
  String get planningScreenTitle;

  /// No description provided for @stateLearned.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisées'**
  String get stateLearned;

  /// No description provided for @stateLearning.
  ///
  /// In fr, this message translates to:
  /// **'En apprentissage'**
  String get stateLearning;

  /// No description provided for @stateToLearn.
  ///
  /// In fr, this message translates to:
  /// **'À apprendre'**
  String get stateToLearn;

  /// No description provided for @noFiguresToday.
  ///
  /// In fr, this message translates to:
  /// **'Aucune figure prévue aujourd\'hui'**
  String get noFiguresToday;

  /// No description provided for @noFiguresTodaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Profites-en pour te reposer !'**
  String get noFiguresTodaySubtitle;

  /// No description provided for @noFigures.
  ///
  /// In fr, this message translates to:
  /// **'Aucune figure pour le moment'**
  String get noFigures;

  /// No description provided for @noFiguresAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une figure'**
  String get noFiguresAction;

  /// No description provided for @noJournalEntry.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée de journal'**
  String get noJournalEntry;

  /// No description provided for @noFigureAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune figure disponible'**
  String get noFigureAvailable;

  /// No description provided for @addFigure.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une figure'**
  String get addFigure;

  /// No description provided for @editFigure.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la figure'**
  String get editFigure;

  /// No description provided for @newFigure.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle figure'**
  String get newFigure;

  /// No description provided for @deleteFigure.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la figure'**
  String get deleteFigure;

  /// No description provided for @deleteFigureConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer \"{name}\" ? Cette action est irréversible.'**
  String deleteFigureConfirm(String name);

  /// No description provided for @fieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get fieldName;

  /// No description provided for @fieldNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Muscle-up'**
  String get fieldNameHint;

  /// No description provided for @fieldColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get fieldColor;

  /// No description provided for @fieldStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get fieldStartDate;

  /// No description provided for @fieldMasteryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de maîtrise'**
  String get fieldMasteryDate;

  /// No description provided for @fieldStartedOn.
  ///
  /// In fr, this message translates to:
  /// **'Débutée le'**
  String get fieldStartedOn;

  /// No description provided for @fieldMasteredOn.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisée le'**
  String get fieldMasteredOn;

  /// No description provided for @changeStatus.
  ///
  /// In fr, this message translates to:
  /// **'Changer le statut'**
  String get changeStatus;

  /// No description provided for @journal.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @newJournalEntry.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle entrée'**
  String get newJournalEntry;

  /// No description provided for @editJournalEntry.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'entrée'**
  String get editJournalEntry;

  /// No description provided for @addJournalEntry.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une entrée'**
  String get addJournalEntry;

  /// No description provided for @journalHint.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta note ici...'**
  String get journalHint;

  /// No description provided for @trainingHint.
  ///
  /// In fr, this message translates to:
  /// **'Comment s\'est passé l\'entraînement ?'**
  String get trainingHint;

  /// No description provided for @trainingNote.
  ///
  /// In fr, this message translates to:
  /// **'Note de séance'**
  String get trainingNote;

  /// No description provided for @addFigureToDay.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une figure'**
  String get addFigureToDay;

  /// No description provided for @showLearnedFigures.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les figures maîtrisées'**
  String get showLearnedFigures;

  /// No description provided for @lastTraining.
  ///
  /// In fr, this message translates to:
  /// **'Dernier'**
  String get lastTraining;

  /// No description provided for @nextTraining.
  ///
  /// In fr, this message translates to:
  /// **'Prochain'**
  String get nextTraining;

  /// No description provided for @buttonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get buttonCancel;

  /// No description provided for @buttonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get buttonClose;

  /// No description provided for @buttonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get buttonSave;

  /// No description provided for @buttonAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get buttonAdd;

  /// No description provided for @buttonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get buttonEdit;

  /// No description provided for @buttonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get buttonDelete;

  /// No description provided for @buttonValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get buttonValidate;

  /// No description provided for @daysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {days} jours'**
  String daysAgo(int days);

  /// No description provided for @daysBefore.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours plus tôt'**
  String daysBefore(int days);

  /// No description provided for @inDays.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days} jours'**
  String inDays(int days);

  /// No description provided for @daysAfter.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours plus tard'**
  String daysAfter(int days);

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @dayAfter.
  ///
  /// In fr, this message translates to:
  /// **'Le lendemain'**
  String get dayAfter;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @dayBefore.
  ///
  /// In fr, this message translates to:
  /// **'La veille'**
  String get dayBefore;

  /// No description provided for @beginLearning.
  ///
  /// In fr, this message translates to:
  /// **'Je vais apprendre cette figure'**
  String get beginLearning;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsAccountSection.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsAccountSection;

  /// No description provided for @settingsLinkGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Lier à un compte Google'**
  String get settingsLinkGoogle;

  /// No description provided for @settingsLinkGoogleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisez vos données sur tous vos appareils'**
  String get settingsLinkGoogleSubtitle;

  /// No description provided for @settingsLinkedGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Connecté avec Google'**
  String get settingsLinkedGoogle;

  /// No description provided for @settingsLinkGoogleSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte Google lié avec succès'**
  String get settingsLinkGoogleSuccess;

  /// No description provided for @settingsLinkGoogleError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la liaison au compte Google'**
  String get settingsLinkGoogleError;

  /// No description provided for @settingsAlreadyLinkedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte déjà utilisé'**
  String get settingsAlreadyLinkedTitle;

  /// No description provided for @settingsAlreadyLinkedContent.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte Google est déjà lié à un autre compte Kalis. Voulez-vous vous connecter à ce compte ? Vos données actuelles ne seront pas migrées.'**
  String get settingsAlreadyLinkedContent;

  /// No description provided for @buttonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get buttonConfirm;

  /// No description provided for @record.
  ///
  /// In fr, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @recordDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le record'**
  String get recordDialogTitle;

  /// No description provided for @recordValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get recordValue;

  /// No description provided for @recordUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get recordUnit;

  /// No description provided for @recordUnitReps.
  ///
  /// In fr, this message translates to:
  /// **'Répétitions'**
  String get recordUnitReps;

  /// No description provided for @recordUnitSeconds.
  ///
  /// In fr, this message translates to:
  /// **'Secondes'**
  String get recordUnitSeconds;

  /// No description provided for @noRecord.
  ///
  /// In fr, this message translates to:
  /// **'Aucun record'**
  String get noRecord;

  /// No description provided for @markAsLearned.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme maîtrisée'**
  String get markAsLearned;

  /// No description provided for @markAsLearnedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme maîtrisée'**
  String get markAsLearnedTitle;

  /// No description provided for @markAsLearnedConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir passer \"{name}\" au statut Maîtrisée ?'**
  String markAsLearnedConfirm(String name);

  /// No description provided for @allFiguresDone.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les figures ont été travaillées !'**
  String get allFiguresDone;

  /// No description provided for @previousTraining.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previousTraining;

  /// No description provided for @followingTraining.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get followingTraining;

  /// No description provided for @calendarLegendDone.
  ///
  /// In fr, this message translates to:
  /// **'Effectué'**
  String get calendarLegendDone;

  /// No description provided for @calendarLegendPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Planifié'**
  String get calendarLegendPlanned;

  /// No description provided for @recordsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Records'**
  String get recordsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
