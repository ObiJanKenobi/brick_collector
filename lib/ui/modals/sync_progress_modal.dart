import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/services/collection_sync_service.dart';

/// Generic progress modal for any task that emits [SyncProgress] events.
/// Pass the stream you're subscribing to and the future representing the work.
/// Collection-sync callers can use [showSyncProgressModal] which wires defaults.
Future<void> showProgressModal(
  BuildContext context, {
  required Stream<SyncProgress?> stream,
  required Future<void> task,
  String runningTitle = 'Syncing…',
  String completeTitle = 'Sync complete',
  String failedTitle = 'Sync failed',
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return PopScope(
        canPop: false,
        child: StreamBuilder<SyncProgress?>(
          stream: stream,
          builder: (context, snapshot) {
            final p = snapshot.data;
            final finished = p?.finished ?? false;
            final failed = p?.failed ?? false;
            final failures = p?.failures ?? const <SyncFailure>[];

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                failed ? failedTitle : (finished ? completeTitle : runningTitle),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (p == null || p.total == 0) ? null : p.fraction,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.highlightColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p?.label ?? 'Starting…',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (p != null && p.total > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${p.done} / ${p.total}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    if (failed && p?.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        p!.error == 'login_required' ? 'Please log in and try again.' : p.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                    if (failures.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${failures.length} source${failures.length == 1 ? "" : "s"} failed:',
                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: failures.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${failures[i].label}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (finished)
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close', style: TextStyle(color: AppColors.highlightColor)),
                  ),
              ],
            );
          },
        ),
      );
    },
  );

  await task;
}

/// Convenience wrapper around [showProgressModal] for the collection sync.
Future<void> showSyncProgressModal(BuildContext context) async {
  final service = collectionSyncService;
  if (!appLogic.loggedIn) {
    await loginUser(context);
    if (!context.mounted) return;
    if (!appLogic.loggedIn) return;
  }

  final sync = service.syncAll();
  await showProgressModal(
    context,
    stream: service.progressStream,
    task: sync,
    runningTitle: 'Syncing collection…',
  );
}
