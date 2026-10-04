import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:estodo/app/app.dart';
import 'package:estodo/core/services/bootstrap.dart';
import 'package:estodo/core/services/preferences_provider.dart';
import 'package:estodo/features/tasks/presentation/screens/home_screen.dart';
import 'package:estodo/features/tasks/presentation/screens/planned_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:estodo/l10n/app_localizations.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/composer/composer_header.dart';

// The timeline's current-time indicator animates continuously.
Future<void> render(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('planned creation survives server reconciliation',
      (tester) async {
    final prefs = await Bootstrap.initialize();
    await prefs.setBool('pref.onboarding_seen', true);
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
    expect(auth.currentUser!.isAnonymous, isTrue,
        reason:
            'Run this production smoke test using a dedicated guest account');
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWith((ref) => prefs),
    ], child: const EstodoApp()));
    for (var i = 0; i < 60 && find.byType(HomeScreen).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.byType(HomeScreen), findsOneWidget);
    await render(tester);
    await tester.tap(find.byIcon(Icons.calendar_month_outlined).last);
    await render(tester);
    expect(find.byType(PlannedScreen), findsOneWidget);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(PlannedScreen)));
    // Drive the actual screen, title, Continue, and Create buttons.
    final title = 'Live verification ${DateTime.now().millisecondsSinceEpoch}';
    final add = find.byWidgetPredicate((widget) =>
        widget is FloatingActionButton &&
        widget.heroTag == 'planned-compose-fab');
    expect(add, findsOneWidget);
    const habit = bool.fromEnvironment('TEST_HABIT');
    await tester.tap(add);
    await render(tester);
    if (habit) {
      await tester.tap(find.descendant(
          of: find.byType(ComposerKindSwitch),
          matching: find.text(l10n.composerKindHabit)));
      await render(tester);
    }
    await tester.enterText(find.byType(TextField).first, title);
    await render(tester);
    await tester.tap(find.text(l10n.composerContinue));
    await render(tester);
    await tester.tap(find.text(l10n.composerCreateTask));
    await tester.pump(const Duration(seconds: 2));
    debugPrint('LIVE_STEP created');
    // Give the real backend enough time to acknowledge or reject the write.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    debugPrint(
        'LIVE_STEP querying server; visible=${find.text(title).evaluate().length}');
    final server = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('tasks')
        .where('title', isEqualTo: title)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 30));
    debugPrint(
        'LIVE_RESULT serverTasks=${server.docs.length}, visible=${find.text(title).evaluate().length}');
    const rejected = bool.fromEnvironment('EXPECT_REJECTED');
    expect(server.docs, hasLength(rejected ? 0 : 1));
    if (!rejected) {
      expect(server.docs.single.data()['isHabit'], habit);
      expect(server.docs.single.data()['startAt'], isA<Timestamp>());
      expect(server.docs.single.data()['dueAt'], isA<Timestamp>());
    }
    expect(find.text(title), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await render(tester);
    await tester.pumpWidget(ProviderScope(overrides: [
      sharedPreferencesProvider.overrideWith((ref) => prefs),
    ], child: const EstodoApp()));
    for (var i = 0; i < 60 && find.byType(HomeScreen).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await render(tester);
    await tester.tap(find.byIcon(Icons.calendar_month_outlined).last);
    await render(tester);
    expect(find.text(title), findsWidgets);
    debugPrint(
        'LIVE_RESULT reopened visible=${find.text(title).evaluate().length}');
    await tester.pumpWidget(const SizedBox.shrink());
    await render(tester);
  });
}
