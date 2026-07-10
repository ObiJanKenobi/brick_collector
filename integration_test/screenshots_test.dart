// The app tree stays mounted for the whole test, so reusing a context under it
// to present the login/sync overlays across pumps is intentional and safe.
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Prefixed import: main.dart re-exports `main` (via common_libs), which would
// clash with this file's own `main`. `app.main` boots the real app;
// `app.loginUser` shows the real Rebrickable login dialog.
import 'package:brick_collector/main.dart' as app;
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';

/// Captures the key onboarding screens (first screen + Rebrickable login &
/// sync) into PNGs for handing to testers.
///
/// Run it with `scripts/screenshots.sh` — NOT `flutter test` (on-device
/// screenshots only work under `flutter drive`).
///
///   1. `01-first-screen`      — the group create/join screen (real app boot)
///   2. `02-rebrickable-login` — the real Rebrickable login dialog
///   3. `03-rebrickable-sync`  — the collection sync progress modal
///
/// Everything runs over ONE continuous widget tree: the surface is converted to
/// an image once, then the real login dialog and sync modal are *pushed onto*
/// the running app (never via pumpWidget — swapping the tree after conversion
/// produces blank screenshots). Scenes 2 & 3 use the real dialog/modal widgets
/// driven with controlled input (login prefilled from --dart-define, sync fed a
/// representative progress event) so the run is deterministic and needs no
/// network or account.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture onboarding screenshots', (tester) async {
    // ---- Scene 1: the first screen (real app boot) --------------------------
    // Fire the real entrypoint; it runs Firebase init, bootstrap and routing.
    app.main();

    // The boot path shows a spinner (which never lets pumpAndSettle settle),
    // so pump in fixed steps until the group-setup screen appears.
    final onFirstScreen =
        await _pumpUntil(tester, find.text('Create New Group'));
    if (!onFirstScreen) {
      // A group already exists on this device (a previous run), so the app
      // skipped setup. Uninstall the app / erase the sim for a clean shot —
      // see scripts/screenshots.sh. We still capture whatever is on screen.
      debugPrint(
          'WARN: group-setup screen not reached — capturing current screen. '
          'Erase the simulator for a clean first-screen shot.');
    }

    // A live context under the app's Navigator, used to present the dialogs.
    final appContext = tester.element(find.byType(Navigator).first);

    // Convert the live surface to an image once, up front (required on iOS/
    // Android before takeScreenshot works). Every later screenshot re-renders
    // this same tree with the dialogs pushed on top.
    await binding.convertFlutterSurfaceToImage();
    await _settle(tester);
    await binding.takeScreenshot('01-first-screen');

    // ---- Scene 2: the Rebrickable login dialog ------------------------------
    // Fire-and-forget: the future completes only when the dialog is dismissed.
    unawaited(app.loginUser(appContext));
    await _pumpUntil(tester, find.text('Enter your Rebrickable credentials'));
    await _settle(tester);
    await binding.takeScreenshot('02-rebrickable-login');

    // Dismiss it programmatically — after the surface is converted to an image,
    // tap gestures can be ignored, but Navigator.pop still works.
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await _settle(tester);

    // ---- Scene 3: the collection sync progress modal ------------------------
    final progress = StreamController<SyncProgress?>();
    unawaited(showProgressModal(
      appContext,
      stream: progress.stream,
      task: Completer<void>().future, // never completes; scene ends the test
      runningTitle: 'Syncing collection…',
    ));
    // A representative mid-sync frame (deterministic; no network/account).
    progress.add(SyncProgress(
      done: 47,
      total: 128,
      label: 'Syncing “Millennium Falcon” (75192)…',
    ));
    await _pumpUntil(tester, find.text('Syncing collection…'));
    await _settle(tester);
    await binding.takeScreenshot('03-rebrickable-sync');
    // The live-async integration binding tolerates the pending stream/dialog at
    // teardown, so no explicit cleanup is needed.
  });
}

/// Pumps in fixed steps until [finder] matches or the timeout elapses.
/// Needed because the app shows perpetual spinners during boot/sync, which
/// make [WidgetTester.pumpAndSettle] time out.
Future<bool> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxSteps = 300, // ~30s
}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Pumps several frames so the capture boundary reflects the latest tree
/// (dialog fully faded in / route transition finished) before a screenshot.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
