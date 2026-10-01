import 'package:estodo/app/theme/app_theme.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/domain/entities/task_priority.dart';
import 'package:estodo/features/tasks/presentation/providers/task_providers.dart';
import 'package:estodo/features/tasks/presentation/widgets/planned/composer/planned_composer.dart';
import 'package:estodo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeController extends TaskController {
  _FakeController(super.ref);
  final created = <String>[];

  @override
  Future<TodoTask> createTask({
    required String title,
    String? notes,
    String? listId,
    String? iconKey,
    int? colorValue,
    bool isHabit = false,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueAt,
    DateTime? startAt,
    int? durationMinutes,
    DateTime? reminderAt,
    recurrence,
    steps = const [],
    List<String> tags = const <String>[],
    bool isImportant = false,
    bool isMyDay = false,
  }) async {
    created.add(title);
    throw UnimplementedError('stop');
  }
}

void main() {
  setUpAll(() async => initializeDateFormatting());

  testWidgets('Oluştur button reaches createTask', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late _FakeController fake;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith((ref) => Stream.value(const <TodoTask>[])),
          listsProvider.overrideWith((ref) => Stream.value(const <TaskList>[])),
          taskControllerProvider.overrideWith((ref) => fake = _FakeController(ref)),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPlannedComposer(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextField).first, 'Su iç');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Devam'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Oluştur'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.created, ['Su iç']);
  });
}
