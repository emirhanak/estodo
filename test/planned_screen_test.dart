import 'package:estodo/app/theme/app_theme.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/presentation/providers/task_providers.dart';
import 'package:estodo/features/tasks/presentation/screens/planned_screen.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/planned_capsule.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/planned_entry_row.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/planned_month_grid.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/planned_week_grid.dart';
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
  DateTime at(int hour, int minute) =>
      DateTime(now.year, now.month, now.day, hour, minute);

  final lists = <TaskList>[
    TaskList(
      id: 'l1',
      userId: 'u',
      name: 'İş',
      color: 0xFF5B5FC7,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  TodoTask task(
    String id,
    String title, {
    DateTime? start,
    int? duration,
    String? listId,
  }) =>
      TodoTask(
        id: id,
        userId: 'u',
        title: title,
        listId: listId,
        dueAt: DateTime(now.year, now.month, now.day),
        startAt: start,
        durationMinutes: duration,
        createdAt: now,
        updatedAt: now,
      );

  Future<void> pump(
    WidgetTester tester,
    List<TodoTask> tasks, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith((ref) => Stream.value(tasks)),
          listsProvider.overrideWith((ref) => Stream.value(lists)),
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
          home: const Scaffold(body: PlannedScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('renders a timeline row per scheduled task', (tester) async {
    await pump(tester, [
      task('1', 'Sabah koşusu', start: at(7, 0), duration: 45),
      task('2', 'Ekip toplantısı',
          start: at(9, 30), duration: 60, listId: 'l1'),
    ]);

    expect(find.byType(PlannedEntryRow), findsNWidgets(2));
    expect(find.byType(PlannedCapsule), findsNWidgets(2));
    expect(find.text('Sabah koşusu'), findsOneWidget);
    expect(find.text('Ekip toplantısı'), findsOneWidget);
  });

  testWidgets('shows the empty state when the day has no tasks',
      (tester) async {
    await pump(tester, const <TodoTask>[]);

    expect(find.text('Bu gün boş'), findsOneWidget);
    expect(find.byType(PlannedEntryRow), findsNothing);
  });

  testWidgets('lists day tasks without a time as unscheduled bubbles',
      (tester) async {
    await pump(tester, [task('1', 'Market alışverişi')]);

    expect(find.textContaining('Saati yok'), findsOneWidget);
    expect(find.text('Market alışverişi'), findsOneWidget);
  });

  testWidgets('switches to the week grid', (tester) async {
    await pump(tester, [task('1', 'Sabah koşusu', start: at(7, 0))]);

    await tester.tap(find.byIcon(Icons.calendar_view_week_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PlannedWeekGrid), findsOneWidget);
    expect(find.byType(PlannedEntryRow), findsNothing);
  });

  testWidgets('switches to the month grid', (tester) async {
    await pump(tester, [task('1', 'Sabah koşusu', start: at(7, 0))]);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(PlannedMonthGrid), findsOneWidget);
    expect(find.byType(PlannedEntryRow), findsNothing);
  });

  testWidgets('shows the inbox pane on tablet widths', (tester) async {
    await pump(
      tester,
      [task('1', 'Market alışverişi')],
      size: const Size(1024, 768),
    );

    // The tablet layout moves unscheduled work into the side panel.
    expect(find.text('Saati yok'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
  });
}
