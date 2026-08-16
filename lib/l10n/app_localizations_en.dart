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
  String get remindMe => 'Remind me';

  @override
  String get reminder => 'Reminder';

  @override
  String get addDueDate => 'Add due date';

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
  String get syncDescription => 'Cloud sync with offline support';

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
