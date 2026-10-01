import 'package:estodo/app/theme/app_theme.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/providers/task_providers.dart';
import 'package:estodo/features/tasks/presentation/utils/planned_draft.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/composer/composer_time_wheel.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/composer/planned_composer.dart';
import 'package:estodo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  final now = DateTime.now();

  Future<void> pump(
    WidgetTester tester, {
    PlannedDraftKind kind = PlannedDraftKind.task,
    TodoTask? task,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith((ref) => Stream.value(const <TodoTask>[])),
          listsProvider.overrideWith((ref) => Stream.value(const <TaskList>[])),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlannedComposer(
              date: now,
              accent: const Color(0xFF8E8CD8),
              kind: kind,
              task: task,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text('Devam'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('opens on the naming step with the parser hint', (tester) async {
    await pump(tester);

    expect(find.text('Devam'), findsOneWidget);
    expect(find.textContaining('yoga cuma 16:00'), findsOneWidget);
    expect(find.byType(ComposerTimeWheel), findsNothing);
  });

  testWidgets('moves to the schedule step after the title is typed',
      (tester) async {
    await pump(tester);
    await type(tester, 'Ekip toplantısı');
    await tapContinue(tester);

    expect(find.byType(ComposerTimeWheel), findsOneWidget);
    expect(find.text('Oluştur'), findsOneWidget);
    expect(find.text('Süre'), findsOneWidget);
  });

  testWidgets('reads day, time and duration out of the typed title',
      (tester) async {
    await pump(tester);
    await type(tester, '1 saat yoga yarın 16:00');
    await tapContinue(tester);

    // Title keeps only the subject, the schedule moved into the header.
    expect(find.text('yoga'), findsOneWidget);
    // Shown twice on purpose: in the header summary and on the wheel pill.
    expect(find.textContaining('16:00 – 17:00'), findsWidgets);
  });

  testWidgets('habit mode asks for a habit and keeps a rhythm', (tester) async {
    await pump(tester, kind: PlannedDraftKind.habit);
    await type(tester, 'Su iç');
    await tapContinue(tester);

    expect(find.text('Oluştur'), findsOneWidget);
    // A daily rhythm is preselected, so the repeat row is already listed.
    expect(find.text('Her gün'), findsNothing);
    expect(find.byIcon(Icons.autorenew_rounded), findsWidgets);
  });

  testWidgets('the icon avatar opens the color and icon sheet', (tester) async {
    await pump(tester);
    await type(tester, 'Koşu');
    await tester.tap(find.byIcon(Icons.palette_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Renk ve simge'), findsOneWidget);
    expect(find.text('Simge ara'), findsOneWidget);
  });

  testWidgets('editing an existing task opens straight on the schedule',
      (tester) async {
    await pump(
      tester,
      task: TodoTask(
        id: 't1',
        userId: 'u',
        title: 'Kod review',
        dueAt: DateTime(now.year, now.month, now.day),
        startAt: DateTime(now.year, now.month, now.day, 11),
        durationMinutes: 90,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(find.byType(ComposerTimeWheel), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.textContaining('11:00 – 12:30'), findsWidgets);
  });
}
