import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Driver side of the screenshot flow. Runs on the host machine (not the
/// device) and writes every screenshot the test requests to disk.
///
/// Output directory is taken from the SCREENSHOT_DIR env var (set by
/// scripts/screenshots.sh); defaults to ./screenshots.
///
/// Invoked via:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshots_test.dart \
///     -d <simulator-udid>
Future<void> main() async {
  final outDir = Platform.environment['SCREENSHOT_DIR'] ?? 'screenshots';

  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final dir = Directory(outDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/$name.png');
      await file.writeAsBytes(bytes);
      stdout.writeln('  📸 wrote ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
