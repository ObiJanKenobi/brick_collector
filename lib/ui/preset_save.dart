import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/filter_preset.dart';

/// Saves [preset] without blocking on the server. Firestore applies the write
/// to its local cache (and so to outPresets) right away, but with offline
/// persistence the write future only completes on server ack, so awaiting it
/// would freeze the UI while offline. [preset.firestoreId] is set on return.
/// A rejected write (permission-denied, invalid data, ...) shows a SnackBar;
/// Firestore then rolls the local change back.
void savePresetInBackground(BuildContext context, FilterPreset preset) {
  final messenger = ScaffoldMessenger.of(context);
  partsLogic.savePreset(preset).catchError((Object e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not save preset "${preset.name}": $e')));
  });
}
