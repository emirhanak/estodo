import 'dart:async';

import 'package:estodo/app/theme/app_theme.dart';
import 'package:estodo/features/auth/domain/entities/app_user.dart';
import 'package:estodo/features/auth/presentation/providers/auth_providers.dart';
import 'package:estodo/features/tasks/domain/entities/task_list.dart';
import 'package:estodo/features/tasks/domain/entities/todo_task.dart';
import 'package:estodo/features/tasks/domain/repositories/task_repository.dart';
import 'package:estodo/features/tasks/presentation/providers/task_providers.dart';
import 'package:estodo/features/tasks/presentation/screens/planned_screen.dart';
import 'package:estodo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _MemoryRepo implements TaskRepository {
  final _tasks = <TodoTask>[];
  final _controller = StreamController<List<TodoTask>>.broadcast();

  @override
  Stream<List<TodoTask>> watchTasks(String userId) async* {
    yield List.of(_tasks);
    yield* _controller.stream;
  }

  @override
  Future<void> createTask(String userId, TodoTask task) async {
    _tasks.add(task);
    _controller.add(List.of(_tasks));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #watchLists) {
      return Stream.value(const <TaskList>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(() async => initializeDateFormatting());

  for (final habitFirst in [true, false]) {
    testWidgets('creating from the FAB shows the entry (habit=$habitFirst)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = _MemoryRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AppUser(
                  id: 'u', email: 'a@b.c', isAnonymous: false)),
            ),
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

      await tester.tap(find.byTooltip('Yeni görev'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      if (!habitFirst) {
        await tester.tap(find.text('Plan'));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.enterText(find.byType(TextField).first, 'Su iç');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Devam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(repo._tasks.length, 1);
      expect(find.text('Oluştur'), findsNothing, reason: 'sheet should close');
      expect(find.text('Su iç'), findsWidgets);
    });
  }
}
