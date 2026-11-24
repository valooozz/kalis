// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kalis';

  @override
  String get tabFigures => 'Figures';

  @override
  String get tabToday => 'Today';

  @override
  String get tabPlanning => 'Planning';

  @override
  String get figuresScreenTitle => 'Figures';

  @override
  String get todayScreenTitle => 'Today\'s session';

  @override
  String get todayHelpTitle => 'Available actions';

  @override
  String get todayHelpContent =>
      'Tap a figure to mark your training as done or edit its note.\n\nPress and hold a completed figure to undo it, or an incomplete figure to review its latest note.\n\nPress and hold the screen background to open today\'s strength exercises.';

  @override
  String get planningScreenTitle => 'Planning';

  @override
  String get planningHelpTitle => 'Available actions';

  @override
  String get planningHelpContent =>
      'Tap a figure to see its recent and upcoming training sessions.\n\nPress and hold a figure to remove it from that day.\n\nTap + to add a figure.\n\nPress and hold + to start or resume a figure.';

  @override
  String get stateLearned => 'Mastered';

  @override
  String get stateLearning => 'Learning';

  @override
  String get stateToLearn => 'To learn';

  @override
  String get noFiguresToday => 'Today is for recharging';

  @override
  String get noFiguresTodaySubtitle => 'Your body needs some rest!';

  @override
  String get noFigures => 'No figures yet';

  @override
  String get noFiguresAction => 'Add a figure';

  @override
  String get noJournalEntry => 'No journal entries';

  @override
  String get noFigureAvailable => 'No figures available';

  @override
  String get addFigure => 'Add a figure';

  @override
  String get editFigure => 'Edit figure';

  @override
  String get newFigure => 'New figure';

  @override
  String get deleteFigure => 'Delete';

  @override
  String deleteFigureConfirm(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get fieldName => 'Name';

  @override
  String get fieldNameHint => 'E.g. Muscle-up';

  @override
  String get fieldColor => 'Color';

  @override
  String get fieldStartDate => 'Start date';

  @override
  String get fieldMasteryDate => 'Mastery date';

  @override
  String get fieldStartedOn => 'Started on';

  @override
  String get fieldMasteredOn => 'Mastered on';

  @override
  String get changeStatus => 'Change status';

  @override
  String get journal => 'Journal';

  @override
  String get newJournalEntry => 'New entry';

  @override
  String get editJournalEntry => 'Edit entry';

  @override
  String get addJournalEntry => 'Add an entry';

  @override
  String get journalHint => 'Write your note here...';

  @override
  String get trainingHint => 'How did your training go?';

  @override
  String get trainingNote => 'Session note';

  @override
  String get addFigureToDay => 'Add a figure';

  @override
  String get showLearnedFigures => 'Show mastered figures';

  @override
  String get lastTraining => 'Last';

  @override
  String get nextTraining => 'Next';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonClose => 'Close';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonAdd => 'Add';

  @override
  String get buttonEdit => 'Edit';

  @override
  String get buttonDelete => 'Delete';

  @override
  String get buttonValidate => 'Done';

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String daysBefore(int days) {
    return '$days days earlier';
  }

  @override
  String inDays(int days) {
    return 'In $days days';
  }

  @override
  String daysAfter(int days) {
    return '$days days later';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get dayAfter => 'The day after';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get dayBefore => 'The day before';

  @override
  String get placesTitle => 'Locations';

  @override
  String get placesHelpTitle => 'What are locations for?';

  @override
  String get placesHelpContent =>
      'Locations help you organize your figures based on where you train. Create locations and choose which figures can be practised there. When planning a day, you can filter the available figures by location.';

  @override
  String get addPlace => 'Add a location';

  @override
  String get newPlace => 'New location';

  @override
  String get editPlace => 'Edit location';

  @override
  String get deletePlace => 'Delete location';

  @override
  String deletePlaceConfirm(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get placeAlreadyExistError => 'This location already exists.';

  @override
  String get fieldPlaceName => 'Name';

  @override
  String get noPlaces => 'No locations yet';

  @override
  String linkedFigures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count figures',
      one: '$count figure',
    );
    return '$_temp0';
  }

  @override
  String get beginLearning => 'I\'m going to learn this figure';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get archivedFiguresTitle => 'Archived figures';

  @override
  String get archivedFiguresSubtitle => 'View and restore archived figures';

  @override
  String get noArchivedFigures => 'No archived figures';

  @override
  String get archiveFigure => 'Archive';

  @override
  String get restoreFigure => 'Restore';

  @override
  String archiveFigureConfirm(String name) {
    return 'Archive the figure \"$name\"?';
  }

  @override
  String get resumeFigure => 'Resume';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsHelpSection => 'Help';

  @override
  String get settingsReplayOnboarding => 'Replay the introduction';

  @override
  String get settingsReplayOnboardingSubtitle =>
      'Rediscover the basics of Kalis';

  @override
  String get settingsHelpBubbles => 'Show help bubbles';

  @override
  String get settingsHelpBubblesSubtitle => 'Show ? buttons on screens';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingFiguresTitle => 'Organize your figures';

  @override
  String get onboardingFiguresDescription =>
      'Add your figures and track which ones you want to learn, are learning, or have mastered.';

  @override
  String get onboardingPlanningTitle => 'Plan your training';

  @override
  String get onboardingPlanningDescription =>
      'Schedule figures for upcoming days to build sessions that fit your pace.';

  @override
  String get onboardingProgressTitle => 'Track your progress';

  @override
  String get onboardingProgressDescription =>
      'Mark today\'s training as done, add notes, and check your records.';

  @override
  String get settingsLinkGoogle => 'Link a Google account';

  @override
  String get settingsLinkGoogleSubtitle =>
      'Sync your data across all your devices';

  @override
  String get settingsLinkedGoogle => 'Connected with Google';

  @override
  String get settingsLinkGoogleSuccess => 'Google account linked successfully';

  @override
  String get settingsLinkGoogleError => 'Error linking Google account';

  @override
  String get settingsAlreadyLinkedTitle => 'Account already in use';

  @override
  String get settingsAlreadyLinkedContent =>
      'This Google account is already linked to another Kalis account. Would you like to sign in to it? Your current data will not be migrated.';

  @override
  String get buttonConfirm => 'Confirm';

  @override
  String get record => 'Record';

  @override
  String get recordDialogTitle => 'Edit record';

  @override
  String get recordValue => 'Value';

  @override
  String get recordUnit => 'Unit';

  @override
  String get recordUnitReps => 'Repetitions';

  @override
  String get recordUnitSeconds => 'Seconds';

  @override
  String get noRecord => 'No records';

  @override
  String get markAsLearned => 'Mark as mastered';

  @override
  String get markAsLearnedTitle => 'Mark as mastered';

  @override
  String markAsLearnedConfirm(String name) {
    return 'Mark \"$name\" as mastered?';
  }

  @override
  String get allFiguresDone => 'All figures have been practised!';

  @override
  String get previousTraining => 'Previous';

  @override
  String get followingTraining => 'Next';

  @override
  String get calendarLegendDone => 'Completed';

  @override
  String get calendarLegendPlanned => 'Planned';

  @override
  String get recordsTitle => 'Records';

  @override
  String calendarMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count training sessions this month',
      one: '1 training session this month',
      zero: 'No training this month',
    );
    return '$_temp0';
  }

  @override
  String get generalNoteTooltip => 'General note';

  @override
  String get generalNoteDialogTitle => 'General note';

  @override
  String get generalNoteHint => 'Write your note here...';

  @override
  String get weeklyActivitiesTooltip => 'Weekly activities';

  @override
  String get weeklyActivitiesDialogTitle => 'Weekly activities';

  @override
  String get weeklyActivityHint => 'E.g. dance class';

  @override
  String get globalCalendarTitle => 'Global calendar';

  @override
  String get filterByColor => 'Filter by color';

  @override
  String get pausedFigure => 'Paused figure';

  @override
  String get pauseFigureTitle => 'Pause figure';

  @override
  String pauseFigureConfirm(String name) {
    return 'Pause the figure \"$name\"? It will no longer appear in planning.';
  }

  @override
  String get buttonPause => 'Pause';

  @override
  String get cannotRemoveDoneFigure =>
      'This figure has already been practised today and cannot be removed';

  @override
  String get pastPlanningTitle => 'Past sessions';

  @override
  String get pastPlanningMarkDoneTitle => 'Mark as practised';

  @override
  String pastPlanningMarkDoneConfirm(String name) {
    return 'Mark \"$name\" as practised on this day?';
  }

  @override
  String get pastPlanningMarkNotDoneTitle => 'Mark as not practised';

  @override
  String pastPlanningMarkNotDoneConfirm(String name) {
    return 'Remove \"$name\" from the figures practised on this day?';
  }

  @override
  String get pastPlanningRemoveTitle => 'Remove figure';

  @override
  String pastPlanningRemoveConfirm(String name) {
    return 'Remove \"$name\" from this day?';
  }

  @override
  String get noFiguresPast => 'No figures';

  @override
  String get errorRemovalTitle => 'Cannot remove figure';

  @override
  String get errorRemoval =>
      'This figure has been practised and therefore cannot be removed.';

  @override
  String get beginLearningDialogTitle => 'Start a figure';

  @override
  String get beginLearningConfirmTitle => 'Start learning';

  @override
  String beginLearningConfirm(String name) {
    return 'Set \"$name\" to learning and add it to today?';
  }

  @override
  String get noFiguresToLearn => 'No figures to learn';

  @override
  String get resumeFigureConfirmTitle => 'Resume figure';

  @override
  String resumeFigureConfirm(String name) {
    return 'Resume \"$name\" and add it to today?';
  }

  @override
  String get pausedFiguresSection => 'Paused figures';

  @override
  String get toLearnFiguresSection => 'Figures to learn';

  @override
  String get deactivateFigure => 'Deactivate figure';

  @override
  String get activateFigure => 'Keep figure active';

  @override
  String get favoriteFigure => 'Add figure to favourites';

  @override
  String get favoriteFigureHint =>
      'Favourite figures will appear first when planning.';

  @override
  String get activeFigureHint =>
      'A mastered figure that remains active will appear in planning alongside figures you are learning.';

  @override
  String get unfavoriteFigure => 'Remove figure from favourites';

  @override
  String get swapDaysTooltip => 'Swap two days';

  @override
  String get swapDaysDialogTitle => 'Swap two days';

  @override
  String get swapDaysConfirmButton => 'Swap';

  @override
  String get cannotSwapDoneFigureTitle => 'Cannot swap days';

  @override
  String get cannotSwapDoneFigure =>
      'A figure already completed today would be moved.';

  @override
  String get noFigurePlannedThisDay => 'No figures planned';

  @override
  String get swapDaysSuccess => 'Days swapped';

  @override
  String get renfosTitle => 'Strength exercises';

  @override
  String get renfosHelpTitle => 'What are strength exercises for?';

  @override
  String get renfosHelpContent =>
      'A strength exercise helps you build strength for one or more figures. Create an exercise, link it to figures, then mark it as done from today\'s session.\n\nA strength exercise cannot be practised if at least one of its linked figures is being practised that day.';

  @override
  String get addRenfo => 'Add a strength exercise';

  @override
  String get newRenfo => 'New strength exercise';

  @override
  String get editRenfo => 'Edit strength exercise';

  @override
  String get deleteRenfo => 'Delete strength exercise';

  @override
  String deleteRenfoConfirm(String name) {
    return 'Delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get renfoAlreadyExistError => 'This strength exercise already exists.';

  @override
  String get fieldRenfoName => 'Name';

  @override
  String get noRenfos => 'No strength exercises yet';

  @override
  String get renfoSessionTitle => 'Today\'s strength exercises';

  @override
  String get noRenfoToday => 'No strength exercises available today';
}
