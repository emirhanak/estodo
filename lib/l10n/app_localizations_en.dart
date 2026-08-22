// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'estodo';

  @override
  String get myDay => 'My Day';

  @override
  String get important => 'Important';

  @override
  String get planned => 'Planned';

  @override
  String get tasks => 'Tasks';

  @override
  String get completed => 'Completed';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get lists => 'Lists';

  @override
  String get newList => 'New list';

  @override
  String get listUnavailable => 'List unavailable';

  @override
  String get selectAnotherList => 'Select another list from the sidebar.';

  @override
  String get renameList => 'Rename list';

  @override
  String get deleteList => 'Delete list';

  @override
  String get deleteListConfirmTitle => 'Delete list?';

  @override
  String deleteListConfirmBody(String name) {
    return 'Tasks in \"$name\" will move back to the default Tasks list.';
  }

  @override
  String get listName => 'List name';

  @override
  String get addTask => 'Add a task';

  @override
  String get newTask => 'New task';

  @override
  String get taskName => 'Task name';

  @override
  String get taskNameRequired => 'Task name is required.';

  @override
  String get addNote => 'Add note';

  @override
  String get addStep => 'Add step';

  @override
  String get upcomingPlans => 'My upcoming plans';

  @override
  String get remindMe => 'Remind me';

  @override
  String get reminder => 'Reminder';

  @override
  String get addDueDate => 'Add due date';

  @override
  String get startTime => 'Start time';

  @override
  String get duration => 'Duration';

  @override
  String get allDay => 'All day';

  @override
  String durationMinutes(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get customDuration => 'Custom duration';

  @override
  String get minutes => 'minutes';

  @override
  String get plannedDayEmpty => 'No plans for this day';

  @override
  String get plannedDayView => 'Day';

  @override
  String get plannedWeekView => 'Week';

  @override
  String get plannedMonthView => 'Month';

  @override
  String get plannedToday => 'Today';

  @override
  String get plannedMoreActions => 'Planning actions';

  @override
  String get plannedSmartPlan => 'Smart plan';

  @override
  String plannedSmartPlanConfirm(int count) {
    return 'Place $count unscheduled tasks into the best available slots on this day? Important and high-priority tasks are placed first.';
  }

  @override
  String get plannedApplyPlan => 'Apply plan';

  @override
  String plannedSmartPlanDone(int count) {
    return 'Smart-planned $count tasks.';
  }

  @override
  String get plannedNothingToPlan =>
      'There are no unscheduled tasks or enough free time on this day.';

  @override
  String get plannedImportCalendar => 'Import calendar (.ics)';

  @override
  String get plannedImport => 'Import';

  @override
  String plannedImportConfirm(int count) {
    return 'Import $count calendar events as tasks?';
  }

  @override
  String plannedImportDone(int count) {
    return 'Imported $count calendar events.';
  }

  @override
  String get plannedImportInvalid => 'Choose an iCalendar (.ics) file.';

  @override
  String get plannedImportEmpty =>
      'No valid events were found in this calendar.';

  @override
  String get plannedImportFailed => 'The calendar could not be imported.';

  @override
  String get plannedNow => 'Now';

  @override
  String get plannedTimeline => 'Timeline';

  @override
  String get plannedUnscheduled => 'Unscheduled';

  @override
  String get plannedUnscheduledHint =>
      'Drag onto the timeline or tap + to give it a time.';

  @override
  String get plannedEmptyDayTitle => 'This day is open';

  @override
  String get plannedEmptyDayBody =>
      'Add a first block and give the day a shape.';

  @override
  String get plannedEmptyWeek => 'Nothing scheduled this week';

  @override
  String plannedMinutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String plannedHoursShort(int hours) {
    return '$hours h';
  }

  @override
  String plannedRemaining(int minutes) {
    return '$minutes min left';
  }

  @override
  String plannedFreeMinutes(int minutes) {
    return '$minutes min free';
  }

  @override
  String plannedAddAt(String time) {
    return 'Add at $time';
  }

  @override
  String plannedScheduledAt(String time) {
    return 'Scheduled for $time';
  }

  @override
  String plannedProgressSummary(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get plannedPickMonth => 'Pick a date';

  @override
  String get plannedPreviousWeek => 'Previous week';

  @override
  String get plannedNextWeek => 'Next week';

  @override
  String get dueLabel => 'Due';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeats => 'Repeats';

  @override
  String get list => 'List';

  @override
  String get priority => 'Priority';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get createTask => 'Create task';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get deleteTaskConfirmTitle => 'Delete task?';

  @override
  String deleteTaskConfirmBody(String title) {
    return 'Delete \"$title\" permanently?';
  }

  @override
  String get addToMyDay => 'Add to My Day';

  @override
  String get addedToMyDay => 'Added to My Day';

  @override
  String get removeFromDay => 'Remove from My Day';

  @override
  String get complete => 'Complete';

  @override
  String get undo => 'Undo';

  @override
  String get markImportant => 'Mark as important';

  @override
  String get removeImportance => 'Remove importance';

  @override
  String get starred => 'Important';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginTabTitle => 'Login';

  @override
  String get register => 'Register';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get createAccount => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent color';

  @override
  String get about => 'About';

  @override
  String get sync => 'Sync';

  @override
  String get syncDescription => 'Cloud sync enabled';

  @override
  String get reportBug => 'Report a bug';

  @override
  String get reportBugTitle => 'Found something wrong?';

  @override
  String get reportBugBody =>
      'Tell us what happened and help us improve estodo.';

  @override
  String get reportBugHint => 'Describe the issue or suggestion';

  @override
  String get sendFeedback => 'Send';

  @override
  String get feedbackThanksTitle => 'Thank you for your feedback';

  @override
  String get feedbackThanksBody => 'Your feedback helps us improve the app.';

  @override
  String get feedbackEmpty => 'Please describe the issue or suggestion.';

  @override
  String get feedbackError => 'Feedback could not be sent. Please try again.';

  @override
  String get comingSoon => 'Coming soon…';

  @override
  String get futureFeaturesPrompt => 'Tap to see upcoming features';

  @override
  String get futureFeaturesTitle => 'Upcoming features';

  @override
  String get suggest => 'Suggest';

  @override
  String get aiTodoList => 'Create a To Do list with AI';

  @override
  String get aiTodoListDescription =>
      'Describe your day and let estodo prepare the tasks for you.';

  @override
  String get featureSuggestionPrompt =>
      'Tap to send the developer a suggestion and help shape this feature.';

  @override
  String get featureSuggestionTitle => 'Help us shape this feature';

  @override
  String get featureSuggestionHint => 'How would you like it to work?';

  @override
  String get featureSuggestionEmpty => 'Please write your suggestion.';

  @override
  String get version => 'Version';

  @override
  String get loading => 'Loading…';

  @override
  String get unavailable => 'Unavailable';

  @override
  String todaySubtitle(String date) {
    return '$date';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String greetingFormat(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get suggestionsTitle => 'Suggestions';

  @override
  String suggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions',
      one: '1 suggestion',
    );
    return '$_temp0';
  }

  @override
  String get suggestionsHint =>
      'Earlier or upcoming tasks you may want to plan for today.';

  @override
  String completedCount(int count) {
    return 'Completed  $count';
  }

  @override
  String get emptyMyDayTitle => 'Focus on your day';

  @override
  String get emptyMyDayBody => 'Add tasks for today and they reset tomorrow.';

  @override
  String get emptyImportantTitle => 'No important tasks';

  @override
  String get emptyImportantBody => 'Star tasks to keep them in this list.';

  @override
  String get emptyPlannedTitle => 'Nothing planned';

  @override
  String get emptyPlannedBody => 'Add a due date to a task to see it here.';

  @override
  String get emptyTasksTitle => 'Your inbox is clear';

  @override
  String get emptyTasksBody => 'Add a task to get started.';

  @override
  String get emptyCompletedTitle => 'Nothing completed yet';

  @override
  String get emptyCompletedBody => 'Tasks you finish appear here.';

  @override
  String get emptyListTitle => 'No tasks in this list';

  @override
  String get emptyListBody => 'Add a task here to keep related work together.';

  @override
  String get emptySearchTitle => 'Search everything';

  @override
  String get emptySearchBody => 'Find tasks by title, notes, or list name.';

  @override
  String get noMatchesTitle => 'No matches';

  @override
  String get noMatchesBody => 'Try a different title, note, or list name.';

  @override
  String get searchHint => 'Search tasks and lists';

  @override
  String get offlineBanner =>
      'Offline. Changes will sync when connection returns.';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekdays => 'Weekdays';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortManual => 'My order';

  @override
  String get sortImportance => 'Importance';

  @override
  String get sortDueDate => 'Due date';

  @override
  String get sortAlphabetical => 'Alphabetically';

  @override
  String get sortCreationDate => 'Creation date';

  @override
  String get sortMyDay => 'Added to My Day';

  @override
  String get bucketEarlier => 'Earlier';

  @override
  String get bucketToday => 'Today';

  @override
  String get bucketTomorrow => 'Tomorrow';

  @override
  String get bucketThisWeek => 'This week';

  @override
  String get bucketLater => 'Later';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get moveTo => 'Move to list';

  @override
  String get clear => 'Clear';

  @override
  String get close => 'Close';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordBody =>
      'Enter your email and we\'ll send a reset link.';

  @override
  String get sendResetEmail => 'Send reset email';

  @override
  String get passwordResetSent => 'Reset link sent. Check your inbox.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmBody =>
      'This will permanently delete your account and all your tasks. This cannot be undone.';

  @override
  String get authErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorWrongPassword => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse => 'An account already exists for this email.';

  @override
  String get authErrorWeakPassword => 'Use a stronger password.';

  @override
  String get authErrorRecentLoginRequired =>
      'Please sign out and sign in again before deleting your account.';

  @override
  String get authErrorNetwork =>
      'Unable to connect. Check your internet connection and try again.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authErrorGuestUnavailable =>
      'Guest access is temporarily unavailable. Try again shortly.';

  @override
  String get authErrorDefault => 'Authentication failed.';

  @override
  String get errorCouldNotLoadTasks => 'Could not load tasks';

  @override
  String get errorTryAgain => 'Something went wrong. Try again.';
}
