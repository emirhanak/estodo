import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/preferences_provider.dart';
import '../../../../core/services/sync_status_provider.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/domain/entities/task_list.dart';
import '../../../tasks/domain/entities/todo_task.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/sync_status_badge.dart';
import '../providers/theme_mode_provider.dart';

const _feedbackEndpoint = 'https://estodo-feedback.emirhanak.workers.dev';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final user = ref.watch(authStateProvider).value;
    final accent = ref.watch(accentColorProvider);
    final oledMode = ref.watch(oledModeProvider);
    final hidden = ref.watch(hiddenSmartListsProvider);
    final syncState = ref.watch(syncStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        Text(
          l10n.settings,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: accent,
                    child: Text(
                      (user.displayName ?? user.email).isNotEmpty
                          ? (user.displayName ?? user.email)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? l10n.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user.email,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.name,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editName(context, ref),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        _SectionLabel(text: l10n.appearance),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                    icon: const Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.dark_mode_rounded),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (value) {
                  ref.read(themeModeProvider.notifier).setMode(value.first);
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accentColor,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in ListPalette.colors)
                    GestureDetector(
                      onTap: () => ref
                          .read(accentColorProvider.notifier)
                          .setColor(Color(color)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(color),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: accent.toARGB32() == color ? 3 : 0,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.only(top: 8),
                secondary: const Icon(Icons.contrast_rounded),
                title: Text(l10n.oledBlack),
                subtitle: Text(
                  l10n.oledBlackDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                value: oledMode,
                activeThumbColor: accent,
                onChanged: (value) =>
                    ref.read(oledModeProvider.notifier).setEnabled(value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel(text: l10n.lists),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (final entry in <_SmartListEntry>[
                _SmartListEntry('myDay', Icons.wb_sunny_outlined, l10n.myDay),
                _SmartListEntry(
                    'important', Icons.star_border_rounded, l10n.important),
                _SmartListEntry('planned', Icons.event_outlined, l10n.planned),
                _SmartListEntry('tasks', Icons.inbox_outlined, l10n.tasks),
                _SmartListEntry('completed', Icons.check_circle_outline_rounded,
                    l10n.completed),
              ])
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  secondary: Icon(entry.icon),
                  title: Text(entry.label),
                  value: !hidden.contains(entry.key),
                  activeThumbColor: accent,
                  onChanged: (_) => ref
                      .read(hiddenSmartListsProvider.notifier)
                      .toggle(entry.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionLabel(text: l10n.about),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  switch (syncState.status) {
                    SyncStatus.synced => Icons.cloud_done_rounded,
                    SyncStatus.syncing => Icons.sync_rounded,
                    SyncStatus.offline => Icons.cloud_off_rounded,
                  },
                  color: switch (syncState.status) {
                    SyncStatus.synced => Colors.teal,
                    SyncStatus.syncing => accent,
                    SyncStatus.offline => Colors.orange,
                  },
                ),
                title: Text(l10n.sync),
                subtitle: Text(
                  switch (syncState.status) {
                    SyncStatus.synced => l10n.syncStatusDetails(
                        DateTimeFormatter.timeLabel(syncState.lastSyncedAt)),
                    SyncStatus.syncing => l10n.syncStatusSyncing,
                    SyncStatus.offline => l10n.syncStatusOffline,
                  },
                ),
                trailing: IconButton(
                  tooltip: l10n.syncNow,
                  icon: syncState.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  onPressed: syncState.isSyncing
                      ? null
                      : () =>
                          ref.read(syncStatusProvider.notifier).triggerSync(),
                ),
                onTap: () => showSyncStatusSheet(context, ref),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                leading: Icon(
                  Icons.file_download_outlined,
                  color: scheme.primary,
                ),
                title: Text(l10n.exportData),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'Görev ve listeleri JSON olarak dışa aktarın'
                      : 'Export tasks and lists as JSON',
                ),
                onTap: () => _exportData(context, ref),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                leading: Icon(
                  Icons.file_upload_outlined,
                  color: scheme.primary,
                ),
                title: Text(l10n.importData),
                subtitle: Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'JSON yedeğinden görevleri geri yükleyin'
                      : 'Restore tasks from a JSON backup',
                ),
                onTap: () => _importData(context, ref),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                leading: SvgPicture.asset(
                  'assets/branding/bug_report.svg',
                  width: 24,
                  height: 24,
                ),
                title: Text(l10n.reportBug),
                onTap: () => _showBugReport(context, ref),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                leading: Icon(
                  Icons.auto_awesome_rounded,
                  color: accent,
                ),
                title: Text(l10n.comingSoon),
                subtitle: Text(l10n.futureFeaturesPrompt),
                onTap: () => _showComingSoon(context, ref),
              ),
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.version),
                subtitle: Text(
                  packageInfo.when(
                    data: (info) => '${info.version}.${info.buildNumber}',
                    loading: () => l10n.loading,
                    error: (error, stackTrace) => l10n.unavailable,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (user?.isAnonymous != true) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.signOut),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => _deleteAccount(context, ref),
          icon: const Icon(Icons.delete_forever_rounded),
          label: Text(l10n.deleteAccount),
        ),
      ],
    );
  }

  Future<void> _showComingSoon(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final accent = ref.read(accentColorProvider);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.futureFeaturesTitle),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.auto_awesome_rounded, color: accent),
              title: Text(l10n.aiTodoList),
              subtitle: Text(l10n.aiTodoListDescription),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline_rounded),
              title: Text(l10n.featureSuggestionTitle),
              trailing: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showFeatureSuggestion(context, ref);
                },
                child: Text(l10n.suggest),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBugReport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reportBugTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.reportBugHint,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.sendFeedback),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || !context.mounted) return;
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackEmpty)),
      );
      return;
    }

    await _submitFeedback(
      context,
      ref,
      message: message,
      type: 'bug',
    );
  }

  Future<void> _showFeatureSuggestion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.featureSuggestionTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.featureSuggestionHint,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.sendFeedback),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || !context.mounted) return;
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.featureSuggestionEmpty)),
      );
      return;
    }
    await _submitFeedback(
      context,
      ref,
      message: message,
      type: 'feature',
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    WidgetRef ref, {
    required String message,
    required String type,
  }) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).value;
    try {
      final userEmail = user?.email ?? 'unknown';
      final displayName = user?.displayName ?? 'unknown';
      final response = await http.post(
        Uri.parse(_feedbackEndpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'userEmail': userEmail,
          'displayName': displayName,
          'type': type,
          'locale': Localizations.localeOf(context).languageCode,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Feedback worker rejected the request.');
      }
      if (context.mounted) await _showFeedbackThanks(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackError)),
      );
    }
  }

  Future<void> _showFeedbackThanks(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final dialogFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'feedback-sent',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.feedbackThanksTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.feedbackThanksBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    await dialogFuture;
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final user = ref.read(authStateProvider).value;
    String? password;
    if (user != null && !user.isAnonymous) {
      password = await _requestPassword(context);
      if (password == null || password.isEmpty) return;
    }
    if (!context.mounted) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount(password: password);
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        final message = switch (error.code) {
          'wrong-password' ||
          'invalid-credential' =>
            l10n.authErrorWrongPassword,
          'requires-recent-login' => l10n.authErrorRecentLoginRequired,
          _ => error.message ?? l10n.authErrorDefault,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authErrorDefault)),
        );
      }
    }
  }

  Future<String?> _requestPassword(BuildContext context) async {
    final controller = TextEditingController();
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTr ? 'Hesabını doğrula' : 'Verify your account'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(
            labelText: isTr ? 'Şifre' : 'Password',
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isTr ? 'İptal' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(isTr ? 'Devam et' : 'Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName ?? '');
    final l10n = AppLocalizations.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await ref.read(authRepositoryProvider).updateDisplayName(newName);
      // Start a fresh subscription as an immediate fallback. The repository's
      // userChanges stream also keeps other screens in sync with this update.
      ref.invalidate(authStateProvider);
    } on FirebaseAuthException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorTryAgain)),
      );
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.read(tasksProvider).value ?? const <TodoTask>[];
    final lists = ref.read(listsProvider).value ?? const <TaskList>[];
    final jsonString = BackupService.exportToJson(tasks: tasks, lists: lists);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exportData),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tasks.length} ${l10n.tasks.toLowerCase()} · ${lists.length} ${l10n.lists.toLowerCase()}',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(
              Localizations.localeOf(dialogContext).languageCode == 'tr'
                  ? 'Panoya Kopyala'
                  : 'Copy to Clipboard',
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.backupCopied)),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final textController = TextEditingController();

    final input = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importData),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: textController,
            maxLines: 10,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '{\n  "app": "estodo",\n  "tasks": [...]\n}',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Pano',
                icon: const Icon(Icons.paste_rounded),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    textController.text = data!.text!;
                  }
                },
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, textController.text.trim()),
            child: Text(l10n.importData),
          ),
        ],
      ),
    );
    textController.dispose();

    if (input == null || input.isEmpty || !context.mounted) return;

    try {
      final controller = ref.read(taskControllerProvider);
      final existingLists =
          ref.read(listsProvider).value ?? const <TaskList>[];
      final existingTasks =
          ref.read(tasksProvider).value ?? const <TodoTask>[];

      final result = await BackupService.importFromJson(
        input,
        controller: controller,
        existingLists: existingLists,
        existingTasks: existingTasks,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupImportSuccess(result.restoredTasksCount)),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupInvalid),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _SmartListEntry {
  const _SmartListEntry(this.key, this.icon, this.label);
  final String key;
  final IconData icon;
  final String label;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
