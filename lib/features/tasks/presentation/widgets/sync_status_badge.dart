import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/preferences_provider.dart';
import '../../../../core/services/sync_status_provider.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../l10n/app_localizations.dart';

class SyncStatusBadge extends ConsumerStatefulWidget {
  const SyncStatusBadge({
    super.key,
    this.showLabel = false,
  });

  final bool showLabel;

  @override
  ConsumerState<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends ConsumerState<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStatusProvider);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (syncState.isSyncing) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      if (_rotationController.isAnimating) {
        _rotationController.stop();
        _rotationController.reset();
      }
    }

    final (icon, color, label) = switch (syncState.status) {
      SyncStatus.synced => (
          Icons.cloud_done_rounded,
          Colors.teal,
          l10n.syncStatusSynced,
        ),
      SyncStatus.syncing => (
          Icons.sync_rounded,
          scheme.primary,
          l10n.syncStatusSyncing,
        ),
      SyncStatus.offline => (
          Icons.cloud_off_rounded,
          Colors.orange,
          l10n.syncStatusOffline,
        ),
    };

    final content = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        showSyncStatusSheet(context, ref);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncState.isSyncing)
              RotationTransition(
                turns: _rotationController,
                child: Icon(icon, size: 20, color: color),
              )
            else
              Icon(icon, size: 20, color: color),
            if (widget.showLabel) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Tooltip(
      message: label,
      child: content,
    );
  }
}

Future<void> showSyncStatusSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final accent = ref.read(accentColorProvider);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final syncState = ref.watch(syncStatusProvider);
          final timeStr = DateTimeFormatter.timeLabel(syncState.lastSyncedAt);

          final (icon, statusColor, title, description) =
              switch (syncState.status) {
            SyncStatus.synced => (
                Icons.cloud_done_rounded,
                Colors.teal,
                l10n.syncStatusSynced,
                l10n.syncStatusDetails(timeStr),
              ),
            SyncStatus.syncing => (
                Icons.sync_rounded,
                accent,
                l10n.syncStatusSyncing,
                l10n.syncStatusSyncing,
              ),
            SyncStatus.offline => (
                Icons.cloud_off_rounded,
                Colors.orange,
                l10n.syncStatusOffline,
                l10n.syncStatusOfflineDetails,
              ),
          };

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 32,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: accent,
                    ),
                    onPressed: syncState.isSyncing
                        ? null
                        : () async {
                            HapticFeedback.lightImpact();
                            await ref
                                .read(syncStatusProvider.notifier)
                                .triggerSync();
                          },
                    icon: syncState.isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(l10n.syncNow),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
