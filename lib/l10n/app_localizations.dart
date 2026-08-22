import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'estodo'**
  String get appName;

  /// No description provided for @myDay.
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get myDay;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @lists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get lists;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @listUnavailable.
  ///
  /// In en, this message translates to:
  /// **'List unavailable'**
  String get listUnavailable;

  /// No description provided for @selectAnotherList.
  ///
  /// In en, this message translates to:
  /// **'Select another list from the sidebar.'**
  String get selectAnotherList;

  /// No description provided for @renameList.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get renameList;

  /// No description provided for @deleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteList;

  /// No description provided for @deleteListConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get deleteListConfirmTitle;

  /// No description provided for @deleteListConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Tasks in \"{name}\" will move back to the default Tasks list.'**
  String deleteListConfirmBody(String name);

  /// No description provided for @listName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listName;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get addTask;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @taskNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Task name is required.'**
  String get taskNameRequired;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @upcomingPlans.
  ///
  /// In en, this message translates to:
  /// **'My upcoming plans'**
  String get upcomingPlans;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @addDueDate.
  ///
  /// In en, this message translates to:
  /// **'Add due date'**
  String get addDueDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String durationMinutes(Object minutes);

  /// No description provided for @customDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get customDuration;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @plannedDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans for this day'**
  String get plannedDayEmpty;

  /// No description provided for @plannedDayView.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get plannedDayView;

  /// No description provided for @plannedWeekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get plannedWeekView;

  /// No description provided for @plannedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get plannedToday;

  /// No description provided for @plannedNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get plannedNow;

  /// No description provided for @plannedTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get plannedTimeline;

  /// No description provided for @plannedUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled'**
  String get plannedUnscheduled;

  /// No description provided for @plannedUnscheduledHint.
  ///
  /// In en, this message translates to:
  /// **'Drag onto the timeline or tap + to give it a time.'**
  String get plannedUnscheduledHint;

  /// No description provided for @plannedEmptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'This day is open'**
  String get plannedEmptyDayTitle;

  /// No description provided for @plannedEmptyDayBody.
  ///
  /// In en, this message translates to:
  /// **'Add a first block and give the day a shape.'**
  String get plannedEmptyDayBody;

  /// No description provided for @plannedEmptyWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled this week'**
  String get plannedEmptyWeek;

  /// No description provided for @plannedMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String plannedMinutesShort(int minutes);

  /// No description provided for @plannedHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String plannedHoursShort(int hours);

  /// No description provided for @plannedRemaining.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String plannedRemaining(int minutes);

  /// No description provided for @plannedFreeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min free'**
  String plannedFreeMinutes(int minutes);

  /// No description provided for @plannedAddAt.
  ///
  /// In en, this message translates to:
  /// **'Add at {time}'**
  String plannedAddAt(String time);

  /// No description provided for @plannedScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String plannedScheduledAt(String time);

  /// No description provided for @plannedProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String plannedProgressSummary(int done, int total);

  /// No description provided for @plannedPickMonth.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get plannedPickMonth;

  /// No description provided for @plannedPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get plannedPreviousWeek;

  /// No description provided for @plannedNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get plannedNextWeek;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueLabel;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeats;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTask;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskConfirmTitle;

  /// No description provided for @deleteTaskConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" permanently?'**
  String deleteTaskConfirmBody(String title);

  /// No description provided for @addToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Add to My Day'**
  String get addToMyDay;

  /// No description provided for @addedToMyDay.
  ///
  /// In en, this message translates to:
  /// **'Added to My Day'**
  String get addedToMyDay;

  /// No description provided for @removeFromDay.
  ///
  /// In en, this message translates to:
  /// **'Remove from My Day'**
  String get removeFromDay;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @markImportant.
  ///
  /// In en, this message translates to:
  /// **'Mark as important'**
  String get markImportant;

  /// No description provided for @removeImportance.
  ///
  /// In en, this message translates to:
  /// **'Remove importance'**
  String get removeImportance;

  /// No description provided for @starred.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get starred;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTabTitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncDescription.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync enabled'**
  String get syncDescription;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get reportBug;

  /// No description provided for @reportBugTitle.
  ///
  /// In en, this message translates to:
  /// **'Found something wrong?'**
  String get reportBugTitle;

  /// No description provided for @reportBugBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened and help us improve estodo.'**
  String get reportBugBody;

  /// No description provided for @reportBugHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue or suggestion'**
  String get reportBugHint;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendFeedback;

  /// No description provided for @feedbackThanksTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback'**
  String get feedbackThanksTitle;

  /// No description provided for @feedbackThanksBody.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps us improve the app.'**
  String get feedbackThanksBody;

  /// No description provided for @feedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue or suggestion.'**
  String get feedbackEmpty;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Feedback could not be sent. Please try again.'**
  String get feedbackError;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon…'**
  String get comingSoon;

  /// No description provided for @futureFeaturesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap to see upcoming features'**
  String get futureFeaturesPrompt;

  /// No description provided for @futureFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming features'**
  String get futureFeaturesTitle;

  /// No description provided for @suggest.
  ///
  /// In en, this message translates to:
  /// **'Suggest'**
  String get suggest;

  /// No description provided for @aiTodoList.
  ///
  /// In en, this message translates to:
  /// **'Create a To Do list with AI'**
  String get aiTodoList;

  /// No description provided for @aiTodoListDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your day and let estodo prepare the tasks for you.'**
  String get aiTodoListDescription;

  /// No description provided for @featureSuggestionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap to send the developer a suggestion and help shape this feature.'**
  String get featureSuggestionPrompt;

  /// No description provided for @featureSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Help us shape this feature'**
  String get featureSuggestionTitle;

  /// No description provided for @featureSuggestionHint.
  ///
  /// In en, this message translates to:
  /// **'How would you like it to work?'**
  String get featureSuggestionHint;

  /// No description provided for @featureSuggestionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please write your suggestion.'**
  String get featureSuggestionEmpty;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @todaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String todaySubtitle(String date);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @greetingFormat.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingFormat(String greeting, String name);

  /// No description provided for @suggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTitle;

  /// No description provided for @suggestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 suggestion} other{{count} suggestions}}'**
  String suggestionsCount(int count);

  /// No description provided for @suggestionsHint.
  ///
  /// In en, this message translates to:
  /// **'Earlier or upcoming tasks you may want to plan for today.'**
  String get suggestionsHint;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'Completed  {count}'**
  String completedCount(int count);

  /// No description provided for @emptyMyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus on your day'**
  String get emptyMyDayTitle;

  /// No description provided for @emptyMyDayBody.
  ///
  /// In en, this message translates to:
  /// **'Add tasks for today and they reset tomorrow.'**
  String get emptyMyDayBody;

  /// No description provided for @emptyImportantTitle.
  ///
  /// In en, this message translates to:
  /// **'No important tasks'**
  String get emptyImportantTitle;

  /// No description provided for @emptyImportantBody.
  ///
  /// In en, this message translates to:
  /// **'Star tasks to keep them in this list.'**
  String get emptyImportantBody;

  /// No description provided for @emptyPlannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get emptyPlannedTitle;

  /// No description provided for @emptyPlannedBody.
  ///
  /// In en, this message translates to:
  /// **'Add a due date to a task to see it here.'**
  String get emptyPlannedBody;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Your inbox is clear'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Add a task to get started.'**
  String get emptyTasksBody;

  /// No description provided for @emptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing completed yet'**
  String get emptyCompletedTitle;

  /// No description provided for @emptyCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Tasks you finish appear here.'**
  String get emptyCompletedBody;

  /// No description provided for @emptyListTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this list'**
  String get emptyListTitle;

  /// No description provided for @emptyListBody.
  ///
  /// In en, this message translates to:
  /// **'Add a task here to keep related work together.'**
  String get emptyListBody;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchBody.
  ///
  /// In en, this message translates to:
  /// **'Find tasks by title, notes, or list name.'**
  String get emptySearchBody;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different title, note, or list name.'**
  String get noMatchesBody;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks and lists'**
  String get searchHint;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline. Changes will sync when connection returns.'**
  String get offlineBanner;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get freqWeekdays;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortManual.
  ///
  /// In en, this message translates to:
  /// **'My order'**
  String get sortManual;

  /// No description provided for @sortImportance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get sortImportance;

  /// No description provided for @sortDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get sortDueDate;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetically'**
  String get sortAlphabetical;

  /// No description provided for @sortCreationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation date'**
  String get sortCreationDate;

  /// No description provided for @sortMyDay.
  ///
  /// In en, this message translates to:
  /// **'Added to My Day'**
  String get sortMyDay;

  /// No description provided for @bucketEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get bucketEarlier;

  /// No description provided for @bucketToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bucketToday;

  /// No description provided for @bucketTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get bucketTomorrow;

  /// No description provided for @bucketThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get bucketThisWeek;

  /// No description provided for @bucketLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bucketLater;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to list'**
  String get moveTo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a reset link.'**
  String get forgotPasswordBody;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmail;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent. Check your inbox.'**
  String get passwordResetSent;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all your tasks. This cannot be undone.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a stronger password.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorRecentLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign in again before deleting your account.'**
  String get authErrorRecentLoginRequired;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorGuestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Guest access is temporarily unavailable. Try again shortly.'**
  String get authErrorGuestUnavailable;

  /// No description provided for @authErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authErrorDefault;

  /// No description provided for @errorCouldNotLoadTasks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tasks'**
  String get errorCouldNotLoadTasks;

  /// No description provided for @errorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorTryAgain;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
