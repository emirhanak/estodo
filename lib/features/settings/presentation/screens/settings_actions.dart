part of 'settings_screen.dart';

extension _SettingsActions on SettingsScreen {
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
    final locale = Localizations.localeOf(context).languageCode;
    try {
      // The worker verifies this token and reads the sender's identity from it.
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw StateError('Feedback requires a signed-in user.');
      }
      final displayName = user?.displayName ?? 'unknown';
      final response = await http.post(
        Uri.parse(_feedbackEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'message': message,
          'displayName': displayName,
          'type': type,
          'locale': locale,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Feedback worker rejected the request: ${response.statusCode}',
        );
      }
      if (context.mounted) await _showFeedbackThanks(context);
    } catch (error) {
      debugPrint('Feedback submission failed: $error');
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
      final existingLists = ref.read(listsProvider).value ?? const <TaskList>[];
      final existingTasks = ref.read(tasksProvider).value ?? const <TodoTask>[];

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
    } catch (error) {
      debugPrint('Backup import failed: $error');
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
